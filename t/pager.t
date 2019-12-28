#!/usr/bin/env perl

use Test::Most;
use lib 'lib';
use Less::Pager;

my $pager = Less::Pager->new(
    db             => 'test',
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

done_testing;
