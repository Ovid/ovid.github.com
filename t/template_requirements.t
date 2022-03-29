#!/usr/bin/env perl

use Test::Most;
use lib 'lib';
use Template::Code;
use Less::Boilerplate;
use File::Find::Rule;
use Test2::Plugin::UTF8;

my @files = sort File::Find::Rule->file->name( '*.tt', '*.tt2markdown' )->in( 'root/blog', 'root/articles' );

foreach my $file (@files) {
    my $parser = Template::Code->new( filename => $file );
    my $title  = $parser->title;
    ok $title, "$file has a title: $title";
}

done_testing;
