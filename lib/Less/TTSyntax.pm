package Less::TTSyntax;

use Less::Boilerplate;
use Exporter 'import';

our @EXPORT_OK = qw(
  simplify_tt_code
  rewrite_code_blocks
);

sub simplify_tt_code($tt) {

    # obviously, more might be added later
    return rewrite_code_blocks($tt);
}

sub rewrite_code_blocks ($tt) {
    my @lines = split /\n/ => $tt;

    my $rewritten = '';
    my $in_code_block;

    my $line_number = 0;
  LINE: foreach my $line (@lines) {
      $line_number++;
        if ( $line !~ /\A ``` \s* (?<language>\w+)? \s* \Z/x ) {
            $rewritten .= "$line\n";
            next LINE;
        }

        # we have found the start or end of a code block such as: ```perl
        my $language = $+{language};
        if ( not $in_code_block ) {
            $in_code_block = $line_number;
            if ($language) {
                $rewritten .=
                  "[% WRAPPER include/code.tt language='$language' -%]\n";
            }
            else {
                $rewritten .= "[% WRAPPER include/code.tt -%]\n";
            }
        }
        else {
            $in_code_block = 0;
            $rewritten .= "[% END %]\n";
        }
    }

    if ($in_code_block) {
        croak("Got to EOF but we're still in a code block starting at line $in_code_block!");
    }
    return $rewritten;
}

1;

__END__

=head1 NAME

Less::TTSyntax - Simplify our TT syntax

=head1 SYNOPSIS

    use Less::TTSyntax qw(simplify_tt_code);
    $contents = simplify_tt_code($contents);

=head1 DESCRIPTION

This module runs in the blog preprocess phase, allowing us to use an alternate
syntax for the files, requiring less syntax. Currently it only rewrites this:

    ```$language
    some
    code
    here
    ```

To this:

    [% WRAPPER include/code.tt language='$language' -%]
    some
    code
    here
    [% END %]

The language is optional.
