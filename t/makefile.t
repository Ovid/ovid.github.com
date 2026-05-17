#!/usr/bin/env perl

# Tests for the Makefile. Specifically: regressions in shell pipelines
# that would silently misbehave on filenames containing whitespace.

use Test::Most;
use lib 'lib';
use Test2::Plugin::UTF8;
use Less::Boilerplate;
use Path::Tiny qw(path);

my $makefile = path('Makefile')->slurp_utf8;

# [I13] The bin/ format pipeline used to emit `grep -l ... | xargs ...`
# with plain whitespace separation, while the lib/ pipeline used
# `find -print0 | xargs -0`. No `bin/*` files have whitespace today,
# but the asymmetric NUL-handling was a latent foot-gun: a script
# named with a space (or a wider refactor that moves more files
# under `bin/`) would silently misformat.
subtest 'bin format pipeline is NUL-safe' => sub {
    my ($bin_line) = grep { /^\s*find\s+bin\b/ } split /\n/, $makefile;
    ok $bin_line, 'Makefile has a `find bin` line';
    like $bin_line, qr/--null/,
      'bin pipeline uses `grep --null` for NUL-separated filenames';
    like $bin_line, qr/xargs\s+-0/,
      'bin pipeline uses `xargs -0` to consume NUL-separated input';
};

done_testing;
