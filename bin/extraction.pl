#!/usr/bin/env perl

use v5.40;
use lib 'lib';
use Less::Script;
use File::Copy::Recursive qw(dircopy);
use File::Path            qw(mkpath rmtree);

use Less::Config qw(config);

my $ga_id     = config()->{google_analytics_id};
my $repo_url  = 'https://github.com/Ovid/Extraction.git';
my $clone_dir = 'Extraction';
my $dest_dir  = 'projects/extraction';

# Clone or pull the Extraction repo
if ( -d $clone_dir ) {
    say "Updating $clone_dir ...";
    system( 'git', '-C', $clone_dir, 'pull', '--quiet' ) == 0
      or die "git pull failed: $?";
}
else {
    say "Cloning $repo_url into $clone_dir ...";
    system( 'git', 'clone', '--quiet', $repo_url, $clone_dir ) == 0
      or die "git clone failed: $?";
}

# Clean and recreate destination
if ( -d $dest_dir ) {
    say "Cleaning $dest_dir ...";
    rmtree($dest_dir);
}
mkpath($dest_dir);

# Copy static site files
my @to_copy = qw(index.html css js data images);

for my $item (@to_copy) {
    my $src = "$clone_dir/$item";
    my $dst = "$dest_dir/$item";

    unless ( -e $src ) {
        warn "Skipping $src (does not exist)\n";
        next;
    }

    if ( -d $src ) {
        dircopy( $src, $dst ) or die "Failed to copy $src to $dst: $!";
        say "  Copied $item/";
    }
    else {
        File::Copy::copy( $src, $dst ) or die "Failed to copy $src to $dst: $!";
        say "  Copied $item";
    }
}

# Inject Google Analytics tag into index.html
my $index = "$dest_dir/index.html";
my $html  = slurp($index);
my $gtag  = <<"GTAG";
<!-- Google tag (gtag.js) -->
<script async src="https://www.googletagmanager.com/gtag/js?id=$ga_id"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', '$ga_id');
</script>
GTAG

if ( $html =~ s{(<head[^>]*>)}{$1\n$gtag} ) {
    splat( $index, $html );
    say "  Injected Google Analytics tag";
}
else {
    warn "Could not find <head> tag in $index to inject analytics\n";
}

say "Done. Extraction site deployed to $dest_dir/";
