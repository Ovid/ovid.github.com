package Ovid::App::LiveEditor;

use v5.40;
use Dancer2;
use Path::Tiny;
use Template;

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

get '/preview' => sub {
    my $file = $ENV{LIVE_EDITOR_FILE};
    unless ($file && -f $file) {
        status 400;
        return "No file specified.";
    }

    return _render_preview($file);
};

sub _render_preview($file) {
    my $path_str = path($file)->absolute->stringify;

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
true;
