package Ovid::App::LiveEditor;

use v5.40;
use Dancer2;
use Path::Tiny;
use Template;
use Ovid::Site;
use Capture::Tiny qw(capture);
use Less::Config ();

our $VERSION = '0.1';

set views => 'root';
set template => 'template_toolkit';
set max_image_size_bytes => Less::Config::config()->{max_image_size_bytes};

sub _get_target_file {
    my $file_param = query_parameters->get('file') // body_parameters->get('file');
    my $file = $file_param // $ENV{LIVE_EDITOR_FILE};

    unless ($file) {
        return (undef, "No file specified.");
    }

    my $path = path($file)->realpath;
    my $root_dir = path('root')->realpath;

    # Security check: Ensure file is within root/ directory
    if ($path->stringify !~ /^\Q$root_dir\E/) {
        return (undef, "Security Error: Can only edit files in the root/ directory.");
    }

    unless ($path->exists && -f $path) {
        return (undef, "File not found: $file");
    }

    return ($path->stringify, undef);
}

get '/api/files' => sub {
    my $root = path('root')->absolute;
    my @files;
    
    # Visit all files in root/ recursively
    $root->visit(sub {
        my $path = shift;
        if ($path->is_file && $path->basename !~ /^\./) { # Skip hidden files
            push @files, $path->relative($root)->stringify;
        }
    }, { recurse => 1 });
    
    content_type 'application/json';
    return to_json([sort @files]);
};

get '/' => sub {
    my ($file, $error) = _get_target_file();
    if ($error) {
        status 400;
        return $error;
    }

    my $content = path($file)->slurp_utf8;
    my $rel_path = path($file)->relative(path('.')->absolute)->stringify;

    template 'editor' => {
        content  => $content,
        filename => path($file)->basename,
        filepath => $rel_path,
    };
};

post '/api/save' => sub {
    my ($file, $error) = _get_target_file();
    if ($error) {
        status 400;
        return $error;
    }

    my $content = body_parameters->get('content');
    unless (defined $content) {
        status 400;
        return "No content provided.";
    }

    # Ensure file is writable
    unless (-w $file) {
        status 500;
        error "File is not writable: $file";
        return "Error: File is not writable.";
    }

    eval {
        path($file)->spew_utf8($content);
    };
    if ($@) {
        status 500;
        error "Failed to save file $file: $@";
        return "Error saving file: $@";
    }

    return "Saved";
};

get '/preview' => sub {
    my ($file, $error) = _get_target_file();
    if ($error) {
        status 400;
        return $error;
    }

    return _render_preview($file);
};

sub _render_preview($file) {
    my $abs_path = path($file)->absolute;
    my $cwd = path('.')->absolute;
    my $rel_path = $abs_path->relative($cwd);

    # Rebuild the file
    # We capture output to prevent log spam, but we should check for errors
    my ($stdout, $stderr) = capture {
        eval {
            my $site = Ovid::Site->new(file => $rel_path->stringify);
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

    if ($path_str =~ m{^(.*)/root/(.*)$}) {
        my $project_root = path($1);
        my $rel_path = $2;

        # Change extension to .html
        $rel_path =~ s{\.(?:tt|tt2markdown)$}{.html};

        # Generated files are in $project_root/$rel_path
        # e.g. /path/to/project/blog/post.html
        my $generated = $project_root->child($rel_path);

        if ($generated->exists) {
            return $generated->slurp_utf8;
        } else {
            return "Preview not available. Generated file not found: " . $generated->stringify;
        }
    }

    return "File is not in a 'root/' directory. Cannot determine preview path.\n" .
           "Expected a source file (e.g., root/blog/post.tt), but got:\n$path_str";
}

get '/static/**' => sub {
    my ($path) = splat;
    my $file = path('.')->child('static', @$path);
    if ($file->exists && -f $file) {
        send_file $file->absolute->stringify, system_path => 1;
    } else {
        pass;
    }
};

true;
