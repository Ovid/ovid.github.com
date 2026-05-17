#!/usr/bin/env perl

# Regression tests for Ovid::Site single-file rebuild edge cases.

use Test::Most;
use lib 'lib';
use Test2::Plugin::UTF8;
use Less::Boilerplate;
use Ovid::Site;

subtest '_copy_to_tmp does not crash when called outside a labeled loop' => sub {

    # `next FILE` used to live inside _copy_to_tmp, but the FILE: label is
    # defined on the loop in _preprocess_files. When _build_single_file calls
    # _copy_to_tmp directly (no enclosing loop), `next FILE` raises a fatal
    # "Label not found" exception. Replace with `return` — same skip semantics
    # in the loop case, correct behavior in the single-file case.

    my $site = Ovid::Site->new( file => 'irrelevant.tt' );

    # Path is non-static and non-tt: triggers the early-skip branch.
    lives_ok {
        $site->_copy_to_tmp('root/blog/foo.txt');
    }
    'early-skip branch does not raise "Label not found" outside a loop';
};

done_testing;
