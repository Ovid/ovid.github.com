#!/usr/bin/env perl

# The PAAD training course at /paad/ is a hand-authored static page deployed
# by bin/paad-training.pl, so it does not go through root/include/header.tt
# and gets no Google Analytics tag from the build. The tag is injected at
# deploy time; this test catches a redeploy that loses it.

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
