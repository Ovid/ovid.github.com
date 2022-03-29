#!/usr/bin/env perl

use Test::Most;
use lib 'lib';
use Test2::Plugin::UTF8;
use Less::Boilerplate;
use Ovid::Template::File::FindCode;

subtest 'code block markers match' => sub {

    # unit testing some internals
    my %bad = (
        '...'            => 'not a clode block',
        '[% ENDWHILE %]' => 'not a clode block',
        ' ```'           => 'leading space will prevent matching',
    );
    foreach my $line ( sort keys %bad ) {
        my $state   = Ovid::Template::File::FindCode->new( filename => 'dummy.tt' );
        my $message = $bad{$line};
        my ( $marker, $language ) = $state->_matches_code_block_marker($line);
        ok !$marker, "no match for <$line>: $message";
    }
    my %good_start = (
        '```'                                           => 'bare markdown',
        '``` java'                                      => 'markdown with language',
        '[% WRAPPER include/code.tt language="perl" %]' => 'start tt',
    );
    foreach my $line ( sort keys %good_start ) {
        my $state   = Ovid::Template::File::FindCode->new( filename => 'dummy.tt' );
        my $message = $good_start{$line};
        my ( $marker, $language ) = $state->_matches_code_block_marker($line);
        ok $marker, "match for <$line>: $message";
    }
    my %good_end = (
        '[% END %]'       => 'end tt',
        '[%-   END   -%]' => 'end tt',
    );
    foreach my $line ( sort keys %good_end ) {
        my $state = Ovid::Template::File::FindCode->new( filename => 'dummy.tt' );

        explain "We have to have a valid start tag or TT end tags won't match";
        $state->parse('[% WRAPPER include/code.tt language="perl" %]');
        my $message = $good_end{$line};
        my ( $marker, $language ) = $state->_matches_code_block_marker($line);
        ok $marker, "match for <$line>: $message";
    }
};

subtest 'Basic code block parsing' => sub {
    my $state = Ovid::Template::File::FindCode->new( filename => 'dummy.tt' );

    ok $state->parse('...'), 'We should be able to parse a line of tt2markdown code';
    ok !$state->is_start_marker, '... and we should no be at the start code marker';
    ok !$state->is_end_marker,   '... and we should not be at the closing code marker';
    ok !$state->is_in_code,      '... and we should not be in a code block if we do not see a marker';

    $state->parse('``` perl');
    ok $state->is_in_code,      '... and we should be in a code block if we see a marker';
    ok $state->is_start_marker, '... and we should be at the start code marker';
    ok !$state->is_end_marker, '... and we should not be at the closing code marker';
    is $state->language, 'perl',
      '... and it should correctly identify the language';

    ok $state->is_in_code, '... and remain in code while we consult it again';
    $state->parse('my $x = 1');
    ok $state->is_in_code, 'We should remain in a code block if we do not see a marker';
    is $state->language,   'perl',
      '... and it should correctly identify the language';

    ok $state->parse('[% END %]'), 'We can parse a marker';
    ok $state->is_in_code, '... but we should still be a in a code block because start and end markers do not match';
    ok !$state->is_start_marker, '... and we should not be at the start code marker';
    ok !$state->is_end_marker,   '... and we should not be at the closing code marker';

    $state->parse('```');
    ok !$state->is_in_code,      '... and we are no longer in a code block once we have a corresponding end marker';
    ok !$state->is_start_marker, '... and we should not be at the start code marker';
    ok $state->is_end_marker, '... but we should be at the closing code marker';
};

subtest 'Standalone END tag' => sub {
    my $state = Ovid::Template::File::FindCode->new( filename => 'dummy.tt' );
    $state->parse('[% END %]');
    ok !$state->is_start_marker, 'A lone [% END %] tag without a start tag is not a start marker';
    ok !$state->is_end_marker,   '... and we should not be at the closing code marker';
    ok !$state->is_in_code,      '... and we should not be in a code block if we do not see a marker';
};

done_testing;
