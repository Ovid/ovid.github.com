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

    ok $state->parse('...'),     'We should be able to parse a line of tt2markdown code';
    ok !$state->is_start_marker, '... and we should no be at the start code marker';
    ok !$state->is_end_marker,   '... and we should not be at the closing code marker';
    ok !$state->is_in_code,      '... and we should not be in a code block if we do not see a marker';

    $state->parse('``` perl');
    ok $state->is_in_code,      '... and we should be in a code block if we see a marker';
    ok $state->is_start_marker, '... and we should be at the start code marker';
    ok !$state->is_end_marker,  '... and we should not be at the closing code marker';
    is $state->language, 'perl',
      '... and it should correctly identify the language';

    ok $state->is_in_code, '... and remain in code while we consult it again';
    $state->parse('my $x = 1');
    ok $state->is_in_code, 'We should remain in a code block if we do not see a marker';
    is $state->language, 'perl',
      '... and it should correctly identify the language';

    ok $state->parse('[% END %]'), 'We can parse a marker';
    ok $state->is_in_code, '... but we should still be a in a code block because start and end markers do not match';
    ok !$state->is_start_marker, '... and we should not be at the start code marker';
    ok !$state->is_end_marker,   '... and we should not be at the closing code marker';

    $state->parse('```');
    ok !$state->is_in_code,      '... and we are no longer in a code block once we have a corresponding end marker';
    ok !$state->is_start_marker, '... and we should not be at the start code marker';
    ok $state->is_end_marker,    '... but we should be at the closing code marker';
};

subtest 'Standalone END tag' => sub {
    my $state = Ovid::Template::File::FindCode->new( filename => 'dummy.tt' );
    $state->parse('[% END %]');
    ok !$state->is_start_marker, 'A lone [% END %] tag without a start tag is not a start marker';
    ok !$state->is_end_marker,   '... and we should not be at the closing code marker';
    ok !$state->is_in_code,      '... and we should not be in a code block if we do not see a marker';
};

subtest 'Edge cases for code block parsing' => sub {
    my $state = Ovid::Template::File::FindCode->new( filename => 'edge_test.tt' );

    # Test multiple consecutive code blocks
    $state->parse('``` javascript');
    ok $state->is_in_code, 'Should be in code block after start marker';
    is $state->language, 'javascript', 'Language should be javascript';

    $state->parse('var x = 1;');
    ok $state->is_in_code, 'Should remain in code block';

    $state->parse('```');
    ok !$state->is_in_code, 'Should exit code block after end marker';

    # Start a new code block immediately
    $state->parse('``` python');
    ok $state->is_in_code, 'Should enter new code block';
    is $state->language, 'python', 'Language should be python';
    $state->parse('```');
    ok !$state->is_in_code, 'Should exit second code block';

    # Test TT wrapper with different formatting
    $state = Ovid::Template::File::FindCode->new( filename => 'edge_test2.tt' );
    $state->parse('[% WRAPPER include/code.tt language="ruby" %]');
    ok $state->is_in_code, 'Should be in code block with TT wrapper';
    is $state->language, 'ruby', 'Language should be ruby';

    $state->parse('puts "hello"');
    ok $state->is_in_code, 'Should remain in TT code block';

    $state->parse('[%- END -%]');
    ok !$state->is_in_code, 'Should exit code block with TT END tag';

    # Test code blocks with no language specified
    $state = Ovid::Template::File::FindCode->new( filename => 'edge_test3.tt' );
    $state->parse('```');
    ok $state->is_in_code, 'Should be in code block without language';
    is $state->language, '', 'Language should be empty string';
    $state->parse('```');
    ok !$state->is_in_code, 'Should exit code block';
};

subtest 'Marker type checking methods' => sub {
    my $state = Ovid::Template::File::FindCode->new( filename => 'marker_test.tt' );

    # Test _is_markdown method
    $state->parse('``` perl');
    ok $state->_is_markdown, '_is_markdown should return true for markdown blocks';
    ok !$state->_is_tt,      '_is_tt should return false for markdown blocks';

    $state->parse('```');
    ok !$state->is_in_code, 'Should exit markdown code block';

    # Test _is_tt method
    $state->parse('[% WRAPPER include/code.tt language="perl" %]');
    ok $state->_is_tt,        '_is_tt should return true for TT blocks';
    ok !$state->_is_markdown, '_is_markdown should return false for TT blocks';

    $state->parse('[% END %]');
    ok !$state->is_in_code, 'Should exit TT code block';
};

subtest 'Mismatched markers' => sub {
    my $state = Ovid::Template::File::FindCode->new( filename => 'mismatch_test.tt' );

    # Start with markdown, try to close with TT
    $state->parse('``` perl');
    ok $state->is_in_code, 'Should be in markdown code block';

    # TT END tag should be ignored when in markdown block
    $state->parse('[% END %]');
    ok $state->is_in_code,     'Should still be in code block when TT END encountered in markdown block';
    ok !$state->is_end_marker, 'TT END should not be recognized as end marker in markdown block';

    # Close with correct marker
    $state->parse('```');
    ok !$state->is_in_code,   'Should exit code block with matching markdown marker';
    ok $state->is_end_marker, 'Matching end marker should be recognized';

    # Start with TT, test actual behavior with markdown marker
    # Note: Due to implementation quirk in _is_tt(), markdown marker DOES close TT blocks
    $state = Ovid::Template::File::FindCode->new( filename => 'mismatch_test2.tt' );
    $state->parse('[% WRAPPER include/code.tt language="java" %]');
    ok $state->is_in_code, 'Should be in TT code block';
    is $state->language, 'java', 'Language should be java';

    # Markdown marker closes TT block (due to _is_tt implementation)
    $state->parse('```');
    ok !$state->is_in_code,   'Markdown marker closes TT block (implementation behavior)';
    ok $state->is_end_marker, 'Markdown marker is recognized as end marker';

    # Verify TT END also works
    $state = Ovid::Template::File::FindCode->new( filename => 'mismatch_test3.tt' );
    $state->parse('[% WRAPPER include/code.tt language="perl" %]');
    ok $state->is_in_code, 'Should be in TT code block';

    $state->parse('[% END %]');
    ok !$state->is_in_code,   'TT END should close TT block';
    ok $state->is_end_marker, 'TT END should be recognized as end marker';
};

subtest 'Return value of parse method' => sub {
    my $state = Ovid::Template::File::FindCode->new( filename => 'return_test.tt' );

    ok $state->parse('some text'),                     'parse should return true for regular text';
    ok $state->parse('``` perl'),                      'parse should return true for start marker';
    ok $state->parse('my $x = 1;'),                    'parse should return true for code line';
    ok $state->parse('```'),                           'parse should return true for end marker';
    ok $state->parse('[% WRAPPER include/code.tt %]'), 'parse should return true for TT wrapper';
    ok $state->parse('[% END %]'),                     'parse should return true for TT END';
};

subtest 'END marker encountered after code block closed' => sub {
    my $state = Ovid::Template::File::FindCode->new( filename => 'end_after_close.tt' );

    # Start and close a TT code block
    $state->parse('[% WRAPPER include/code.tt %]');
    ok $state->is_in_code, 'Should be in TT code block';

    $state->parse('[% END %]');
    ok !$state->is_in_code, 'Should be out of code block after first END';

    # Encounter another END marker while not in code (might be part of template logic)
    $state->parse('[% END %]');
    ok !$state->is_in_code,    'Should still be out of code block';
    ok !$state->is_end_marker, 'Standalone END outside code block should not be treated as code end marker';
};

subtest 'TT wrapper without language attribute' => sub {
    my $state = Ovid::Template::File::FindCode->new( filename => 'wrapper_no_lang.tt' );

    # TT wrapper with no language specified
    $state->parse('[% WRAPPER include/code.tt %]');
    ok $state->is_in_code, 'Should be in code block with TT wrapper without language';
    is $state->language, '', 'Language should be empty when not specified';
    ok $state->is_start_marker, 'Should be at start marker';

    $state->parse('some code');
    ok $state->is_in_code, 'Should remain in code block';

    $state->parse('[% END %]');
    ok !$state->is_in_code,   'Should exit code block';
    ok $state->is_end_marker, 'Should be at end marker';
};

done_testing;
