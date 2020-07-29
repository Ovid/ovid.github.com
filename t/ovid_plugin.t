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
'<span aria-label="Open Footnote" class="open-dialog" id="open-dialog-1"> <i class="fa fa-clipboard fa_custom"></i> </span>',
'<span aria-label="Open Footnote" class="open-dialog" id="open-dialog-2"> <i class="fa fa-clipboard fa_custom"></i> </span>',
);

eq_or_diff \@hrefs, \@expected,
  'add_note() should return links for unnamed and named footnotes';

explain "I should fix this one day. It's currently coupled to my personal data";
my $prev_post =
  $ovid->prev_post( 'articles', 'fixing-mvc-in-web-applications' );
is $prev_post->{slug}, 'avoid-common-software-project-mistakes',
  'prev post should be correct';
my $next_post =
  $ovid->next_post( 'articles', 'fixing-mvc-in-web-applications' );
is $next_post->{slug}, 'how-to-defeat-facebook', 'next post should be correct';
ok !$ovid->next_post( 'articles', 'no-such-post' ),
  '... but we should not be able to fetch non-existing posts';

my $bug =
  $ovid->next_post( 'articles', 'fixing-mvc-in-web-applications' );
explain $bug;
$bug =
 $ovid->prev_post( 'articles', 'fixing-mvc-in-web-applications' );
 explain $bug;

done_testing;
