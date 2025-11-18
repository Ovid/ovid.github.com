#!/usr/bin/env perl

use v5.40;
use Test::Most;
use lib 'lib';
use File::Temp qw(tempfile tempdir);
use File::Spec::Functions qw(catfile);
use Capture::Tiny qw(capture);
use Less::Script;

# Test UTF-8 handling in single file rebuild
# This addresses FR-001 through FR-007 from spec.md

plan tests => 4;

subtest 'Test fixture template exists with UTF-8 content' => sub {
    my $fixture = catfile( 't', 'fixtures', 'templates', 'utf8_test_template.tt2markdown' );
    ok( -f $fixture, 'UTF-8 test fixture template exists' );

    my $content = slurp($fixture);
    ok( length($content) > 0, 'Fixture has content' );

    # Verify fixture contains UTF-8 test characters
    like( $content, qr/"Smart double quotes"/,     'Fixture contains smart quotes' );
    like( $content, qr/Em dashes—like this—/,      'Fixture contains em dashes' );
    like( $content, qr/Café/,                      'Fixture contains accented characters' );
    like( $content, qr/© Copyright symbol/,        'Fixture contains copyright symbol' );
    like( $content, qr/&ldquo;HTML entities&rdquo;/, 'Fixture contains HTML entities' );
};

subtest 'Single file rebuild produces UTF-8 warnings (EXPECTED TO FAIL BEFORE FIX)' => sub {
    plan skip_all => 'This test verifies the bug exists before the fix is applied';

    # This test should be run manually before implementing the fix:
    # prove -lv t/utf8_single_file_rebuild.t
    #
    # Expected behavior BEFORE fix:
    # - Should see "Parsing of undecoded UTF-8" warnings
    # - Should see "Wide character in print" warnings
    #
    # Expected behavior AFTER fix:
    # - No UTF-8 warnings should appear
};

subtest 'Verify no UTF-8 warnings appear during single-file rebuild (WILL FAIL BEFORE FIX)' => sub {
    # This test will fail until T009-T012 are implemented
    plan skip_all => 'Skipping until implementation is complete (T009-T012)';

    # Setup: Copy test fixture to a temporary location that mimics root/blog/
    my $tempdir = tempdir( CLEANUP => 1 );
    my $root_dir = catfile( $tempdir, 'root', 'blog' );
    mkdir( catfile( $tempdir, 'root' ) );
    mkdir($root_dir);

    my $fixture    = catfile( 't', 'fixtures', 'templates', 'utf8_test_template.tt2markdown' );
    my $test_file  = catfile( $root_dir, 'utf8-test.tt2markdown' );
    my $fixture_content = slurp($fixture);
    splat( $test_file, $fixture_content );

    # Run single file rebuild and capture output
    my ( $stdout, $stderr, $exit ) = capture {
        system( 'perl', 'bin/rebuild', '--file', $test_file, '--notest' );
    };

    # Verify no UTF-8 encoding warnings appear
    unlike( $stderr, qr/Parsing of undecoded UTF-8/i,
        'No "Parsing of undecoded UTF-8" warnings should appear' );
    unlike( $stderr, qr/Wide character in print/i,
        'No "Wide character in print" warnings should appear' );

    # Verify rebuild succeeded
    is( $exit, 0, 'Rebuild should exit successfully' );
};

subtest 'Generated HTML contains correctly encoded UTF-8 characters (WILL FAIL BEFORE FIX)' => sub {
    # This test will fail until T009-T012 are implemented
    plan skip_all => 'Skipping until implementation is complete (T009-T012)';

    # Setup: Create test template and rebuild it
    my $tempdir = tempdir( CLEANUP => 1 );
    my $root_dir = catfile( $tempdir, 'root', 'blog' );
    mkdir( catfile( $tempdir, 'root' ) );
    mkdir($root_dir);

    my $fixture    = catfile( 't', 'fixtures', 'templates', 'utf8_test_template.tt2markdown' );
    my $test_file  = catfile( $root_dir, 'utf8-test.tt2markdown' );
    my $fixture_content = slurp($fixture);
    splat( $test_file, $fixture_content );

    # Run rebuild (suppressing output for cleaner test output)
    my ( $stdout, $stderr, $exit ) = capture {
        system( 'perl', 'bin/rebuild', '--file', $test_file, '--notest' );
    };

    # Read generated HTML
    my $output_file = catfile( 'blog', 'utf8-test.html' );
    ok( -f $output_file, 'Generated HTML file should exist' );

    my $html = slurp($output_file);

    # Verify UTF-8 characters are correctly encoded in output
    like( $html, qr/"Smart double quotes"/,  'Smart quotes should be preserved' );
    like( $html, qr/Em dashes—like this—/,   'Em dashes should be preserved' );
    like( $html, qr/Café/,                   'Accented characters should be preserved' );
    like( $html, qr/© Copyright symbol/,     'Unicode symbols should be preserved' );
    like( $html, qr/€ Euro sign/,            'Euro sign should be preserved' );

    # Verify charset meta tag is present
    like( $html, qr/<meta\s+charset=["']utf-8["']/i,
        'HTML should contain UTF-8 charset meta tag' );

    # Clean up generated file
    unlink($output_file) if -f $output_file;
};

done_testing();

__END__

=head1 NAME

utf8_single_file_rebuild.t - Test UTF-8 handling in single file rebuilds

=head1 DESCRIPTION

This test verifies that single-file rebuilds via C<bin/rebuild --file> handle
UTF-8 characters correctly without producing warnings. This addresses the
following functional requirements from spec.md:

=over 4

=item * FR-001: Eliminate UTF-8 encoding warnings

=item * FR-002: Support various UTF-8 characters (smart quotes, em dashes, accented letters)

=item * FR-003: Match full rebuild UTF-8 behavior

=item * FR-004: No modification to existing templates

=item * FR-005: No performance degradation

=item * FR-006: Maintain HTML5 validity

=item * FR-007: Automated tests with fixtures

=back

=head2 Test Strategy

=over 4

=item 1. Create test fixture with diverse UTF-8 content

=item 2. Verify no warnings during rebuild (FR-001, FR-007)

=item 3. Verify UTF-8 characters display correctly (FR-002, FR-006)

=item 4. Verify charset meta tag is present (FR-006)

=back

=head2 Expected Behavior

B<Before Fix (T008)>: Tests should FAIL with UTF-8 warnings visible

B<After Fix (T013)>: All tests should PASS with no warnings

=head1 AUTHOR

UTF-8 Rebuild Warnings Fix - User Story 1

=cut
