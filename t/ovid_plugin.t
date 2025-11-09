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

# Test tag-related methods
my @tags = $ovid->tags();
ok scalar(@tags) > 0, 'tags() should return a list of tags';
ok( ( grep { $_ ne '__ALL__' } @tags ) == scalar(@tags),
    'tags() should filter out __ALL__'
);

# Test tags_by_weight()
my @weighted_tags = $ovid->tags_by_weight();
ok scalar(@weighted_tags) > 0, 'tags_by_weight() should return tags';
is_deeply [ sort @weighted_tags ], [ sort @tags ],
  'tags_by_weight() should return same tags as tags()';

# Test has_articles_for_tag()
my $first_tag = $tags[0];
ok $ovid->has_articles_for_tag($first_tag),
  "has_articles_for_tag() should return true for valid tag '$first_tag'";

# Test name_for_tag()
my $tag_name = $ovid->name_for_tag($first_tag);
ok $tag_name, "name_for_tag() should return name for tag '$first_tag'";

# Test name_for_tag() error branch - unknown tag
throws_ok { $ovid->name_for_tag('nonexistent_tag_12345') }
qr/Cannot find name for unknown tag/,
  'name_for_tag() should croak for unknown tag';

# Test count_for_tag()
my $count = $ovid->count_for_tag($first_tag);
ok $count > 0, "count_for_tag() should return positive count for tag '$first_tag'";

# Test count_for_tag() error branch - unknown tag
throws_ok { $ovid->count_for_tag('nonexistent_tag_12345') }
qr/Cannot find count for unknown tag/,
  'count_for_tag() should croak for unknown tag';

# Test weight_for_tag()
my $weight = $ovid->weight_for_tag($first_tag);
ok $weight >= 1 && $weight <= 9, "weight_for_tag() should return weight between 1-9";

# Test weight_for_tag() caching branch - call it again for same tag
my $weight2 = $ovid->weight_for_tag($first_tag);
is $weight2, $weight, 'weight_for_tag() should return cached weight on second call';

# Test tags_for_url()
my $files_collection = $ovid->files_for_tag($first_tag);
ok ref($files_collection) eq 'Ovid::Template::File::Collection',
  'files_for_tag() should return Collection object';

# Test files_for_tag() error branch - unknown tag
throws_ok { $ovid->files_for_tag('nonexistent_tag_12345') }
qr/Cannot find files for unknown tag/,
  'files_for_tag() should croak for unknown tag';

# Get first file URL from tagmap directly for testing title_for_tag_file
my $tagmap_first_file = $ovid->{tagmap}{$first_tag}{files}[0];
if ($tagmap_first_file) {
    my $url_tags = $ovid->tags_for_url($tagmap_first_file);
    ok ref($url_tags) eq 'ARRAY', 'tags_for_url() should return array reference';

    # Test title_for_tag_file() - use the actual file URL from tagmap
    my $title = eval { $ovid->title_for_tag_file( $first_tag, $tagmap_first_file ) };
    ok $title, "title_for_tag_file() should return title for valid tag '$first_tag' and file"
      or diag "Error: $@";
}

# Test title_for_tag_file() error branch - unknown tag
throws_ok { $ovid->title_for_tag_file( 'nonexistent_tag_12345', 'some_file.html' ) }
qr/Cannot find title for unknown tag/,
  'title_for_tag_file() should croak for unknown tag';

# Test tags_for_url() branch - URL not found (returns [])
my $empty_tags = $ovid->tags_for_url('/nonexistent/url.html');
is_deeply $empty_tags, [], 'tags_for_url() should return empty arrayref for unknown URL';

# Test is_blog()
ok $ovid->is_blog('blog'),      'is_blog() should return true for "blog"';
ok !$ovid->is_blog('articles'), 'is_blog() should return false for "articles"';

# Test this_post()
my $this_post = $ovid->this_post( 'articles', 'fixing-mvc-in-web-applications' );
is $this_post->{slug}, 'fixing-mvc-in-web-applications', 'this_post() should return current post';

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

explain "I should fix this one day. It's currently coupled to my personal data";
my $prev_post = $ovid->prev_post( 'articles', 'fixing-mvc-in-web-applications' );
is $prev_post->{slug}, 'avoid-common-software-project-mistakes',
  'prev post should be correct';
my $next_post = $ovid->next_post( 'articles', 'fixing-mvc-in-web-applications' );
is $next_post->{slug}, 'how-to-defeat-facebook', 'next post should be correct';
ok !$ovid->next_post( 'articles', 'no-such-post' ),
  '... but we should not be able to fetch non-existing posts';

my $bug = $ovid->next_post( 'articles', 'fixing-mvc-in-web-applications' );
explain $bug;
$bug = $ovid->prev_post( 'articles', 'fixing-mvc-in-web-applications' );
explain $bug;

done_testing;
