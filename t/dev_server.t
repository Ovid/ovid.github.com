#!/usr/bin/env perl

use Test::Most;
use Plack::Test;
use HTTP::Request::Common;
use JSON::MaybeXS qw(decode_json);
use Path::Tiny    qw(path);

# Prevent side effects (launching browser) during tests
$ENV{TESTING} = 1;

# Load the app
my $app;
lives_ok { $app = do './bin/review' } 'bin/review loads without errors';
ok $app, 'bin/review returns a PSGI app';

# [C1] The dev server must bind to localhost only. The startup banner
# advertises 127.0.0.1, but Dancer2 defaults to 0.0.0.0 when no host is
# set — so without `set host`, the server is reachable on every interface.
#
# This is a source check rather than a runtime check because Test::Most
# pulls in modules that pre-initialize Dancer2's runner before
# `do "./bin/review"` runs, so a late `set host` cannot retroactively
# update the test-time runner. Verifying the source confirms the line
# is present at module-load time, which is when it matters in production.
subtest 'bin/review explicitly binds the host to 127.0.0.1' => sub {
    my $source = path('bin/review')->slurp_utf8;
    like $source, qr/^\s*set\s+host\s*=>\s*['"]127\.0\.0\.1['"]/m,
      q{`set host => '127.0.0.1'` is present in bin/review};
};

test_psgi $app => sub {
    my $cb = shift;

    # Test root endpoint exists
    my $res = $cb->(GET '/');
    ok $res, 'GET / returns a response';
};

test_psgi $app => sub {
    my $cb = shift;

    # Test serving index.html
    my $res = $cb->(GET '/index.html');
    is $res->code, 200, 'index.html returns 200';
    like $res->content, qr/Curtis.*Poe/i, 'index.html contains expected content';
};

test_psgi $app => sub {
    my $cb = shift;

    # Test API endpoint exists
    my $res = $cb->(
        POST '/api/launch-editor',
        Content_Type => 'application/json',
        Content => '{"file":"root/404.tt"}'
    );

    ok $res->is_success, 'API endpoint returns success for valid file';

    my $data = decode_json($res->content);
    ok $data->{success}, 'Response indicates success';
    is $data->{file}, 'root/404.tt', 'Response includes file path';
};

test_psgi $app => sub {
    my $cb = shift;

    # Test missing file parameter
    my $res = $cb->(
        POST '/api/launch-editor',
        Content_Type => 'application/json',
        Content => '{}'
    );
    is $res->code, 400, 'Missing file returns 400';
    my $data = decode_json($res->content);
    ok $data->{error}, 'Error message present';

    # Test path traversal attempt
    $res = $cb->(
        POST '/api/launch-editor',
        Content_Type => 'application/json',
        Content => '{"file":"../etc/passwd"}'
    );
    is $res->code, 400, 'Path traversal returns 400';

    # Test non-existent file
    $res = $cb->(
        POST '/api/launch-editor',
        Content_Type => 'application/json',
        Content => '{"file":"nonexistent/file.tt"}'
    );
    is $res->code, 404, 'Non-existent file returns 404';
};

# [I6] Malformed JSON bodies should produce a 400, not an uncaught
# `from_json` croak (which Dancer2 turns into a 500).
subtest 'launch-editor returns 400 on malformed JSON body' => sub {
    test_psgi $app => sub {
        my $cb  = shift;
        my $res = $cb->(
            POST '/api/launch-editor',
            Content_Type => 'application/json',
            Content      => '{not valid json'
        );
        is $res->code, 400, 'Malformed JSON returns 400 (not 500)';
        my $data = eval { decode_json( $res->content ) };
        ok $data->{error}, 'Error message present in response';
    };
};

# [I7] The editor-launch endpoint must restrict targets to files under
# `root/`. Without this, anyone reaching the endpoint (after [C1] is
# fixed, only loopback; but loopback is still a defense-in-depth concern)
# can launch the editor against arbitrary in-project files.
subtest 'launch-editor restricts targets to files under root/' => sub {
    test_psgi $app => sub {
        my $cb = shift;

        for my $blocked ( 'db/ovid.db', 'cpanfile', 'lib/Ovid/Site.pm' ) {

            # Skip files that don't exist in this checkout — the test
            # is about scope enforcement, not file probing.
            next unless -e $blocked;

            my $res = $cb->(
                POST '/api/launch-editor',
                Content_Type => 'application/json',
                Content      => qq{{"file":"$blocked"}}
            );
            isnt $res->code, 200,
              "$blocked is in-project but outside root/ — must be rejected";
        }

        # Absolute paths outside the project are also rejected. The
        # existing `..` check catches relative traversal; absolute
        # paths bypass that.
        my $res = $cb->(
            POST '/api/launch-editor',
            Content_Type => 'application/json',
            Content      => '{"file":"/etc/passwd"}'
        );
        isnt $res->code, 200, 'absolute path /etc/passwd must be rejected';
    };
};

# [C2] The static file handler must not expose arbitrary in-project
# files. Without restrictions, GET /cpanfile, GET /db/ovid.db,
# GET /lib/Ovid/Site.pm all return file contents.
subtest 'static handler blocks sensitive in-project paths' => sub {
    test_psgi $app => sub {
        my $cb = shift;
        for my $blocked (
            'cpanfile', 'Makefile', 'db/ovid.db', 'lib/Ovid/Site.pm',
            '.git/config',
          )
        {
            next unless -e $blocked;
            my $res = $cb->( GET "/$blocked" );
            isnt $res->code, 200,
              "GET /$blocked must not return file contents";
        }
    };
};

# [C2] Confirm the handler still serves legitimate paths.
subtest 'static handler still serves legitimate site content' => sub {
    test_psgi $app => sub {
        my $cb = shift;

        my $res = $cb->( GET '/index.html' );
        is $res->code, 200, 'index.html still served';

        if ( -e 'static/css/main.css' ) {
            $res = $cb->( GET '/static/css/main.css' );
            is $res->code, 200, 'static/css/main.css still served';
        }
    };
};

done_testing;
