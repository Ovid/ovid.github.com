use v5.40;
use Test::Most;
use Plack::Test;
use HTTP::Request::Common;
use Path::Tiny;
use Cwd qw(getcwd);

# Setup test environment before loading app
my $cwd = getcwd();
my $temp_dir = Path::Tiny->tempdir;
chdir $temp_dir;

# Create structure
$temp_dir->child('root')->mkpath;
my $source_file = $temp_dir->child('root/test.tt');
$source_file->spew_utf8("Source Content");

my $generated_file = $temp_dir->child('test.html');
$generated_file->spew_utf8("Generated HTML Content");

# Create dummy editor template because we are in a temp dir
$temp_dir->child('root/editor.tt')->spew_utf8(<<'EOF');
Editor: [% content %]
Iframe: <iframe src="/preview"></iframe>
EOF

# Create dummy static file
$temp_dir->child('static/css')->mkpath;
$temp_dir->child('static/css/style.css')->spew_utf8("body { color: red; }");

$ENV{LIVE_EDITOR_FILE} = $source_file->absolute->stringify;

use Ovid::App::LiveEditor;

my $app = Ovid::App::LiveEditor->to_app;
my $test = Plack::Test->create($app);

pass("Module loaded and app created");

subtest 'Root route' => sub {
    my $res = $test->request(GET '/');
    ok $res->is_success, 'Root route successful';
    like $res->content, qr/Editor: Source Content/, 'Editor shows source content';
    like $res->content, qr/Iframe: <iframe src="\/preview"/, 'Preview iframe found';
};

subtest 'Preview route' => sub {
    my $res = $test->request(GET '/preview');
    ok $res->is_success, 'Preview route successful';
    like $res->content, qr/Generated HTML Content/, 'Preview shows generated HTML';
};

subtest 'Static files' => sub {
    my $res = $test->request(GET '/static/css/style.css');
    ok $res->is_success, 'Static file served';
    is $res->content, 'body { color: red; }', 'Static file content matches';
};

# Cleanup
chdir $cwd;
done_testing;
