#!/usr/bin/env perl

use Test::Most;
use lib 'lib';
use lib 't/lib';
use Less::Boilerplate;
use Test2::Plugin::UTF8;
use Path::Tiny qw(path);
use Cwd        qw(getcwd);
use Ovid::Site;

my $cwd = getcwd();
END { chdir $cwd }

subtest '_assert_tt_config croaks when ~/.ttreerc is missing' => sub {
    my $home_tmp = Path::Tiny->tempdir;    # no .ttreerc inside
    local $ENV{HOME} = "$home_tmp";

    my $site = Ovid::Site->new;
    throws_ok { $site->_assert_tt_config }
        qr/\.ttreerc/,
        'croaks with a message mentioning .ttreerc';
};

subtest '_assert_tt_config returns silently when ~/.ttreerc exists' => sub {
    my $home_tmp = Path::Tiny->tempdir;
    $home_tmp->child('.ttreerc')->spew('verbose');
    local $ENV{HOME} = "$home_tmp";

    my $site = Ovid::Site->new;
    lives_ok { $site->_assert_tt_config } 'no croak when .ttreerc present';
};

subtest '_run_ttree renders sample.tt through wrapper.tt' => sub {
    my $tempdir = Path::Tiny->tempdir;
    chdir $tempdir;

    $tempdir->child('tmp/include')->mkpath;
    path('t/fixtures/ttree/include/wrapper.tt')->absolute($cwd)
        ->copy( $tempdir->child('tmp/include/wrapper.tt')->stringify );
    path('t/fixtures/ttree/sample.tt')->absolute($cwd)
        ->copy( $tempdir->child('tmp/sample.tt')->stringify );

    # Point ttree at the fixture rc file so it picks up `suffix tt=html`.
    local $ENV{TTREERC}
        = path('t/fixtures/ttree/.ttreerc')->absolute($cwd)->stringify;

    my $site = Ovid::Site->new;
    lives_ok { $site->_run_ttree } '_run_ttree completes without dying';

    my $out = $tempdir->child('sample.html');
    ok -e $out, 'sample.html generated';
    my $html = $out->slurp_utf8;
    like $html, qr{<html><body>}, 'wrapper opens HTML/body';
    like $html, qr{<h1>Sample</h1>}, 'inner heading present';
    like $html, qr{Hello from sample\.tt}, 'inner paragraph present';
    like $html, qr{</body></html>}, 'wrapper closes HTML/body';

    chdir $cwd;
};

subtest '_run_ttree_single renders one file' => sub {
    my $tempdir = Path::Tiny->tempdir;
    chdir $tempdir;

    $tempdir->child('tmp/include')->mkpath;
    path('t/fixtures/ttree/include/wrapper.tt')->absolute($cwd)
        ->copy( $tempdir->child('tmp/include/wrapper.tt')->stringify );
    path('t/fixtures/ttree/sample.tt')->absolute($cwd)
        ->copy( $tempdir->child('tmp/sample.tt')->stringify );

    # Point ttree at the fixture rc file so it picks up `suffix tt=html`.
    local $ENV{TTREERC}
        = path('t/fixtures/ttree/.ttreerc')->absolute($cwd)->stringify;

    my $site = Ovid::Site->new;
    lives_ok { $site->_run_ttree_single('tmp/sample.tt') }
        '_run_ttree_single completes without dying';

    ok -e $tempdir->child('sample.html'), 'sample.html generated';

    chdir $cwd;
};

subtest '_run_ttree_single dies on a missing source file' => sub {
    my $tempdir = Path::Tiny->tempdir;
    chdir $tempdir;

    my $site = Ovid::Site->new;
    throws_ok { $site->_run_ttree_single('tmp/does-not-exist.tt') }
        qr/does not exist before calling ttree/,
        'guards against ttree being called on a missing file';

    chdir $cwd;
};

subtest '_get_git_lastmod returns a YYYY-MM-DD date for a committed file' => sub {
    my $site = Ovid::Site->new;
    # lib/Ovid/Site.pm is definitely in this repo's history.
    my $date = $site->_get_git_lastmod('lib/Ovid/Site.pm');
    like $date, qr/^\d{4}-\d{2}-\d{2}$/, "git path returns YYYY-MM-DD ($date)";
};

subtest '_get_git_lastmod falls back to mtime for an untracked file' => sub {
    my $tempfile = Path::Tiny->tempfile( SUFFIX => '.txt' );
    $tempfile->spew('whatever');

    # Set a known mtime so we can assert on the date.
    my $epoch = 1_577_836_800;    # 2020-01-01 00:00:00 UTC
    utime $epoch, $epoch, "$tempfile";

    my $site = Ovid::Site->new;
    my $date = $site->_get_git_lastmod("$tempfile");
    like $date, qr/^\d{4}-\d{2}-\d{2}$/, "mtime fallback returns YYYY-MM-DD ($date)";
    # Don't assert the exact date — timezone of the local machine may
    # shift "2020-01-01 00:00:00 UTC" to 2019-12-31 in negative offsets.
    like $date, qr/^(?:2019-12-31|2020-01-01)$/,
        'mtime fallback date is one of the two valid timezone-shifted values';
};

done_testing;
