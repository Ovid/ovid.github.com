#!/usr/bin/env perl

# The PAAD training course at /paad/ is a hand-maintained static page
# (paad/index.html is the source), so it does not go through root/include/header.tt
# and gets no Google Analytics tag from the build. The tag lives in the page itself;
# this test catches an edit that loses it.

use Test::Most;
use lib 'lib';
use Less::Boilerplate;
use Less::Config qw(config);

my $page  = 'paad/index.html';
my $ga_id = config()->{google_analytics_id};

ok $ga_id, "config supplies a google_analytics_id ($ga_id)";
ok -e $page, "$page should be deployed";

my $html = do { open my $fh, '<:encoding(UTF-8)', $page or die $!; local $/; <$fh> };

like $html, qr/gtag\/js\?id=\Q$ga_id\E"/,
  'gtag.js script src includes the analytics id';
like $html, qr/gtag\('config', '\Q$ga_id\E'\)/,
  "gtag('config') call includes the analytics id";

done_testing;
