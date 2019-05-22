#!/usr/bin/env perl

use Test::Most;
use lib 'lib';
use Template::Plugin::Ovid;

my $ovid = Template::Plugin::Ovid->new(undef);

is $ovid->cite( '/example.html', 'link name' ),
'<a href="/example.html" target="_blank">link name</a> <span class="fa fa-external-link"></span>',
  'We should be able to cite an external link with an external link span';

is $ovid->link( '/example.html', 'link name' ),
  '<a href="/example.html">link name</a>',
  'We should be able to create an internal link with no external link span';

ok !$ovid->has_footnotes, 'Our plugin should start with no footnotes';

my @hrefs = (
    $ovid->add_footnote('footnote 1'),
    $ovid->add_footnote( 'footnote 2', 'named footnote' )
);
my @expected = (
    '<sup id="1-return"><a href="#1">1</a></sup>',
    '<sup id="named-footnote-return"><a href="#named-footnote">2</a></sup>'
);

eq_or_diff \@hrefs, \@expected,
  'add_footnote() should return links for unnamed and named footnotes';
ok $ovid->has_footnotes, '... and has_footnotes() should now return true';

@expected = (
    '<p id="1"><a href="#1-return">[1]</a> footnote 1</p>',
'<p id="named-footnote"><a href="#named-footnote-return">[2]</a> footnote 2</p>'
);
eq_or_diff $ovid->get_footnotes, \@expected,
'... and get_footnotes() should return an aref the actual footnotes in HTML format.';
ok $ovid->has_footnotes, '... and has_footnotes() should still return true';

done_testing;
