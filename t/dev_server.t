#!/usr/bin/env perl

use Test::Most;
use Plack::Test;
use HTTP::Request::Common;
use JSON::MaybeXS qw(decode_json);

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

done_testing;
