#!/usr/bin/env perl

use Test::Most;
use Plack::Test;
use HTTP::Request::Common;

my $app = do './bin/review' or die $!;

test_psgi $app => sub {
    my $cb = shift;

    my $res = $cb->(GET '/index.html');
    my $content = $res->content;

    like $content, qr/window\.DEV_MODE\s*=\s*true/,
        'HTML contains DEV_MODE flag';

    like $content, qr{<script src="/static/dev-tools\.js"></script>},
        'HTML contains dev-tools script reference';

    like $content, qr{window\.DEV_MODE.*</head>}s,
        'DEV_MODE injection appears before closing head tag';
};

done_testing;
