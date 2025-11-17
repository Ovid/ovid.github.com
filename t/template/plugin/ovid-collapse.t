#!/usr/bin/env perl

use Test::Most;
use lib 'lib';
use Template;
use Template::Plugin::Ovid;
use Template::Context;
use Path::Tiny qw(path);

# ========================================
# User Story 1 Tests - Basic Collapsible Content Display
# ========================================

subtest 'Parameter validation (T006)' => sub {
    my $context = Template::Context->new();
    my $plugin  = Template::Plugin::Ovid->new($context);

    # Test undefined short_description
    throws_ok {
        $plugin->collapse( undef, "content" );
    }
    qr/collapse\(\) requires short_description parameter/,
      'Dies when short_description is undefined';

    # Test empty short_description
    throws_ok {
        $plugin->collapse( "", "content" );
    }
    qr/collapse\(\) requires short_description parameter/,
      'Dies when short_description is empty';

    # Test whitespace-only short_description
    throws_ok {
        $plugin->collapse( "   ", "content" );
    }
    qr/collapse\(\) requires short_description parameter/,
      'Dies when short_description is whitespace-only';

    # Test undefined full_content
    throws_ok {
        $plugin->collapse( "summary", undef );
    }
    qr/collapse\(\) requires full_content parameter/,
      'Dies when full_content is undefined';

    # Test empty full_content
    throws_ok {
        $plugin->collapse( "summary", "" );
    }
    qr/collapse\(\) requires full_content parameter/,
      'Dies when full_content is empty';

    # Test whitespace-only full_content
    throws_ok {
        $plugin->collapse( "summary", "   " );
    }
    qr/collapse\(\) requires full_content parameter/,
      'Dies when full_content is whitespace-only';
};

subtest 'Basic collapse() method invocation (T007)' => sub {
    my $context = Template::Context->new();
    my $plugin  = Template::Plugin::Ovid->new($context);

    my $result = $plugin->collapse( "Short description", "Full content here" );

    ok defined($result),  'collapse() returns a defined value';
    ok length($result),   'collapse() returns non-empty value';
    like $result, qr/</, 'Result contains HTML tags';
};

subtest 'HTML structure test (T008)' => sub {
    my $context = Template::Context->new();
    my $plugin  = Template::Plugin::Ovid->new($context);

    my $html = $plugin->collapse( "Summary", "Details" );

    like $html, qr/<div class="collapsible-section">/,
      'Contains collapsible-section container';
    like $html, qr/<div class="collapsible-trigger"/,
      'Contains collapsible-trigger element';
    like $html, qr/id="collapsible-content-\d+"/,
      'Contains collapsible-content element with ID';
    like $html, qr/class="collapsible-content"/,
      'Contains collapsible-content class';
    like $html, qr/<noscript>/,
      'Contains noscript fallback';
};

subtest 'Unique ID generation test (T009)' => sub {
    my $context = Template::Context->new();
    my $plugin  = Template::Plugin::Ovid->new($context);

    my $html1 = $plugin->collapse( "First", "Content 1" );
    my $html2 = $plugin->collapse( "Second", "Content 2" );
    my $html3 = $plugin->collapse( "Third", "Content 3" );

    like $html1, qr/collapsible-trigger-1/,
      'First call generates ID with -1';
    like $html1, qr/collapsible-content-1/,
      'First call generates content ID with -1';

    like $html2, qr/collapsible-trigger-2/,
      'Second call generates ID with -2';
    like $html2, qr/collapsible-content-2/,
      'Second call generates content ID with -2';

    like $html3, qr/collapsible-trigger-3/,
      'Third call generates ID with -3';
    like $html3, qr/collapsible-content-3/,
      'Third call generates content ID with -3';

    unlike $html1, qr/collapsible-trigger-2/,
      'First section does not contain second ID';
    unlike $html2, qr/collapsible-trigger-3/,
      'Second section does not contain third ID';
};

subtest 'Fixture-based integration test (T012)' => sub {
    my $tt = Template->new(
        {   INCLUDE_PATH => 't/fixtures/collapsible-sections',
        }
    );

    my $output;
    ok $tt->process( 'basic.tt', {}, \$output ),
      'Template processes successfully'
      or diag $tt->error();

    # Read expected output
    my $expected_file = path('t/fixtures/collapsible-sections/expected/basic.html');
    my $expected      = $expected_file->slurp_utf8;

    # Normalize whitespace for comparison
    $output   =~ s/\s+/ /g;
    $expected =~ s/\s+/ /g;
    $output   =~ s/>\s+</></g;
    $expected =~ s/>\s+</></g;

    is $output, $expected, 'Generated HTML matches expected output';
};

# ========================================
# User Story 2 Tests - Full-Width Visual Integration
# ========================================

subtest 'CSS selector tests (T021)' => sub {
    my $context = Template::Context->new();
    my $plugin  = Template::Plugin::Ovid->new($context);

    my $html = $plugin->collapse( "Summary text", "Details here" );

    like $html, qr/class="collapsible-section"/,
      'Output contains .collapsible-section class';
    
    like $html, qr/<div class="collapsible-section">/,
      'collapsible-section is a div element';
    
    # Verify the class appears exactly once per collapse() call
    my @matches = $html =~ /class="collapsible-section"/g;
    is scalar(@matches), 1, 'collapsible-section class appears exactly once';
};

subtest 'CSS class verification tests (T022)' => sub {
    my $context = Template::Context->new();
    my $plugin  = Template::Plugin::Ovid->new($context);

    my $html = $plugin->collapse( "Click to expand", "Full content" );

    # Verify trigger class
    like $html, qr/class="collapsible-trigger"/,
      'Output contains .collapsible-trigger class';
    
    # Verify icon class
    like $html, qr/class="fa fa-chevron-down collapsible-icon"/,
      'Output contains .collapsible-icon class with Font Awesome';
    
    # Verify short description class
    like $html, qr/class="collapsible-short"/,
      'Output contains .collapsible-short class';
    
    # Verify content class
    like $html, qr/class="collapsible-content"/,
      'Output contains .collapsible-content class';
    
    # Verify noscript fallback classes
    like $html, qr/class="collapsible-section-noscript"/,
      'Output contains .collapsible-section-noscript class';
    
    like $html, qr/class="collapsible-short-noscript"/,
      'Output contains .collapsible-short-noscript class';
    
    like $html, qr/class="collapsible-content-noscript"/,
      'Output contains .collapsible-content-noscript class';
    
    # Verify all classes are present in a single collapse() call
    my @expected_classes = (
        'collapsible-section',
        'collapsible-trigger',
        'collapsible-icon',
        'collapsible-short',
        'collapsible-content',
        'collapsible-section-noscript',
        'collapsible-short-noscript',
        'collapsible-content-noscript',
    );
    
    for my $class (@expected_classes) {
        like $html, qr/\Q$class\E/,
          "Class '$class' is present in output";
    }
};

done_testing;
