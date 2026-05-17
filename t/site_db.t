#!/usr/bin/env perl

use Test::Most;
use lib 'lib';
use lib 't/lib';
use Less::Boilerplate;
use Test2::Plugin::UTF8;
use DBI;
use Ovid::Site;

subtest 'Ovid::Site accepts an injected dbh attribute' => sub {
    my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', { RaiseError => 1 });
    my $site = Ovid::Site->new( dbh => $dbh );
    is $site->dbh, $dbh, 'dbh accessor returns the injected handle';
};

done_testing;
