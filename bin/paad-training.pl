#!/usr/bin/env perl

# Deploys the hand-authored PAAD training course to /paad/. Unlike bin/zork.pl
# and bin/tramp.pl there is nothing to clone or build: the course is a single
# self-contained HTML file. It still needs the Google Analytics tag injected,
# because it does not go through root/include/header.tt.

use v5.40;
use lib 'lib';
use Less::Script;
use File::Path qw(mkpath);

use Less::Config qw(config);

my $ga_id  = config()->{google_analytics_id};
my $source = 'scratch/paadtraining.html';
my $dest   = 'paad/index.html';

die "Source file $source does not exist\n" unless -e $source;

my $html = slurp($source);
my $gtag = <<"GTAG";
<!-- Google tag (gtag.js) -->
<script async src="https://www.googletagmanager.com/gtag/js?id=$ga_id"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', '$ga_id');
</script>
GTAG

$html =~ s{(<head[^>]*>)}{$1\n$gtag}
  or die "Could not find <head> tag in $source to inject analytics\n";

mkpath('paad');
splat( $dest, $html );
say "Done. PAAD training course deployed to $dest";
