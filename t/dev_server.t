#!/usr/bin/env perl

use Test::Most;
use Plack::Test;
use HTTP::Request::Common;

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

done_testing;
