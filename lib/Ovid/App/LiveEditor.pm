package Ovid::App::LiveEditor;

use v5.40;
use Dancer2;
use Path::Tiny;
use Template;
use Ovid::Site;
use Capture::Tiny qw(capture);

our $VERSION = '0.1';

set views => 'root';
set template => 'template_toolkit';

get '/' => sub {
    my $file = $ENV{LIVE_EDITOR_FILE};
    unless ($file && -f $file) {
        status 400;
        return "No file specified or file not found.";
    }

    my $content = path($file)->slurp_utf8;

    template 'editor' => {
        content  => $content,
        filename => path($file)->basename,
    };
};

post '/api/save' => sub {
    my $file = $ENV{LIVE_EDITOR_FILE};
    unless ($file && -f $file) {
        status 400;
        return "No file specified or file not found.";
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
    my $file = $ENV{LIVE_EDITOR_FILE};
    unless ($file && -f $file) {
        status 400;
        return "No file specified.";
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
