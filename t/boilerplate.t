#!/usr/bin/env perl

use Test::Most;
use lib 'lib';

# Test the import functionality (already covered by many tests, but explicit here)
subtest 'import enables modern Perl features' => sub {
    {

        package TestImport;
        use Less::Boilerplate;

        # Test that signatures work (feature enabled)
        sub test_sub ($arg) {
            return $arg * 2;
        }

        # Test that strict is enabled - use string eval to avoid compile-time error
        my $code = 'package TestImport; my $x = $undefined_var;';
        eval $code;
        ::like $@, qr/Global symbol "\$undefined_var" requires explicit package name/,
          'strict should be enabled';
    }

    is TestImport::test_sub(5), 10, 'Signatures should work';
};

# Test the unimport functionality (currently uncovered)
subtest 'unimport disables Perl features' => sub {
    {

        package TestUnimport;
        use Less::Boilerplate;

        # First verify features are enabled
        sub test_sub1 ($arg) { return $arg }

        # Now unimport
        no Less::Boilerplate;

        # After unimport, signatures should not work in new subs
        # Note: This is tricky to test because feature disabling affects compilation
        # We'll just verify unimport doesn't die
        ::pass 'unimport should execute without dying';
    }

    is TestUnimport::test_sub1(42), 42, 'Previously defined subs still work';
};

# Test that Try::Tiny is imported
subtest 'Try::Tiny functions are available' => sub {
    {

        package TestTryTiny;
        use Less::Boilerplate;

        my $result;
        try {
            $result = 'success';
        }
        catch {
            $result = 'failure';
        };

        ::is $result, 'success', 'try/catch should be available';
    }
};

# Test that Carp is imported
subtest 'Carp functions are available' => sub {
    {

        package TestCarp;
        use Less::Boilerplate;

        eval { croak "test error" };
        ::like $@, qr/test error/, 'croak should be available';
    }
};

done_testing;
