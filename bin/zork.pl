#!/usr/bin/env perl

use v5.40;
use lib 'lib';
use Less::Script;
use File::Copy::Recursive qw(dircopy);
use File::Path            qw(mkpath rmtree);

use Less::Config qw(config);

my $ga_id     = config()->{google_analytics_id};
my $repo_url  = 'https://github.com/Ovid/loquor.git';
my $clone_dir = 'loquor';
my $dest_dir  = 'paad/zork';

# Clone or pull the loquor repo
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

# Build the Vite project
say "Installing npm dependencies ...";
system( 'npm', '--prefix', $clone_dir, 'install', '--silent' ) == 0
  or die "npm install failed: $?";

say "Building Vite project ...";

# Loquor's vite.config.ts does NOT read a VITE_BASE_PATH env var, so we cannot set
# the public base path the way the tramp-freighter script does. Instead, pass
# Vite's --base flag through to the build. `npm run build` runs `tsc -b && vite
# build`, and npm appends everything after `--` to the end of that command, so
# Vite receives `--base=/paad/zork/` and rewrites asset URLs for the subpath.
system( 'npm', '--prefix', $clone_dir, 'run', 'build', '--', "--base=/$dest_dir/" ) == 0
  or die "npm run build failed: $?";

# Clean and recreate destination
if ( -d $dest_dir ) {
    say "Cleaning $dest_dir ...";
    rmtree($dest_dir);
}
mkpath($dest_dir);

# Copy built files from dist/
my $dist_dir = "$clone_dir/dist";
die "Build output directory $dist_dir does not exist\n" unless -d $dist_dir;

dircopy( $dist_dir, $dest_dir )
  or die "Failed to copy $dist_dir to $dest_dir: $!";
say "  Copied dist/ to $dest_dir/";

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

say "Done. Loquor (Zork) site deployed to $dest_dir/";
