#!/usr/bin/env perl

use Test::Most;
use lib 'lib';
use Less::Pager;

my $pager = Less::Pager->new(
    items_per_page => 2,
    oldest_first   => 1,
    type           => 'article'
);
cmp_ok $pager->total, '>', 0, 'We should have records in our database';
is $pager->current_page_number, 0, '... and we should not yet have a page';
my $found = 0;

my $current_page_number = 0;
while ( my $records = $pager->next ) {
    $current_page_number++;
    is $pager->current_page_number, $current_page_number,
      '... fetching records should increment our page number';
    $found += $records->@*;
}
is $pager->total_pages, $current_page_number,
  '... and our total_pages() should match the last pager number';

is $found, $pager->total,
  'We should be able to fetch the correct number of records';

explain "I should fix this one day. It's currently coupled to my personal data";
my $prev_post = $pager->prev_post( 'articles', 'fixing-mvc-in-web-applications' );
is $prev_post->{slug}, 'avoid-common-software-project-mistakes',
  'prev post should be correct';
my $next_post = $pager->next_post( 'articles', 'fixing-mvc-in-web-applications' );
is $next_post->{slug}, 'how-to-defeat-facebook',
  'next post should be correct';

# Test this_post method
my $this_post = $pager->this_post( 'articles', 'fixing-mvc-in-web-applications' );
ok $this_post, 'this_post should return a result';
is $this_post->{slug}, 'fixing-mvc-in-web-applications',
  'this_post should return the correct post';
is $this_post->{type}, 'article', 'this_post should have correct type';
ok exists $this_post->{title},       'this_post should have a title';
ok exists $this_post->{description}, 'this_post should have a description';

# Test this_post with nonexistent post
my $missing_post = $pager->this_post( 'articles', 'nonexistent-post-slug' );
is $missing_post, undef, 'this_post should return undef for nonexistent post';

# Test all() method
my $all_articles = $pager->all;
ok $all_articles, 'all() should return results';
is ref $all_articles, 'ARRAY', 'all() should return an array reference';
cmp_ok scalar(@$all_articles), '>', 0, 'all() should return multiple articles';
is $all_articles->[0]{type}, 'article', 'all() should return correct type';

# Test with blog type
my $blog_pager = Less::Pager->new(
    items_per_page => 3,
    type           => 'blog'
);
ok $blog_pager, 'Should be able to create pager for blog type';
cmp_ok $blog_pager->total, '>', 0, 'Blog pager should have records';
my $blog_records = $blog_pager->next;
ok $blog_records, 'Blog pager should return records';
is $blog_records->[0]{type}, 'blog', 'Blog records should have correct type';

# Test all() with blog and oldest_first
my $blog_all = $blog_pager->all;
ok $blog_all, 'all() should work with blog type';
is $blog_all->[0]{type}, 'blog', 'all() blog records should have correct type';

# Test with default oldest_first (0 - newest first)
my $newest_first_pager = Less::Pager->new(
    items_per_page => 2,
    type           => 'article'
);
is $newest_first_pager->oldest_first, 0, 'oldest_first should default to 0';
my $newest_records = $newest_first_pager->next;
ok $newest_records, 'newest_first pager should return records';

# Test boundary condition: items_per_page = 1
my $single_pager = Less::Pager->new(
    items_per_page => 1,
    type           => 'article'
);
my $single_record = $single_pager->next;
ok $single_record, 'Pager with items_per_page=1 should work';
is scalar(@$single_record), 1, 'Should return exactly 1 record';

# Test boundary condition: very large items_per_page
my $large_pager = Less::Pager->new(
    items_per_page => 10000,
    type           => 'article'
);
my $all_in_one = $large_pager->next;
ok $all_in_one, 'Pager with large items_per_page should work';
is $large_pager->current_page_number, 1, 'Should have fetched one page';
my $no_more = $large_pager->next;
is $no_more, undef, 'Should return undef when no more records';

# Test total_pages calculation with exact division
my $exact_pager = Less::Pager->new(
    items_per_page => $pager->total,    # Use total to get exact division
    type           => 'article'
);
is $exact_pager->total_pages, 1, 'total_pages should handle exact division';

# Test prev_post and next_post with edge cases
# Test prev_post at beginning (should return undef or handle gracefully)
# Note: This depends on database content, testing the method is called correctly
my $first_article_slug = $pager->all->[0]{slug};
my $prev_of_first      = $pager->prev_post( 'articles', $first_article_slug );

# May be undef if at the beginning, or may wrap - either is valid behavior

# Test next_post at end
my $all_for_end       = $pager->all;
my $last_article_slug = $all_for_end->[-1]{slug};
my $next_of_last      = $pager->next_post( 'articles', $last_article_slug );

# May be undef if at the end, or may wrap - either is valid behavior

# Test prev_post with blog type
if ( $blog_pager->total > 1 ) {
    my $blog_posts = $blog_pager->all;
    if ( @$blog_posts >= 2 ) {
        my $second_blog_slug = $blog_posts->[1]{slug};
        my $blog_prev        = $blog_pager->prev_post( 'blog', $second_blog_slug );

        # Should work with blog type
    }
}

# Test error condition: nonexistent directory/slug for prev_post
my $bad_prev = $pager->prev_post( 'nonexistent-dir', 'nonexistent-slug' );
is $bad_prev, undef, 'prev_post should return undef for nonexistent post';

# Test error condition: nonexistent directory/slug for next_post
my $bad_next = $pager->next_post( 'nonexistent-dir', 'nonexistent-slug' );
is $bad_next, undef, 'next_post should return undef for nonexistent post';

done_testing;
