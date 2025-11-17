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
    unlike $html, qr/<noscript>/,
      'Does not contain noscript block (uses progressive enhancement instead)';
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
    like $html, qr/class="fa fa-chevron-right collapsible-icon"/,
      'Output contains .collapsible-icon class with Font Awesome (chevron-right when collapsed)';
    
    # Verify short description class
    like $html, qr/class="collapsible-short"/,
      'Output contains .collapsible-short class';
    
    # Verify content class
    like $html, qr/class="collapsible-content"/,
      'Output contains .collapsible-content class';
    
    # Note: No noscript classes - we use progressive enhancement
    # Content is visible by default, JavaScript adds 'js-enabled' class to hide it
    unlike $html, qr/noscript/,
      'Does not contain noscript elements (progressive enhancement approach)';
    
    # Verify all classes are present in a single collapse() call
    my @expected_classes = (
        'collapsible-section',
        'collapsible-trigger',
        'collapsible-icon',
        'collapsible-short',
        'collapsible-content',
    );
    
    for my $class (@expected_classes) {
        like $html, qr/\Q$class\E/,
          "Class '$class' is present in output";
    }
};

# ========================================
# User Story 3 Tests - Template Syntax for Authors
# ========================================

subtest 'Blogdown processing (T033)' => sub {
    my $context = Template::Context->new();
    my $plugin  = Template::Plugin::Ovid->new($context);

    # Test code block with ~~~perl syntax
    my $markdown_content = <<'MARKDOWN';
Example code:

~~~perl
use v5.40;
say "Hello, World!";
~~~
MARKDOWN

    my $html = $plugin->collapse( "Code Example", $markdown_content );

    # Verify blogdown processes the code block
    like $html, qr/<pre/,
      'Blogdown converts code fence to <pre> tag';

    like $html, qr/<code/,
      'Blogdown creates <code> tag for syntax highlighting';

    like $html, qr/class="[^"]*language-perl/,
      'Blogdown adds language-perl class for syntax highlighting';

    # Verify the code content is preserved
    like $html, qr/use v5\.40/,
      'Code content is preserved in output';

    like $html, qr/Hello, World!/,
      'String content is preserved in output';

    # Test Markdown lists
    my $list_content = <<'MARKDOWN';
Key benefits:

- **Improved readability**: Keep content focused
- **Progressive disclosure**: Let readers choose depth
- Better organization
MARKDOWN

    $html = $plugin->collapse( "Benefits", $list_content );

    # Verify blogdown processes the list
    like $html, qr/<ul>/,
      'Blogdown converts Markdown list to <ul>';

    like $html, qr/<li>/,
      'Blogdown creates <li> elements';

    like $html, qr/<strong>Improved readability<\/strong>/,
      'Blogdown processes bold markdown (**text**)';

    # Test external links
    my $link_content = 'See [the documentation](https://example.com) for details.';

    $html = $plugin->collapse( "Resources", $link_content );

    # Verify blogdown processes external links with target="_blank"
    like $html, qr/<a [^>]*href="https:\/\/example\.com"/,
      'Blogdown converts Markdown link to anchor tag';

    like $html, qr/<a [^>]*target="_blank"/,
      'Blogdown adds target="_blank" for external links';

    like $html, qr/fa-external-link/,
      'Blogdown adds external link icon';
};

subtest 'Blogdown integration test (T036)' => sub {
    my $tt = Template->new(
        {   INCLUDE_PATH => 't/fixtures/collapsible-sections',
        }
    );

    my $output;
    ok $tt->process( 'blogdown-content.tt', {}, \$output ),
      'Template with blogdown content processes successfully'
      or diag $tt->error();

    # Read expected output
    my $expected_file = path('t/fixtures/collapsible-sections/expected/blogdown-content.html');
    my $expected      = $expected_file->slurp_utf8;

    # Verify key blogdown features are present in output
    like $output, qr/<pre class="scrolled">/,
      'Blogdown creates syntax-highlighted code block';

    like $output, qr/class="language-perl"/,
      'Blogdown adds language-perl class for code highlighting';

    like $output, qr/<ul>/,
      'Blogdown converts Markdown lists to HTML lists';

    like $output, qr/<strong>Progressive disclosure<\/strong>/,
      'Blogdown processes bold Markdown syntax';

    like $output, qr/target="_blank"/,
      'Blogdown adds target="_blank" to external links';

    like $output, qr/fa-external-link/,
      'Blogdown adds external link icons';

    # Verify the content appears in the collapsible-content div
    # Note: No duplication - progressive enhancement means content is only in one place
    like $output, qr/<div id="collapsible-content-1"[^>]*>.*?<h2>Code Block Example<\/h2>/s,
      'Blogdown processed content appears in collapsible-content div';

    unlike $output, qr/collapsible-content-noscript/,
      'No noscript duplication (progressive enhancement approach)';
};

subtest 'Nested TT directives edge case (T039)' => sub {
    my $tt = Template->new(
        {   INCLUDE_PATH => 't/fixtures/collapsible-sections',
        }
    );

    # Test that collapse() can contain pre-processed TT content
    # For example, you can build content with concatenation and other TT directives
    my $template_with_html = '[% USE Ovid -%]
[% SET note = Ovid.add_note("This is a footnote") -%]
[% Ovid.collapse(
    "Section with processed content",
    "This content has a reference." _ note _ " More content."
) %]';

    my $output;
    ok $tt->process( \$template_with_html, {}, \$output ),
      'Template with pre-processed TT content works'
      or diag $tt->error();

    # The processed footnote HTML should be in the output
    like $output, qr/<sup>/,
      'Pre-processed TT content (footnote) appears in collapse output';

    # Test that collapse() works with complex blogdown and regular content mixed
    my $template_mixed = '[% USE Ovid -%]
[% Ovid.collapse(
    "Mixed content",
    "Regular text with **bold** and a list:

- Item 1
- Item 2

More text here."
) %]';

    $output = '';
    ok $tt->process( \$template_mixed, {}, \$output ),
      'Template with mixed Markdown content processes successfully'
      or diag $tt->error();

    like $output, qr/<strong>bold<\/strong>/,
      'Blogdown processes bold Markdown in mixed content';

    like $output, qr/<li>Item 1<\/li>/,
      'Blogdown processes lists in mixed content';
};

done_testing;
