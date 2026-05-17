package TestHelper::Site;

use v5.40;
use Path::Tiny qw(path);
use Cwd        qw(getcwd);
use DBI;
use Ovid::Site;

use Exporter 'import';
our @EXPORT_OK = qw(setup_tempdir_site make_test_dbh);

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

# Returns a fresh dbi:SQLite::memory: handle with the test schema
# already deployed. The schema file is read from the repo, not from
# any cwd-relative path, so tests that have chdir'd into a tempdir
# still work.
sub make_test_dbh () {
    my $dbh = DBI->connect( 'dbi:SQLite::memory:', '', '', { RaiseError => 1 } );
    my $schema_path = path(__FILE__)
        ->parent->parent->parent->child('fixtures/test-schema.sql');
    my $sql = $schema_path->slurp_utf8;
    for my $stmt ( split /;\s*\n/, $sql ) {
        next unless $stmt =~ /\S/;
        $dbh->do($stmt);
    }
    return $dbh;
}

1;
