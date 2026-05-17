package TestHelper::Site;

use v5.40;
use Path::Tiny qw(path);
use Cwd        qw(getcwd);
use Ovid::Site;

use Exporter 'import';
our @EXPORT_OK = qw(setup_tempdir_site);

# Returns ($site, $tempdir) with chdir already done into a tempdir
# containing a minimal root/ skeleton. Caller is responsible for
# chdir'ing back when finished (typically in an END or after the
# subtest).
sub setup_tempdir_site (%args) {
    my $tempdir = Path::Tiny->tempdir;
    chdir $tempdir;
    $tempdir->child('root/include')->mkpath;
    $tempdir->child('root/tags')->mkpath;
    $tempdir->child('root/static')->mkpath;

    my $site = Ovid::Site->new(%args);
    return ( $site, $tempdir );
}

1;
