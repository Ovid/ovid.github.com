#!/usr/bin/env perl

use Test::Most;
use lib 'lib';
use Less::Script;

ok my $dbh    = dbh, 'I should be able to fetch my database handle';
ok my $tables = $dbh->selectcol_arrayref("SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name;"),
  '... and we should be able to fetch our tables';
eq_or_diff $tables, [ 'article_types', 'articles', 'images', 'sqlite_sequence' ],
  '... and they should be the tables we expect';

my $type = article_type('blog');
eq_or_diff $type, { name => 'Blog Entries', type => 'blog', directory => 'blog', },
  'article_type($type) should return a hashref of type information';

done_testing;
