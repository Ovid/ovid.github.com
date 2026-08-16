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

# The course is authored standalone, so it has no way back to the site. Add a
# link above the PAAD wordmark in the sidebar, plus the style it needs.
my $home_link
  = qq{<a class="brand-home" href="/">\x{2190} Curtis \x{201C}Ovid\x{201D} Poe</a>\n    };
$html =~ s{(?=<div class="brand-mark">)}{$home_link}
  or die "Could not find sidebar brand mark in $source to inject the home link\n";

my $home_style = <<'CSS';
.brand-home{display:inline-block; margin-bottom:12px; font-size:12.5px; color:var(--text-dim);
  text-decoration:none; letter-spacing:.02em}
.brand-home:hover{color:var(--accent); text-decoration:underline}
CSS
$html =~ s{(?=\.brand-mark\{)}{$home_style}
  or die "Could not find .brand-mark rule in $source to inject the home link style\n";

mkpath('paad');
splat( $dest, $html );
say "Done. PAAD training course deployed to $dest";
