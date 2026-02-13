#!/usr/bin/env perl

use Test::Most;
use Plack::Test;
use HTTP::Request::Common;
use JSON::MaybeXS qw(decode_json);

# Prevent side effects (launching browser) during tests
$ENV{TESTING} = 1;

# Load the app
my $app;
lives_ok { $app = do './bin/review' } 'bin/review loads without errors';
ok $app, 'bin/review returns a PSGI app';

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

done_testing;
