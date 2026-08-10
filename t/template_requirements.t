#!/usr/bin/env perl

use Test::Most;
use lib 'lib';
use Ovid::Template::File;
use Less::Boilerplate;
use File::Find::Rule;
use Test2::Plugin::UTF8;

my @files = sort File::Find::Rule->file->name( '*.tt', '*.tt2markdown' )->in( 'root/blog', 'root/articles' );

foreach my $file (@files) {
    my $parser = Ovid::Template::File->new( filename => $file );
    my $title  = $parser->title;
    my $date   = $parser->date;
    my $type   = $parser->type;
    my $slug   = $parser->slug;
    subtest "Attributes for $file" => sub {
        ok $title, "$file has a title: « $title »";
        ok $date,  "... and a date: $date";
        ok $slug,  "... and a slug: $slug";
        ok $type,  "... and a type: $type";
        like $file, qr{^root/$type}, '... and the type should match the beginning of the path';

        # Every article must go through include/wrapper.tt, because that is
        # what supplies <article id="article">. 18 legacy articles included
        # include/header.tt directly and so got no such element: footer.tt's
        # readingTime() does getElementById("article").innerText and threw a
        # TypeError on every one of them, leaving the opener reading " min
        # read" with no number, and Site::_html_to_text extracts body text
        # from that element, so all 18 contributed nothing to the search
        # index.
        like $parser->_code, qr{WRAPPER\s+include/wrapper},
          '... and it should be built on include/wrapper.tt';
    };
}

done_testing;
