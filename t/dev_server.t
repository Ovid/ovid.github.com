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

subtest 'GET / serves index.html directly without redirect' => sub {
    test_psgi $app => sub {
        my $cb  = shift;
        my $res = $cb->( GET '/' );
        is $res->code, 200, 'GET / returns 200 (no redirect)';
        like $res->content, qr/Curtis.*Poe/i,
            'GET / returns homepage content';
    };
};

subtest 'launch-editor honors OVID_REVIEW_TEST_LAUNCH_CMD for fork path' => sub {
    # When TESTING is set without the knob, the fork is skipped. With
    # the knob set, exercise the fork/dup/exec path + _terminate_previous_editor
    # against a benign command (`perl -e 'exit 0'`) instead of bin/launch.
    local $ENV{OVID_REVIEW_TEST_LAUNCH_CMD} = $^X;

    test_psgi $app => sub {
        my $cb = shift;

        # First call: spawns child A.
        my $res = $cb->(
            POST '/api/launch-editor',
            Content_Type => 'application/json',
            Content      => '{"file":"root/404.tt"}'
        );
        ok $res->is_success, 'first fork-path request succeeds';

        # Second call: terminates child A and spawns child B.
        # Exercises _terminate_previous_editor.
        $res = $cb->(
            POST '/api/launch-editor',
            Content_Type => 'application/json',
            Content      => '{"file":"root/404.tt"}'
        );
        ok $res->is_success, 'second fork-path request succeeds';
    };

    # Reap any child the fork left behind.
    1 while waitpid( -1, 1 ) > 0;
};

subtest 'static handler serves binary asset (Delayed path)' => sub {
    # The `after` hook short-circuits when the response is
    # Dancer2::Core::Response::Delayed (returned by send_file). Hit
    # that branch by requesting a non-HTML static asset that exists.
    test_psgi $app => sub {
        my $cb = shift;

        # Use a static file that's likely to exist in this repo.
        for my $candidate (
            'static/favicon.ico',
            'static/css/main.css',
            'static/js/codemirror/codemirror.js',
          )
        {
            next unless -e $candidate;
            my $res = $cb->( GET "/$candidate" );
            is $res->code, 200, "served $candidate as binary";
            last;
        }
    };
};

subtest 'after hook does not inject when content-type is not text/html' => sub {
    test_psgi $app => sub {
        my $cb = shift;
        for my $candidate ( 'static/favicon.ico', 'static/css/main.css' ) {
            next unless -e $candidate;
            my $res = $cb->( GET "/$candidate" );
            unlike $res->content, qr/window\.DEV_MODE/,
                "dev-tools script not injected into $candidate";
            last;
        }
    };
};

subtest 'static handler rejects symlinks pointing outside project root' => sub {
    # Create a symlink inside the project that points to a file
    # outside the project (e.g. /etc/hosts). The handler's realpath
    # check should reject it.
    my $tmplink = path('static/symlink-test.txt');
    return if $tmplink->exists;    # don't clobber

    # Find a safe target outside the project root that's readable.
    my $target;
    for my $candidate ('/etc/hostname', '/etc/hosts') {
        $target = $candidate if -r $candidate;
        last if $target;
    }
    return unless $target;

    eval { symlink $target, "$tmplink" or die "symlink failed: $!" };
    return if $@;

    test_psgi $app => sub {
        my $cb  = shift;
        my $res = $cb->( GET '/static/symlink-test.txt' );
        isnt $res->code, 200, 'symlink outside project root is rejected';
    };

    unlink "$tmplink";
};

done_testing;
