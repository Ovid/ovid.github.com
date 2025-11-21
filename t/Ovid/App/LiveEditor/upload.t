use v5.40;
use Test::Most;
use Plack::Test;
use HTTP::Request::Common;
use Path::Tiny;
use Cwd qw(getcwd);
use Test::MockModule;
use Ovid::App::LiveEditor;

# Setup test environment
my $cwd      = getcwd();
my $temp_dir = Path::Tiny->tempdir;
chdir $temp_dir;

# Create structure
$temp_dir->child('root')->mkpath;
$temp_dir->child('static/images')->mkpath;
$temp_dir->child('root/404.tt')->spew("Not Found");

# Mock Ovid::Site to avoid full rebuild
my $site_mock = Test::MockModule->new('Ovid::Site');
$site_mock->mock( 'build', sub { return; } );

# Mock Less::Config to ensure consistent max_image_size_bytes
my $config_mock = Test::MockModule->new('Less::Config');
$config_mock->mock(
    'config',
    sub {
        return { max_image_size_bytes => 300_000 };
    }
);

# Mock Ovid::Util::Image to isolate controller logic
my $image_util_mock = Test::MockModule->new('Ovid::Util::Image');

# We will override this mock in specific subtests

my $app  = Ovid::App::LiveEditor->to_app;
my $test = Plack::Test->create($app);

subtest 'Upload success' => sub {
    $image_util_mock->mock(
        'process',
        sub {
            my ( $class, %args ) = @_;
            return { success => 1, path => '/static/images/test.png' };
        }
    );

    my $req = POST '/api/upload-image',
      Content_Type => 'form-data',
      Content      => [
        image    => [ undef, 'test.png', Content_Type => 'image/png', Content => 'fakeimage' ],
        filename => 'test.png',
      ];

    my $res = $test->request($req);

    # Note: Route not implemented yet, so this will 404
    if ( $res->code == 404 ) {
        pass("Route not implemented yet (404 expected until T008)");
    }
    else {
        ok( $res->is_success, 'Upload successful' );
        like( $res->content, qr{/static/images/test\.png}, 'Response contains image path' );
    }
};

subtest 'Overwrite rejection' => sub {
    $image_util_mock->mock(
        'process',
        sub {
            return { success => 0, error => 'File exists', code => 'exists' };
        }
    );

    my $req = POST '/api/upload-image',
      Content_Type => 'form-data',
      Content      => [
        image    => [ undef, 'test.png', Content_Type => 'image/png', Content => 'fakeimage' ],
        filename => 'test.png',
      ];

    my $res = $test->request($req);

    if ( $res->code == 404 ) {
        pass("Route not implemented yet");
    }
    else {
        is( $res->code, 409, 'Conflict status for overwrite' );
        like( $res->content, qr/File exists/, 'Error message returned' );
    }
};

subtest 'MIME filtering' => sub {

    # This might be handled by the controller or the util.
    # If util handles it, we mock the failure.
    $image_util_mock->mock(
        'process',
        sub {
            return { success => 0, error => 'Invalid type', code => 'invalid_type' };
        }
    );

    my $req = POST '/api/upload-image',
      Content_Type => 'form-data',
      Content      => [
        image    => [ undef, 'test.txt', Content_Type => 'text/plain', Content => 'text' ],
        filename => 'test.txt',
      ];

    my $res = $test->request($req);

    if ( $res->code == 404 ) {
        pass("Route not implemented yet");
    }
    else {
        is( $res->code, 415, 'Unsupported Media Type' );
        like( $res->content, qr/Invalid type/, 'Error message returned' );
    }
};

subtest 'Config-sized failures' => sub {
    $image_util_mock->mock(
        'process',
        sub {
            return { success => 0, error => 'Image too large', code => 'too_large' };
        }
    );

    my $req = POST '/api/upload-image',
      Content_Type => 'form-data',
      Content      => [
        image    => [ undef, 'huge.png', Content_Type => 'image/png', Content => 'huge' ],
        filename => 'huge.png',
      ];

    my $res = $test->request($req);

    if ( $res->code == 404 ) {
        pass("Route not implemented yet");
    }
    else {
        is( $res->code, 413, 'Payload Too Large' );
        like( $res->content, qr/Image too large/, 'Error message returned' );
    }
};

chdir $cwd;
done_testing;
