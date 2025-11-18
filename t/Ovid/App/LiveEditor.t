use v5.40;
use Test::Most;
use Plack::Test;
use HTTP::Request::Common;
use Path::Tiny;

use Ovid::App::LiveEditor;

# Setup test file
my $temp_file = Path::Tiny->tempfile;
$temp_file->spew_utf8("Test Content");
$ENV{LIVE_EDITOR_FILE} = $temp_file->stringify;

my $app = Ovid::App::LiveEditor->to_app;
my $test = Plack::Test->create($app);

pass("Module loaded and app created");

subtest 'Root route' => sub {
    my $res = $test->request(GET '/');
    ok $res->is_success, 'Root route successful';
    like $res->content, qr/Test Content/, 'Content found in response';
    like $res->content, qr/iframe src="\/preview"/, 'Preview iframe found';
};

subtest 'Preview route' => sub {
    my $res = $test->request(GET '/preview');
    ok $res->is_success, 'Preview route successful';
    like $res->content, qr/Test Content/, 'Preview content matches';
};

done_testing;
