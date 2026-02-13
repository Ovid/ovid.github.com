#!/usr/bin/env perl

use Test::Most;
use Path::Tiny;

# This is a CRITICAL safety test to ensure dev tools never leak to production

# Scan all generated HTML in production directories
my @html_files;
for my $dir (qw(articles blog)) {
    next unless -d $dir;
    push @html_files, path($dir)->children(qr/\.html$/);
}

# Must find at least some HTML files
ok scalar(@html_files) > 0, 'Found HTML files to test'
    or BAIL_OUT('No HTML files found - cannot verify production safety');

for my $file (@html_files) {
    my $content = $file->slurp_utf8;

    unlike $content, qr/window\.DEV_MODE/,
        "$file must not contain DEV_MODE flag";

    unlike $content, qr{dev-tools\.js},
        "$file must not contain dev-tools.js reference";
}

done_testing;
