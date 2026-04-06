package Ovid::App::LiveEditor;

use v5.40;
use Dancer2;
use Path::Tiny;
use Template;
use Ovid::Site;
use Capture::Tiny qw(capture);
use Less::Config  ();
use Ovid::Util::Image;

our $VERSION = '0.1';

set views                => 'root';
set template             => 'template_toolkit';
set max_image_size_bytes => Less::Config::config()->{max_image_size_bytes};

sub _get_target_file {
    my $file_param = query_parameters->get('file') // body_parameters->get('file');
    my $file       = $file_param                   // $ENV{LIVE_EDITOR_FILE};

    unless ($file) {
        return ( undef, "No file specified." );
    }

    my $path     = path($file)->realpath;
    my $root_dir = path('root')->realpath;

    # Security check: Ensure file is within root/ directory
    if ( $path->stringify !~ /^\Q$root_dir\E/ ) {
        return ( undef, "Security Error: Can only edit files in the root/ directory." );
    }

    unless ( $path->exists && -f $path ) {
        return ( undef, "File not found: $file" );
    }

    return ( $path->stringify, undef );
}

get '/api/files' => sub {
    my $root = path('root')->absolute;
    my @files;

    # Visit all files in root/ recursively
    $root->visit(
        sub {
            my $path = shift;
            if ( $path->is_file && $path->basename !~ /^\./ ) {    # Skip hidden files
                push @files, $path->relative($root)->stringify;
            }
        },
        { recurse => 1 }
    );

    content_type 'application/json';
    return to_json( [ sort @files ] );
};

get '/health' => sub {
    content_type 'application/json';
    return to_json(
        {
            ok        => 1,
            file      => $ENV{LIVE_EDITOR_FILE},
            timestamp => time,
        }
    );
};

get '/' => sub {
    my ( $file, $error ) = _get_target_file();
    if ($error) {
        status 400;
        return $error;
    }

    my $content  = path($file)->slurp_utf8;
    my $rel_path = path($file)->relative( path('.')->absolute )->stringify;

    template 'editor' => {
        content  => $content,
        filename => path($file)->basename,
        filepath => $rel_path,
    };
};

post '/api/save' => sub {
    my ( $file, $error ) = _get_target_file();
    if ($error) {
        status 400;
        return $error;
    }

    my $content = body_parameters->get('content');
    unless ( defined $content ) {
        status 400;
        return "No content provided.";
    }

    # Ensure file is writable
    unless ( -w $file ) {
        status 500;
        error "File is not writable: $file";
        return "Error: File is not writable.";
    }

    eval { path($file)->spew_utf8($content); };
    if ($@) {
        status 500;
        error "Failed to save file $file: $@";
        return "Error saving file: $@";
    }

    return "File saved successfully.";
};

post '/api/upload-image' => sub {
    my $upload = request->upload('image');
    unless ($upload) {
        status 400;
        return to_json( { error => 'No image uploaded' } );
    }

    my $filename  = body_parameters->get('filename');
    my $overwrite = body_parameters->get('overwrite') ? 1 : 0;
    my $source    = body_parameters->get('source');
    my $alt       = body_parameters->get('alt');
    my $caption   = body_parameters->get('caption');

    unless ($filename) {
        status 400;
        return to_json( { error => 'Filename is required' } );
    }
    unless ($alt) {
        status 400;
        return to_json( { error => 'Alt text is required' } );
    }

    my $result = Ovid::Util::Image->process(
        upload    => $upload,
        filename  => $filename,
        overwrite => $overwrite,
    );

    unless ( $result->{success} ) {
        if ( $result->{code} eq 'exists' ) {
            status 409;
        }
        elsif ( $result->{code} eq 'invalid_type' ) {
            status 415;
        }
        elsif ( $result->{code} eq 'too_large' ) {
            status 413;
        }
        else {
            status 400;
        }
        return to_json( { error => $result->{error}, code => $result->{code} } );
    }

    # Escape values for TT double-quoted strings
    my $esc_src     = _escape_tt( $result->{path} );
    my $esc_alt     = _escape_tt( $alt     // '' );
    my $esc_caption = _escape_tt( $caption // '' );
    my $esc_source  = _escape_tt( $source  // '' );

    my $snippet = <<~"EOF";
    [% INCLUDE include/image.tt
       src      = "$esc_src"
       source   = "$esc_source"
       align    = "center" 
       alt      = "$esc_alt"
       caption  = "$esc_caption"
    %]
    EOF

    content_type 'application/json';
    return to_json(
        {
            snippet => $snippet,
            path    => $result->{path},
        }
    );
};

sub _escape_tt {
    my $str = shift;
    $str =~ s/"/&quot;/g;
    return $str;
}

get '/preview' => sub {
    my ( $file, $error ) = _get_target_file();
    if ($error) {
        status 400;
        return $error;
    }

    return _render_preview($file);
};

sub _render_preview($file) {
    my $abs_path = path($file)->absolute;
    my $cwd      = path('.')->absolute;
    my $rel_path = $abs_path->relative($cwd);

    # Rebuild the file
    # We capture output to prevent log spam, but we should check for errors
    my ( $stdout, $stderr ) = capture {
        eval {
            my $site = Ovid::Site->new( file => $rel_path->stringify );
            $site->build;
        };
    };

    if ($@) {
        error "Rebuild failed: $@";
        return "Error rebuilding file: $@\n\nStdout:\n$stdout\n\nStderr:\n$stderr";
    }

    my $path_str = $abs_path->stringify;

    # We expect the file to be in a 'root' directory within the project
    # e.g. /path/to/project/root/blog/post.tt

    if ( $path_str =~ m{^(.*)/root/(.*)$} ) {
        my $project_root = path($1);
        my $rel_path     = $2;

        # Change extension to .html
        $rel_path =~ s{\.(?:tt|tt2markdown)$}{.html};

        # Generated files are in $project_root/$rel_path
        # e.g. /path/to/project/blog/post.html
        my $generated = $project_root->child($rel_path);

        if ( $generated->exists ) {
            return $generated->slurp_utf8;
        }
        else {
            return "Preview not available. Generated file not found: " . $generated->stringify;
        }
    }

    return "File is not in a 'root/' directory. Cannot determine preview path.\n"
      . "Expected a source file (e.g., root/blog/post.tt), but got:\n$path_str";
}

get '/static/**' => sub {
    my ($path) = splat;
    my $file = path('.')->child( 'static', @$path );
    if ( $file->exists && -f $file ) {
        send_file $file->absolute->stringify, system_path => 1;
    }
    else {
        pass;
    }
};

true;

__END__

=head1 NAME

Ovid::App::LiveEditor - Dancer2 web application for real-time template editing and preview

=head1 SYNOPSIS

    # Set the file to edit via environment variable
    $ENV{LIVE_EDITOR_FILE} = 'root/blog/my-post.tt';

    # Launch via the CLI wrapper
    perl bin/launch root/blog/my-post.tt

    # Or start directly with Dancer2
    plackup -a bin/app.psgi

=head1 DESCRIPTION

Ovid::App::LiveEditor is a Dancer2 application that provides a browser-based
editor for Template Toolkit source files. It offers side-by-side editing with
live preview, image uploading with automatic compression, and a file browser
for navigating all templates under the C<root/> directory.

For security, the editor restricts all file operations to files within the
C<root/> directory. Path traversal attempts are rejected.

The target file can be specified either via the C<LIVE_EDITOR_FILE>
environment variable or the C<file> query/body parameter on each request.

=head1 API ENDPOINTS

=head2 GET /

Renders the editor interface for the target file. The file's content is
loaded and passed to the C<editor> template along with its filename and
relative path.

Returns HTTP 400 if no file is specified or the file is not found.

=head2 GET /preview

Rebuilds the target file using L<Ovid::Site> and returns the generated HTML.
The rebuild runs in-process with output captured via L<Capture::Tiny>.

The endpoint maps the source path (e.g., C<root/blog/post.tt>) to its
generated output (e.g., C<blog/post.html>) and returns the HTML content.

Returns HTTP 400 if no file is specified or the file cannot be found.

=head2 POST /api/save

Saves new content to the target file. Expects a C<content> body parameter
containing the full file text and a C<file> parameter identifying the target.

Returns a success message on success, or HTTP 400/500 on error.

=head2 POST /api/upload-image

Uploads and processes an image file. Accepts a multipart form with:

=over 4

=item C<image> - The uploaded image file (required)

=item C<filename> - Target filename for the image (required)

=item C<alt> - Alt text for accessibility (required)

=item C<overwrite> - If true, overwrite an existing file with the same name

=item C<source> - Attribution source URL

=item C<caption> - Image caption text

=back

The image is processed via L<Ovid::Util::Image> and saved to both
C<root/static/images/> and C<static/images/>. On success, returns a JSON
response containing a Template Toolkit C<snippet> for embedding the image
and the image C<path>.

HTTP status codes: 409 (file exists), 415 (invalid type), 413 (too large),
400 (other errors).

=head2 GET /api/files

Returns a JSON array of all non-hidden file paths under the C<root/>
directory, sorted alphabetically. Paths are relative to C<root/>.

=head2 GET /health

Returns a JSON health check response with C<ok>, the current C<file> being
edited, and a C<timestamp>.

=head2 GET /static/**

Serves static files from the C<static/> directory in the project root.

=cut
