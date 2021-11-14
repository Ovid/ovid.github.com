#!/usr/bin/env perl

use Test::Most;
use Less::TTSyntax qw(rewrite_code_blocks);

my $markdown = <<'END';
[% WRAPPER include/wrapper.tt blogdown=1 -%]

Before

```perl
my $foo = bar;
$foo++;
```

Whee!

[%- END %]
END

my $expected = <<'END';
[% WRAPPER include/wrapper.tt blogdown=1 -%]

Before

[% WRAPPER include/code.tt language='perl' -%]
my $foo = bar;
$foo++;
[% END %]

Whee!

[%- END %]
END

is rewrite_code_blocks($markdown), $expected, 'We should be able to rewrite our code blocks';
done_testing;
