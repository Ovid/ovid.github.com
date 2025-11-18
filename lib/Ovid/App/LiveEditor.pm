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
    my $content = path($file)->slurp_utf8;

    my $tt = Template->new({
        INCLUDE_PATH => ['include', 'root'],
        ENCODING     => 'utf8',
        ABSOLUTE     => 1,
        RELATIVE     => 1,
    });

    my $output = '';
    $tt->process(\$content, {}, \$output) || return $tt->error;

    return $output;
}

true;
