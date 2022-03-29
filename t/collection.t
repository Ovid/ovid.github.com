#!/usr/bin/env perl

use Test::Most;
use lib 'lib';
use Test2::Plugin::UTF8;
use Less::Boilerplate;
use aliased 'Ovid::Template::File::Collection';

subtest 'iterating' => sub {
    my $coll = Collection->new( files => [qw/foo bar baz/], raw => 1 );
    is $coll->count, 3,     'We should have three files in our collection';
    is $coll->next,  'foo', '... and the first item should be correct';
    is $coll->next,  'bar', '... and the second item should be correct';
    is $coll->next,  'baz', '... and the third item should be correct';
    ok !defined $coll->next, '... and we should have no more items';
    $coll->reset;
    is $coll->count, 3,     'We should have three files in our collection';
    is $coll->next,  'foo', '... and the first item should be correct';
    is $coll->next,  'bar', '... and the second item should be correct';
    is $coll->next,  'baz', '... and the third item should be correct';
    ok !defined $coll->next, '... and we should have no more items';
};

# yeah, this is a bit sloppy
#
subtest 'iterating over html docs' => sub {
    my $files = [
        'blog/jeff-bezos-1000-problems.html',
        'blog/life-on-venus.html',
        'blog/time-to-invest-in-space.html'
    ];
    ok my $coll     = Collection->new( files => $files ),
        'We should be able to create a collection of HTML files';
    my @files = map {
        my $file = $_;
        +{
            map { $_ => $file->$_ } qw/date filename references/
        }
    } $coll->all;
    my @expected = (
        {
            date       => "2022-03-08",
            filename   => "root/blog/time-to-invest-in-space.tt2markdown",
            references => "blog/time-to-invest-in-space.html",
        },
        {
            date       => "2021-10-01",
            filename   => "root/blog/jeff-bezos-1000-problems.tt",
            references => "blog/jeff-bezos-1000-problems.html",
        },
        {
            date       => "2020-09-15",
            filename   => "root/blog/life-on-venus.tt",
            references => "blog/life-on-venus.html",
        }
    );
	eq_or_diff \@files, \@expected, '... and they should be returned as objects pointing to templates, in decending date order';
};

done_testing;

__END__
$files = [
  'blog/jeff-bezos-1000-problems.html',
  'blog/life-on-venus.html',
  'blog/time-to-invest-in-space.html'
];
