#!/usr/bin/env perl

use Test::Most;
use lib 'lib';
use Less::Pager;

my $pager =
  Less::Pager->new( db => 'test', items_per_page => 2, oldest_first => 1 );
cmp_ok $pager->total, '>', 0, 'We should have records in our database';
is $pager->current_page_number, 0, '... and we should not yet have a page';
my $found = 0;

my $current_page_number = 1;
while ( my $records = $pager->next ) {
    is $pager->current_page_number, $current_page_number,
      '... fetching records should increment our page number';
    $current_page_number++;
    $found += $records->@*;
}
is $found, $pager->total,
  'We should be able to fetch the correct number of records';

done_testing;
