#!/usr/bin/env perl

use Test::Most;
use Less::Boilerplate;
use Test2::Plugin::UTF8;

# Module under test
use Ovid::Site::Utils qw(
  use_smart_quotes
  get_image_description
  set_image_description
);

# Ensure we have a database connection
my $dbh = Less::Script::dbh();
plan skip_all => "No database connection available"
  unless $dbh;

# Set up the test database environment
BEGIN {
    # Ensure we're in test mode
    $ENV{LESS_SCRIPT_ENV} //= 'test';
}

# Wrap all tests in a transaction
my $transaction_active = 0;

sub start_transaction {
    $dbh->begin_work;
    $transaction_active = 1;
}

sub rollback_transaction {
    if ($transaction_active) {
        $dbh->rollback;
        $transaction_active = 0;
    }
}

# Ensure cleanup happens even on test failures
END {
    rollback_transaction();
}

subtest 'use_smart_quotes tests' => sub {
    my %tests = (

        # Basic quotes
        q{"Hello"} => qq{“Hello”},
        q{Hello"}  => qq{Hello”},
        q{"Hello}  => qq{“Hello},

        # Quotes between words
        q{don"t}           => q{don&quot;t},
        q{The "quick" fox} => qq{The “quick” fox},

        # Quotes with punctuation
        q{"Hello!"}         => qq{“Hello!”},
        q{"Hello," he said} => qq{“Hello,” he said},

        # Apostrophes
        q{don't} => qq{don’t},
        q{'tis}  => qq{‘tis},
        q{'Twas} => qq{‘Twas},

        # Complex cases
        q{"Hello," she said, "goodbye!"} => qq{“Hello,” she said, “goodbye!”},
        q{The dog's "bone" was lost}     => qq{The dog’s “bone” was lost},

        # Edge cases
        q{""} => qq{“”},
        q{'}  => qq{'},
        q{"}  => qq{"},
    );
    for my $input ( sort keys %tests ) {
        my $expected = $tests{$input};
        is( use_smart_quotes($input),
            $expected,
            "Smart quotes: '$input' -> '$expected'"
        );
    }
};

subtest 'image description database tests' => sub {
    start_transaction();

    # First, ensure our test image doesn't exist
    $dbh->do( 'DELETE FROM images WHERE filename = ?', {}, 'test.jpg' );

    # Insert test data
    $dbh->do(
        'INSERT INTO images (filename, description) VALUES (?, ?)',
        {},
        'test.jpg',
        'Initial description'
    );

    # Test get_image_description
    my $description = get_image_description('test.jpg');
    is( $description,
        'Initial description',
        'Retrieved correct initial description'
    );

    # Test nonexistent image
    my $null_description = get_image_description('nonexistent.jpg');
    is( $null_description,
        undef,
        'Null description for nonexistent image'
    );

    # Test set_image_description
    set_image_description( 'test.jpg', 'Updated description' );

    $description = get_image_description('test.jpg');
    is( $description,
        'Updated description',
        'Description was inserted successfully'
    );

    # Test set_image_description
    set_image_description( 'test.jpg', 'Reupdated description' );

    $description = get_image_description('test.jpg');
    is( $description,
        'Reupdated description',
        'Description was updated successfully'
    );
    rollback_transaction();
};

done_testing();
