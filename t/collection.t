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
    ok my $coll = Collection->new( files => $files ),
      'We should be able to create a collection of HTML files';
    my @files = map {
        my $file = $_;
        +{ map { $_ => $file->$_ } qw/date filename references/ }
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
    eq_or_diff \@files, \@expected,
      '... and they should be returned as objects pointing to templates, in decending date order';
};

# Test iteration edge case: calling next() beyond collection bounds
# Covers line 51: if $i - 1 > $self->count (T branch)
subtest 'iteration boundary conditions' => sub {
    my $coll = Collection->new( files => [qw/foo bar/], raw => 1 );
    is $coll->next, 'foo', 'First item should be foo';
    is $coll->next, 'bar', 'Second item should be bar';
    ok !defined $coll->next, 'Third call should return undef (past end)';
    ok !defined $coll->next, 'Fourth call should also return undef';
    ok !defined $coll->next, 'Fifth call triggers early return (i - 1 > count)';
};

# Test file path handling for non-.html files
# Covers line 67-68: elsif (not -e $file) branches
subtest 'file path handling edge cases' => sub {
    # Test with actual template files that exist (non-.html paths)
    # This triggers the elsif F branch (file exists, not .html)
    my $coll = Collection->new(
        files => ['root/blog/life-on-venus.tt']
    );
    is $coll->count, 1, 'Should accept non-.html file paths that exist';
    
    # Test error handling for missing non-.html file
    # This triggers the elsif T branch (file doesn't exist, not .html)
    throws_ok {
        Collection->new( files => ['nonexistent/file.txt'] )
    }
    qr/Cannot find file/, 'Should croak when non-.html file does not exist';
};

# Test error handling for missing template files
# Covers line 71: unless (-e $file) branch (T branch - missing .tt2markdown)
subtest 'missing template file error handling' => sub {
    # This tests the case where .html file maps to missing .tt and .tt2markdown
    throws_ok {
        Collection->new( files => ['blog/nonexistent-article-xyz.html'] )
    }
    qr/Cannot find template file/, 
      'Should croak when neither .tt nor .tt2markdown exists for .html file';
};

done_testing;

__END__
$files = [
  'blog/jeff-bezos-1000-problems.html',
  'blog/life-on-venus.html',
  'blog/time-to-invest-in-space.html'
];
