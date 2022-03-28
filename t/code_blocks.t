#!/usr/bin/env perl

use Test::Most;
use lib 'lib';
use Test2::Plugin::UTF8;
use Less::Boilerplate;
use Template::Code::State;

my $state = Template::Code::State->new;
ok $state->parse('...'), 'We should be able to parse a line of tt2markdown code';
ok !$state->is_in_code, '... and we should not be in a code block if we do not see a marker';

$state->parse('``` perl');
ok $state->is_in_code, '... and we should be in a code block if we see a marker';
is $state->language,   'perl',
  '... and it should correctly identify the language';

ok $state->is_in_code, '... and remain in code while we consult it again';
$state->parse('my $x = 1');
ok $state->is_in_code, 'We should remain in a code block if we do not see a marker';
is $state->language,   'perl',
  '... and it should correctly identify the language';

ok $state->parse('[% END %]'), 'We can parse a marker';
ok $state->is_in_code, '... but we should still be a in a code block because start and end markers do not match';

$DB::single = 1;
$state->parse('```');
ok !$state->is_in_code, '... and we are no longer in a code block once we have a corresponding end marker';

done_testing;
