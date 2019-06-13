#!/usr/bin/env perl

use Test::Most;
use lib 'lib';
use Less::Script;

ok my $dbh = dbh('test'), 'I should be able to fetch my test database handle';
ok my $tables =
  $dbh->selectcol_arrayref('SELECT name FROM sqlite_master ORDER BY name;'),
  '... and we should be able to fetch our tables';
eq_or_diff $tables, ['articles'], '... and they should be the tables we expect';
ok my $prod = dbh('prod'),
  '... and we should also be able to fetch our prod database';
throws_ok { dbh('wtf') }
qr/Could not find database handle for 'wtf'/,
  '... but attempting to fetch an unknown database handle should fail';

done_testing;
