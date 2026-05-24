#!/usr/bin/env perl

use Test::Most;
use lib 'lib';
use lib 't/lib';
use Less::Boilerplate;
use Test2::Plugin::UTF8;
use Path::Tiny   qw(path);
use Cwd          qw(getcwd);
use Capture::Tiny qw(capture);
use Ovid::Site;

my $cwd = getcwd();
END { chdir $cwd }

sub _in_tempdir ($code) {
    my $tempdir = Path::Tiny->tempdir;
    chdir $tempdir;
    eval { $code->($tempdir); 1 } or do {
        my $err = $@;
        chdir $cwd;
        die $err;
    };
    chdir $cwd;
}

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
    _in_tempdir sub ($tempdir) {
        $tempdir->child('tmp/include')->mkpath;
        path('t/fixtures/ttree/include/wrapper.tt')->absolute($cwd)
            ->copy( $tempdir->child('tmp/include/wrapper.tt')->stringify );
        path('t/fixtures/ttree/sample.tt')->absolute($cwd)
            ->copy( $tempdir->child('tmp/sample.tt')->stringify );

        # Point ttree at the fixture rc file so it picks up `suffix tt=html`.
        local $ENV{TTREERC}
            = path('t/fixtures/ttree/.ttreerc')->absolute($cwd)->stringify;

        my $site = Ovid::Site->new;
        # Wrap in capture() so the "Rebuilding pages..." diagnostic from
        # _run_ttree doesn't leak into the test output.
        lives_ok { capture { $site->_run_ttree } } '_run_ttree completes without dying';

        my $out = $tempdir->child('sample.html');
        ok -e $out, 'sample.html generated';
        my $html = $out->slurp_utf8;
        like $html, qr{<html><body>}, 'wrapper opens HTML/body';
        like $html, qr{<h1>Sample</h1>}, 'inner heading present';
        like $html, qr{Hello from sample\.tt}, 'inner paragraph present';
        like $html, qr{</body></html>}, 'wrapper closes HTML/body';
    };
};

subtest '_run_ttree_single renders one file' => sub {
    _in_tempdir sub ($tempdir) {
        $tempdir->child('tmp/include')->mkpath;
        path('t/fixtures/ttree/include/wrapper.tt')->absolute($cwd)
            ->copy( $tempdir->child('tmp/include/wrapper.tt')->stringify );
        path('t/fixtures/ttree/sample.tt')->absolute($cwd)
            ->copy( $tempdir->child('tmp/sample.tt')->stringify );

        # Point ttree at the fixture rc file so it picks up `suffix tt=html`.
        local $ENV{TTREERC}
            = path('t/fixtures/ttree/.ttreerc')->absolute($cwd)->stringify;

        my $site = Ovid::Site->new;
        # Wrap in capture() so the verbose "Running ttree in-process..."
        # diagnostic from _execute_ttree doesn't leak into the test output.
        lives_ok { capture { $site->_run_ttree_single('tmp/sample.tt') } }
            '_run_ttree_single completes without dying';

        ok -e $tempdir->child('sample.html'), 'sample.html generated';
    };
};

subtest '_run_ttree_single dies on a missing source file' => sub {
    _in_tempdir sub ($tempdir) {
        my $site = Ovid::Site->new;
        throws_ok { $site->_run_ttree_single('tmp/does-not-exist.tt') }
            qr/does not exist before calling ttree/,
            'guards against ttree being called on a missing file';
    };
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

subtest '_resolve_source prefers .tt2markdown when both extensions exist' => sub {
    _in_tempdir sub ($tempdir) {
        $tempdir->child('root/articles')->mkpath;
        $tempdir->child('root/articles/foo.tt2markdown')->spew('md source');
        $tempdir->child('root/articles/foo.tt')->spew('tt source');

        my $site = Ovid::Site->new;
        is $site->_resolve_source('articles/foo.html'),
            'root/articles/foo.tt2markdown',
            '.tt2markdown wins when both exist';
    };
};

subtest '_resolve_source returns .tt when only .tt exists' => sub {
    _in_tempdir sub ($tempdir) {
        $tempdir->child('root')->mkpath;
        $tempdir->child('root/foo.tt')->spew('tt source');

        my $site = Ovid::Site->new;
        is $site->_resolve_source('foo.html'),
            'root/foo.tt',
            '.tt is used when no .tt2markdown sibling exists';
    };
};

subtest '_resolve_source returns undef when neither source extension exists' => sub {
    _in_tempdir sub ($tempdir) {
        my $site = Ovid::Site->new;
        is $site->_resolve_source('articles_2.html'),
            undef,
            'undef returned when neither .tt2markdown nor .tt is on disk';
    };
};

subtest '_get_git_lastmod uses the source template date for a generated HTML' => sub {
    # root/404.tt is committed in this repo (with no .tt2markdown sibling).
    # 404.html, if it exists, is the generated output — possibly untracked.
    # _get_git_lastmod('404.html') should resolve to root/404.tt and return
    # that file's committed date, regardless of the HTML's own state.
    my $site = Ovid::Site->new;

    chomp( my $raw = `git log -1 --format=%ai -- root/404.tt` );
    $raw =~ /^(\d{4}-\d{2}-\d{2})/
        or die "unexpected git log output for root/404.tt: [$raw]";
    my $expected = $1;

    is $site->_get_git_lastmod('404.html'), $expected,
        "lastmod for 404.html comes from root/404.tt ($expected)";
};

done_testing;
