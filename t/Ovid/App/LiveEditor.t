use v5.40;
use Test::Most;
use Plack::Test;
use HTTP::Request::Common;
use Path::Tiny;
use Cwd qw(getcwd);
use Test::MockModule;

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

# Mock Ovid::Site to avoid full rebuild in tests
my $site_mock = Test::MockModule->new('Ovid::Site');
my $build_called = 0;
$site_mock->mock('build', sub {
    $build_called++;
    return;
});

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
    ok $build_called, 'Ovid::Site->build was called';
};

subtest 'Static files' => sub {
    my $res = $test->request(GET '/static/css/style.css');
    ok $res->is_success, 'Static file served';
    is $res->content, 'body { color: red; }', 'Static file content matches';
};

subtest 'Save endpoint' => sub {
    my $new_content = "Updated Content";
    my $res = $test->request(POST '/api/save', [ content => $new_content ]);
    ok $res->is_success, 'Save request successful';
    is $source_file->slurp_utf8, $new_content, 'File on disk updated';
    
    # Test missing content
    $res = $test->request(POST '/api/save', []);
    ok !$res->is_success, 'Save request without content fails';
    is $res->code, 400, 'Returns 400 Bad Request';
};

subtest 'File Switching' => sub {
    # Create another file
    my $other_file = $temp_dir->child('root/other.tt');
    $other_file->spew_utf8("Other Content");
    
    # Test GET / with file param
    my $res = $test->request(GET '/?file=' . $other_file->absolute->stringify);
    ok $res->is_success, 'Switch file successful';
    like $res->content, qr/Editor: Other Content/, 'Editor shows other file content';
    
    # Test Save with file param
    my $new_other_content = "New Other Content";
    $res = $test->request(POST '/api/save', [ content => $new_other_content, file => $other_file->absolute->stringify ]);
    ok $res->is_success, 'Save other file successful';
    is $other_file->slurp_utf8, $new_other_content, 'Other file on disk updated';
    
    # Test Security
    my $outside_file = Path::Tiny->tempfile;
    $res = $test->request(GET '/?file=' . $outside_file->absolute->stringify);
    ok !$res->is_success, 'Accessing outside file fails';
    like $res->content, qr/Security Error/, 'Security error message';
    
    # Test Security: File in project root but not in root/ directory
    my $lib_file = $temp_dir->child('lib/Test.pm');
    $lib_file->parent->mkpath;
    $lib_file->spew_utf8("package Test;");
    $res = $test->request(GET '/?file=' . $lib_file->absolute->stringify);
    ok !$res->is_success, 'Accessing file outside root/ fails';
    like $res->content, qr/Security Error/, 'Security error message for non-root/ file';
};

subtest 'File Listing' => sub {
    my $res = $test->request(GET '/api/files');
    ok $res->is_success, 'File listing successful';
    my $json = $res->content;
    like $json, qr/test\.tt/, 'Contains test.tt';
    like $json, qr/other\.tt/, 'Contains other.tt';
    like $json, qr/editor\.tt/, 'Contains editor.tt';
    unlike $json, qr/Test\.pm/, 'Does not contain lib files';
};

# Cleanup
chdir $cwd;
done_testing;
