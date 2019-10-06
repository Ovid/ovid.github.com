#!/usr/bin/env perl

use Test::Most;
use lib 'lib';
use Template::Plugin::Ovid;

my $ovid = Template::Plugin::Ovid->new(undef);

is $ovid->cite( '/example.html', 'link name' ),
'<a href="/example.html" target="_blank">link name</a> <span class="fa fa-external-link fa_custom"></span>',
  'We should be able to cite an external link with an external link span';

is $ovid->link( '/example.html', 'link name' ),
  '<a href="/example.html">link name</a>',
  'We should be able to create an internal link with no external link span';

my @hrefs = (
    $ovid->add_note('footnote 1'),
    $ovid->add_note( 'footnote 2', 'named footnote' )
);
my @expected = (
'<a href="#1" class="popup-btn"> <span class="fa fa-clipboard fa_custom"></span></a>
<div id="1" class="popup">
  <a href="#1-return" class="close">&times;</a>
  <p class="popup-body">footnote 1</p>
</div>
<a href="#1-return" class="close-popup"></a>
',
'<a href="#named-footnote" class="popup-btn"> <span class="fa fa-clipboard fa_custom"></span></a>
<div id="named-footnote" class="popup">
  <a href="#named-footnote-return" class="close">&times;</a>
  <p class="popup-body">footnote 2</p>
</div>
<a href="#named-footnote-return" class="close-popup"></a>
'
);

eq_or_diff \@hrefs, \@expected,
  'add_note() should return links for unnamed and named footnotes';

done_testing;
