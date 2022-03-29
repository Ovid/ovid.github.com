#!/usr/bin/env perl

use Test::Most;
use lib 'lib';
use Test2::Plugin::UTF8;
use Less::Boilerplate;
use Ovid::Template::File;

my $tt = moose_blog_example();

my $parser = Ovid::Template::File->new( filename => 'dummy', _code => $tt );
is $parser->title, 'Moose "has" a Problem', 'We should be able to read the title';
is $parser->next,        '[%', 'We should be able to fetch the first line of our code';
is $parser->line_number, 1,    '... and we should be at the correct line number';
while ( defined( $parser->next ) ) {

    #    explain $line;
}
ok !$parser->is_in_code, 'We should not be in a code state when we have read all of the lines';

$parser = Ovid::Template::File->new( filename => 'dummy', _code => code_blocks() );
ok !$parser->title, 'Our code_blocks() snippet should not have a title';
my $expected = <<'END';
[% WRAPPER include/wrapper blogdown=1 %]
<nav role="navigation" class="table-of-contents">
    <ul>
    <li class="indent-1"><a href="#this-is-a-header">This is a header</a></li>
    <li class="indent-2"><a href="#this-is-a-level-two-header">This is a level two header</a></li>
    </ul>
</nav>
<hr>

<h1><a name="this-is-a-header"></a>This is a header</h1>
<h2><a name="this-is-a-level-two-header"></a>This is a level two header</h2>

[% WRAPPER include/code.tt language='perl' -%]
my $x = shift;
# This is a comment, not a header
[% END %]

[% IF some_var %]
    <p>foo</p>
[% END %]

and

[% WRAPPER include/code.tt language='java' -%]
int someVar;
[% END %]
[% END %]
END

my $tag_map = {};
my $rewritten = $parser->rewrite('foo-bar', $tag_map);
eq_contents( $rewritten, $expected, 'Rewritten code blocks should match expections' );

$parser = Ovid::Template::File->new(
    filename => 'dummy',
    _code    => double_or_heading_bug(),
);

while ( defined ( my $line = $parser->next ) ) {
    my $is_in_code = $parser->is_in_code ? "yes" : "no";
    explain "$line is in code? $is_in_code";
}

$parser = Ovid::Template::File->new(
    filename => 'dummy',
    _code    => double_or_heading_bug(),
);
$ENV{DEBUG} = 1;
$rewritten = $parser->rewrite('foo', {});
explain $rewritten;

done_testing;

sub double_or_heading_bug {
    return <<'END';
[% WRAPPER include/wrapper.tt blogdown=1 -%]

```perl
my $x = 1;
```

```perl
# or
# or
```

[%- END %]
END
}

sub code_blocks {
    return <<'END';
[% WRAPPER include/wrapper blogdown=1 %]
{{TOC}}
# This is a header

## This is a level two header

```perl
my $x = shift;
# This is a comment, not a header
```

[% IF some_var %]
    <p>foo</p>
[% END %]

and

[% WRAPPER include/code.tt language='java' %]
int someVar;
[% END %]
[% END %]
END
}

sub moose_blog_example {
    return <<'END';
[%
    title            = 'Moose "has" a Problem';
    type             = 'blog';
    slug             = 'moose-has-a-problem';
    include_comments = 1;
    syntax_highlight = 1;
    date             = '2020-01-01';
    USE Ovid;
%]
[% WRAPPER include/wrapper.tt blogdown=1 -%]

{{TAGS programming oop}}

I'm too lazy to delete this.

[% WRAPPER include/code.tt language='perl' -%]
package Point2D {
    use Moose;
    has [qw/x y/] => (
        is       => 'ro',
        isa      => 'Num',
        required => 1,
    );
}
[% END %]

The above is a class for the canonical 2D point object that developers have a
That's a lot to pack into one function, and it leads to confusion like this:

[% WRAPPER include/code.tt language='perl' -%]
has attr => (
    is       => 'ro',            # read-only
    isa      => 'Int',           # declare it an integer
    writer   => 'set_attr',      # but it's read-only?
    required => 1,               # 'attr' must be provided
    builder  => '_build_attr',   # called if not passed in the constructor
);
[% END %]

[%- END %]
END
}

sub eq_contents ( $have, $want, $message ) {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my @have = grep { /\S/ } split /\n/ => $have;
    my @want = grep { /\S/ } split /\n/ => $want;
    eq_or_diff \@have, \@want, $message;
}
