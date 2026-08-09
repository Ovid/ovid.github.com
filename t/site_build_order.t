#!/usr/bin/env perl

# _preprocess_files wipes tmp/ and snapshots root/ into it, and _run_ttree
# renders from tmp/. So anything build() splats into root/ after that snapshot
# does not reach the current build -- ttree faithfully renders the copy the
# snapshot took, which is whatever the previous build left behind. The pages
# are then silently one build stale, and a second rebuild with no source change
# "fixes" them.
#
# This has already bitten root/include/latest.tt once; see the comment above
# _rebuild_latest_posts in Ovid::Site. Rather than pin the known offenders,
# this asserts the invariant itself: every generator funnels through splat(),
# so recording those paths catches any future generator added on the wrong
# side of the snapshot too.

use Test::Most;
use lib 'lib';
use Less::Boilerplate;
use Ovid::Site;

my @writes;

{
    no warnings 'redefine';

    # Record instead of write: the test must not touch the real root/ tree.
    local *Ovid::Site::splat = sub ( $file, @ ) { push @writes, $file };

    # The snapshot boundary we are measuring against.
    local *Ovid::Site::_preprocess_files = sub { push @writes, '<<snapshot>>' };

    # Not under test, and far too expensive to run for real.
    local *Ovid::Site::_run_ttree        = sub { };
    local *Ovid::Site::_write_sitemap    = sub { };
    local *Ovid::Site::_assert_tt_config = sub { };

    Ovid::Site->new->build;
}

my $snapshot = 0;
$snapshot++ until $snapshot > $#writes || '<<snapshot>>' eq $writes[$snapshot];
ok $snapshot <= $#writes, 'build() takes the tmp/ snapshot';

my @late = grep { m{^root/} } @writes[ $snapshot + 1 .. $#writes ];
is_deeply \@late, [],
  'nothing under root/ is written after the tmp/ snapshot';

# Guard against the inverse mistake: _write_tagmap consumes the _tagmap that
# _preprocess_files populates, so it must stay on the far side of the snapshot.
my @early = grep { 'tagmap.json' eq $_ } @writes[ 0 .. $snapshot ];
is_deeply \@early, [], 'tagmap.json is written after the snapshot that builds it';

done_testing;
