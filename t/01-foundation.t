#!/usr/bin/env perl

use v5.40;
use Test::Most;
use File::Spec;
use File::Basename qw(dirname);
use Cwd            qw(abs_path);
use DBI;

# Test that foundational infrastructure is working correctly
# This validates Phase 2 completion

plan tests => 4;

subtest 'Test fixtures directory structure exists' => sub {
    my @required_dirs = (
        File::Spec->catdir( 't', 'fixtures' ),
        File::Spec->catdir( 't', 'fixtures', 'templates' ),
        File::Spec->catdir( 't', 'fixtures', 'markdown' ),
        File::Spec->catdir( 't', 'fixtures', 'data' ),
    );

    for my $dir (@required_dirs) {
        ok( -d $dir, "Required directory exists: $dir" );
    }
};

subtest 'Test database fixture is valid' => sub {
    my $test_db = File::Spec->catfile( 't', 'fixtures', 'test.db' );

    ok( -f $test_db, 'Test database file exists' );

    my $dbh = DBI->connect( "dbi:SQLite:dbname=$test_db", "", "" );
    ok( defined $dbh, 'Can connect to test database' );

    # Verify schema tables exist
    my @tables = qw(articles article_types images);
    for my $table (@tables) {
        my $sth = $dbh->prepare("SELECT name FROM sqlite_master WHERE type='table' AND name=?");
        $sth->execute($table);
        my ($found) = $sth->fetchrow_array();
        ok( defined $found, "Table $table exists in schema" );
    }

    # Verify test data exists
    my $sth = $dbh->prepare("SELECT COUNT(*) FROM articles");
    $sth->execute();
    my ($count) = $sth->fetchrow_array();
    cmp_ok( $count, '>=', 3, 'Test database has sample articles' );

    $sth = $dbh->prepare("SELECT COUNT(*) FROM article_types");
    $sth->execute();
    ($count) = $sth->fetchrow_array();
    cmp_ok( $count, '>=', 2, 'Test database has sample article types' );

    $sth = $dbh->prepare("SELECT COUNT(*) FROM images");
    $sth->execute();
    ($count) = $sth->fetchrow_array();
    cmp_ok( $count, '>=', 2, 'Test database has sample images' );

    $sth->fetchall_arrayref();    # discard remainder so we can disconnect cleanly

    $dbh->disconnect();
};

subtest 'Usage analysis script exists and is executable' => sub {
    my $script = File::Spec->catfile( 'bin', 'analyze-usage' );

    ok( -f $script, 'analyze-usage script exists' );
    ok( -x $script, 'analyze-usage script is executable' );

    # Test help output
    my $output    = `perl $script --help 2>&1`;
    my $exit_code = $? >> 8;

    is( $exit_code, 0, 'Script exits successfully with --help' );
    like( $output, qr/Usage:/, 'Script provides usage information' );

    # Test error on missing required arguments
    $output    = `perl $script 2>&1`;
    $exit_code = $? >> 8;

    isnt( $exit_code, 0, 'Script exits with error when missing required arguments' );
};

subtest 'Integration test infrastructure' => sub {
    my $integration_dir = File::Spec->catdir( 't', 'integration' );
    ok( -d $integration_dir, 'Integration test directory exists' );

    my $readme = File::Spec->catfile( $integration_dir, 'README.md' );
    ok( -f $readme, 'Integration test README exists' );
};

done_testing();

__END__

=head1 NAME

01-foundation.t - Integration tests for Phase 2 foundational infrastructure

=head1 DESCRIPTION

This test validates that all Phase 2 foundational infrastructure is in place:

=over 4

=item * Test fixtures directory structure

=item * SQLite test database with schema and data

=item * Usage analysis script (bin/analyze-usage)

=item * Integration test infrastructure

=back

=head1 AUTHOR

Test Coverage Improvement Project - Phase 2

=cut
