#!/usr/bin/env perl

use v5.40;
use Test::Most;
use lib 'lib';
use Template::Plugin::Ovid;
use Path::Tiny 'path';
use File::Temp 'tempdir';
use Test::MockModule;

#
# Test Helper Subroutines for Footnote Testing
#

# Extract footnote dialog spans from HTML
sub extract_footnote_dialogs ($html) {
    my @dialogs = $html =~ m{<span[^>]*class="[^"]*open-dialog[^"]*"[^>]*>.*?</span>}gs;
    return @dialogs;
}

# Extract noscript anchor links from HTML
sub extract_noscript_anchors ($html) {
    my @anchors = $html =~ m{<noscript>.*?<a[^>]*href="#footnote-\d+"[^>]*>.*?</a>.*?</noscript>}gs;
    return @anchors;
}

# Validate HTML has matching IDs (no duplicates)
sub validate_unique_ids ($html) {
    my %ids;
    while ( $html =~ m{id="([^"]+)"}g ) {
        my $id = $1;
        return 0 if $ids{$id}++;    # Duplicate found
    }
    return 1;                       # All IDs unique
}

# Extract footnote content from dialog body
sub extract_dialog_content ( $html, $number ) {
    if ( $html =~ m{<div id="dialog-$number"[^>]*>.*?<div>(.*?)</div>}s ) {
        return $1;
    }
    return undef;
}

# Check if HTML contains noscript section
sub has_noscript_section ($html) {
    return $html =~ m{<noscript>.*?</noscript>}s;
}

# Extract all footnote numbers from HTML
sub extract_footnote_numbers ($html) {
    my @numbers;
    while ( $html =~ m{(?:open-dialog|dialog)-(\d+)}g ) {
        push @numbers, $1;
    }

    # Remove duplicates and sort
    my %seen;
    return sort { $a <=> $b } grep { !$seen{$_}++ } @numbers;
}

my $ovid = Template::Plugin::Ovid->new(undef);

# Test cite() - external links
is $ovid->cite( '/example.html', 'link name' ),
  '<a href="/example.html" target="_blank">link name</a> <span class="fa fa-external-link fa_custom"></span>',
  'We should be able to cite an external link with an external link span';

# Test link() - internal links
is $ovid->link( '/example.html', 'link name' ),
  '<a href="/example.html">link name</a>',
  'We should be able to create an internal link with no external link span';

# Test add_note() - footnotes (now includes noscript fallback - Feature 002)
my @hrefs = (
    $ovid->add_note('footnote 1'),
    $ovid->add_note('footnote 2')
);
my @expected = (
    '<span aria-label="Open Footnote" class="open-dialog js-only" id="open-dialog-1"> <i class="fa fa-clipboard fa_custom"></i> </span><noscript><a href="#footnote-1" id="footnote-1-return" aria-label="Footnote 1"><sup>[1]</sup></a></noscript>',
    '<span aria-label="Open Footnote" class="open-dialog js-only" id="open-dialog-2"> <i class="fa fa-clipboard fa_custom"></i> </span><noscript><a href="#footnote-2" id="footnote-2-return" aria-label="Footnote 2"><sup>[2]</sup></a></noscript>',
);

eq_or_diff \@hrefs, \@expected,
  'add_note() should return links for footnotes';

# Test note() - alias for add_note()
my $note_result = $ovid->note('test footnote');
like $note_result, qr/open-dialog-3/, 'note() should work as alias for add_note()';

# Test get_footnotes() and has_footnotes()
ok $ovid->has_footnotes(), 'has_footnotes() should return true when footnotes exist';
my $footnotes = $ovid->get_footnotes();
is scalar @$footnotes, 3, 'get_footnotes() should return all 3 footnotes';
ok ref($footnotes) eq 'ARRAY', 'get_footnotes() should return an array reference';

#
# Baseline Tests: Document Current add_note() Behavior (JavaScript Mode)
# These tests establish the expected behavior before adding noscript support
#

subtest 'Baseline: Current add_note() JavaScript behavior' => sub {
    my $test_ovid = Template::Plugin::Ovid->new(undef);

    # Test: add_note() returns span with open-dialog class
    my $result1 = $test_ovid->add_note('First note content');
    like $result1, qr/class="[^"]*open-dialog[^"]*"/,
      'add_note() returns span with open-dialog class';
    like $result1, qr/id="open-dialog-1"/,
      'add_note() generates correct sequential ID';

    # Test: Footnotes are stored with number and body fields
    my $stored_footnotes = $test_ovid->get_footnotes();
    is scalar @$stored_footnotes,      1, 'One footnote stored';
    is $stored_footnotes->[0]{number}, 1, 'Footnote has correct number field';
    ok exists $stored_footnotes->[0]{body}, 'Footnote has body field';
    like $stored_footnotes->[0]{body}, qr/id="dialog-1"/,
      'Footnote body contains dialog HTML with correct ID';

    # Test: Dialog body contains ARIA attributes
    like $stored_footnotes->[0]{body}, qr/role="dialog"/,
      'Dialog body has role="dialog" attribute';
    like $stored_footnotes->[0]{body}, qr/aria-labelledby="note-1"/,
      'Dialog body has aria-labelledby attribute';
    like $stored_footnotes->[0]{body}, qr/aria-describedby="note-description-1"/,
      'Dialog body has aria-describedby attribute';

    # Test: Dialog body contains the footnote content
    like $stored_footnotes->[0]{body}, qr/First note content/,
      'Dialog body contains the footnote content';

    # Test: Multiple footnotes increment correctly
    my $result2 = $test_ovid->add_note('Second note');
    like $result2, qr/id="open-dialog-2"/,
      'Second footnote has incremented ID';
    is scalar @{ $test_ovid->get_footnotes() }, 2,
      'Two footnotes stored after second add_note()';

    # Test: Helper function - extract dialog content
    my $dialog_content = extract_dialog_content( $stored_footnotes->[0]{body}, 1 );
    like $dialog_content, qr/First note content/,
      'Helper can extract content from dialog body';

    # Test: Helper function - validate unique IDs
    my $combined_html = $result1 . $stored_footnotes->[0]{body} . $result2 . $test_ovid->get_footnotes()->[1]{body};
    ok validate_unique_ids($combined_html),
      'All generated IDs are unique (no duplicates)';
};

#
# User Story 3: Prevent Overlay Interference Without JavaScript (Priority: P1)
# Tests should FAIL before implementation, PASS after
#
subtest 'US3: NoScript section in footer output' => sub {
    my $test_ovid = Template::Plugin::Ovid->new(undef);
    $test_ovid->add_note('Test footnote for noscript');

    # Test T009: noscript section should exist in footer output
    # NOTE: This tests the template rendering, but we'll mock it here
    # by checking if the plugin stores the necessary data
    my $footnotes = $test_ovid->get_footnotes();
    ok exists $footnotes->[0]{content},
      'T009: Footnote hash should have content field for noscript rendering';

    # Test T010: noscript tag should wrap footnotes section
    # This will be tested via template integration, but we can verify
    # the data structure supports it
    is $footnotes->[0]{content}, 'Test footnote for noscript',
      'T010: Content field should contain raw footnote text';

    # Test T011: dialog overlay and dialog elements should be outside noscript tag
    # This is template-level verification - we verify that dialog HTML is separate
    ok exists $footnotes->[0]{body},
      'T011: Dialog body should exist separately from noscript content';
    like $footnotes->[0]{body}, qr/<div id="dialog-1"/,
      'T011: Dialog body should contain dialog HTML structure';

    # Verify both modes can coexist
    isnt $footnotes->[0]{body}, $footnotes->[0]{content},
      'Dialog body and noscript content should be different (dual rendering)';
};

#
# User Story 1: JavaScript-Enabled Footnote Viewing (Priority: P1)
# Regression tests to ensure JavaScript mode still works correctly
#
subtest 'US1: JavaScript footnote modal behavior (regression prevention)' => sub {
    my $test_ovid = Template::Plugin::Ovid->new(undef);

    # Test T016: add_note generates span with open-dialog class
    my $result1 = $test_ovid->add_note('First JS footnote');
    like $result1, qr/<span[^>]*class="[^"]*open-dialog[^"]*"/,
      'T016: add_note() generates span with open-dialog class for JavaScript mode';
    like $result1, qr/class="[^"]*js-only[^"]*"/,
      'T016: Span should have js-only class to hide when JS disabled';

    # Test T017: add_note generates unique dialog IDs
    my $result2 = $test_ovid->add_note('Second JS footnote');
    like $result1, qr/id="open-dialog-1"/,
      'T017: First footnote has unique ID open-dialog-1';
    like $result2, qr/id="open-dialog-2"/,
      'T017: Second footnote has unique ID open-dialog-2';
    unlike $result1, qr/id="open-dialog-2"/,
      'T017: First footnote does not have second ID (uniqueness verified)';

    # Test T018: footnote body contains dialog HTML with ARIA attributes
    my $footnotes = $test_ovid->get_footnotes();
    like $footnotes->[0]{body}, qr/<div[^>]*id="dialog-1"[^>]*>/,
      'T018: Footnote body contains dialog div with unique ID';
    like $footnotes->[0]{body}, qr/role="dialog"/,
      'T018: Dialog has role="dialog" ARIA attribute';
    like $footnotes->[0]{body}, qr/aria-labelledby="note-1"/,
      'T018: Dialog has aria-labelledby attribute';
    like $footnotes->[0]{body}, qr/aria-describedby="note-description-1"/,
      'T018: Dialog has aria-describedby attribute';
    like $footnotes->[0]{body}, qr/aria-hidden="true"/,
      'T018: Dialog has aria-hidden="true" by default (prevents overlay flash)';

    # Test T019: dialog overlay rendered in footer when has_footnotes is true
    # Note: The actual template rendering is tested via integration, but we verify
    # the plugin provides the necessary data for the footer template
    ok $test_ovid->has_footnotes(),
      'T019: has_footnotes() returns true when footnotes exist';
    is scalar @$footnotes, 2,
      'T019: get_footnotes() returns all footnotes for footer rendering';

    # Verify footnote content is preserved in dialog body
    like $footnotes->[0]{body}, qr/First JS footnote/,
      'T019: Dialog body contains the footnote content';
    like $footnotes->[1]{body}, qr/Second JS footnote/,
      'T019: Second dialog body contains correct content';

    # Verify all IDs are unique (no collisions between dialog IDs and open-dialog IDs)
    my $all_html = $result1 . $result2 . $footnotes->[0]{body} . $footnotes->[1]{body};
    ok validate_unique_ids($all_html),
      'T019: All generated IDs are unique across footnotes and dialogs';
};

# Test youtube()
my $youtube_html = $ovid->youtube('dQw4w9WgXcQ');
like $youtube_html, qr{<iframe.*src="https://www\.youtube\.com/embed/dQw4w9WgXcQ"},
  'youtube() should generate proper iframe embed code';
like $youtube_html, qr{class="video-responsive"},
  'youtube() should wrap in responsive container';

# Test youtube() with invalid ID (contains slash)
throws_ok { $ovid->youtube('invalid/id') } qr/does not appear to be valid/,
  'youtube() should reject IDs containing slashes';

# Test image_type()
is $ovid->image_type('test.png'),  'image/png',  'image_type() should identify PNG';
is $ovid->image_type('test.jpg'),  'image/jpeg', 'image_type() should identify JPEG';
is $ovid->image_type('test.jpeg'), 'image/jpeg', 'image_type() should identify JPEG with .jpeg extension';
is $ovid->image_type('test.gif'),  'image/gif',  'image_type() should identify GIF';
throws_ok { $ovid->image_type('test.webp') } qr/Cannot determine image type/,
  'image_type() should croak on unknown types';

# Test describe_image() with non-existent file
throws_ok { $ovid->describe_image('root/static/images/nonexistent.png') }
qr/File does not exist or is not readable/,
  'describe_image() should croak on non-existent file';

# Test describe_image() branches - successful cases only
SKIP: {
    my $test_image = 'root/static/images/rss.png';
    skip "Test image $test_image not found", 2 unless -f $test_image;

    # Mock the imported functions in Template::Plugin::Ovid namespace
    # (they were imported at compile time, so they're local to that package)
    my $plugin_mock = Test::MockModule->new('Template::Plugin::Ovid');

    # Test branch: image path already starts with root/ AND cached description exists
    $plugin_mock->redefine( 'get_image_description' => sub { return 'cached description for root/ path' } );

    my $desc1 = $ovid->describe_image('root/static/images/rss.png');
    is $desc1, 'cached description for root/ path',
      'describe_image() should return cached description for path with root/';

    # Test branch: image path does NOT start with root/ (prepends it) AND cached description exists
    $plugin_mock->redefine( 'get_image_description' => sub { return 'cached description for relative path' } );
    my $desc2 = $ovid->describe_image('static/images/rss.png');
    is $desc2, 'cached description for relative path',
      'describe_image() should prepend root/ to relative paths and use cached description';
}

# NOTE: The branch where no cached description exists (requiring AI call) is not tested
# to avoid external API dependencies. This branch is covered by integration tests.
# See: specs/001-test-coverage-improvement/coverage-exceptions.md

done_testing;
