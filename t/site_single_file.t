#!/usr/bin/env perl

# Regression tests for Ovid::Site single-file rebuild edge cases.

use Test::Most;
use lib 'lib';
use Test2::Plugin::UTF8;
use Less::Boilerplate;
use Path::Tiny qw(path);
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

# Regression test for [I11]: the tag template stub heredoc in
# _write_tag_templates used to begin with `USE Ovid;`, but the stub's
# only body is `INCLUDE include/tags.tt`, and tags.tt declares its own
# plugin imports. Template Toolkit plugin scope is file-local, so the
# `USE Ovid;` in the stub was unused — and misleading for readers
# trying to understand which plugin a template actually relies on.
subtest 'generated tag-template stub does not include cargo-cult USE Ovid;' => sub {
    my $source = path('lib/Ovid/Site.pm')->slurp_utf8;
    unlike $source, qr/^\s*USE\s+Ovid\s*;\s*$/m,
      'no leftover `USE Ovid;` line in Site.pm (heredoc cargo-cult removed)';
    like $source, qr{INCLUDE\s+include/tags\.tt},
      'tag stub heredoc still includes include/tags.tt (sanity check)';
};

done_testing;
