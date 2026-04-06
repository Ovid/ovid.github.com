package Ovid::Template::File::FindCode {
    use Moose;
    use Less::Boilerplate;
    use Ovid::Types qw(
      Bool
      EmptyStr
      NonEmptySimpleStr
    );
    with qw(
      Ovid::Template::Role::Debug
      Ovid::Template::Role::File
    );

    # parameters

    my $CODE_BLOCK_MARKER = qr{^
        (?:
            (?<marker>```)                                 # markdown code block start/end
            \s*
            (?<language>\w+)?                              # optional langugage
            \s*
        |
            \s*
            \[%-?                                          # tt2 code block start
            \s+
            (?<marker>WRAPPER) 
            \s+
            include/code.tt
            \s+
            (?:language\s*=\s*['"](?<language>\w+)['"]\s+)? # optional language
            -?%\]
        |
            \s*
            \[%-?                                          # tt2 code block end
            \s*
            (?<marker>END) 
            \s*
            -?%\]
        )
        \s*
    $}x;

    has is_in_code => (
        is       => 'rw',
        writer   => '_set_is_in_code',
        isa      => Bool,
        default  => 0,
        init_arg => undef,
    );

    foreach my $marker (qw/_start_marker _end_marker/) {
        has $marker => (
            is       => 'rw',
            writer   => "_set_is$marker",
            isa      => Bool,
            default  => 0,
            init_arg => undef,
        );
    }

    has language => (
        is      => 'rw',
        isa     => NonEmptySimpleStr | EmptyStr,
        writer  => "_set_language",
        default => '',
    );

    has _marker => (
        is      => 'rw',
        isa     => NonEmptySimpleStr | EmptyStr,
        writer  => "_set_marker",
        default => '',
    );

    sub is_start_marker ($self) {
        return $self->_marker ne 'END' && $self->_start_marker;
    }

    # TODO (Coverage Improvement 001): Review usage and add tests
    # Used internally for code block parsing. Ensure edge cases are tested.
    # See: specs/001-test-coverage-improvement/unused-code-decisions.md
    sub is_end_marker ($self) {
        return $self->_end_marker;
    }

    sub _matches_code_block_marker ( $self, $line = '' ) {
        if ( $line =~ /$CODE_BLOCK_MARKER/ ) {
            if ( 'END' eq $+{marker} && !$self->_markers_match( $+{marker} ) ) {

                # We may have hit a code block example of TT syntax, or we hit
                # an [% END %] tag that closes a non-code block section
                return;
            }
            return ( ( $+{marker} // '' ), ( $+{language} // '' ) );
        }
        return;
    }

    # TODO (Coverage Improvement 001): Verify this is main entry point and add tests
    # May be called from external code or templates. Check for usage patterns.
    # See: specs/001-test-coverage-improvement/unused-code-decisions.md
    sub parse ( $self, $line = '' ) {
        $self->_set_is_start_marker(0);
        $self->_set_is_end_marker(0);
        if ( my ( $marker, $language ) = $self->_matches_code_block_marker($line) ) {
            if ( !$self->is_in_code ) {
                if ( 'END' ne $marker ) {
                    $self->_debug("Starting code block: $line");
                    $self->_set_is_start_marker(1);
                    $self->_set_is_in_code(1);
                    $self->_set_language($language);
                    $self->_set_marker($marker);
                }
            }
            elsif ( $self->_markers_match($marker) ) {
                $self->_debug("Ending code block: $line");
                $self->_set_is_end_marker(1);
                $self->_set_is_in_code(0);
                $self->_set_marker($marker);
            }
        }
        return 1;
    }

    sub _markers_match ( $self, $marker ) {

        # call this before setting the new marker!
        return ( $self->_is_markdown && $self->_is_markdown($marker) || $self->_is_tt && $self->_is_tt($marker) );
    }

    sub _is_markdown ( $self, $marker = $self->_marker ) {
        return $self->is_in_code && $marker eq '```';
    }

    sub _is_tt ( $self, $marker = $self->_marker ) {
        return $self->is_in_code && $self->_marker eq 'WRAPPER';
    }

    __PACKAGE__->meta->make_immutable;
}

__END__

=head1 NAME

Ovid::Template::File::FindCode - Detect and track code block boundaries in template files

=head1 SYNOPSIS

    use Ovid::Template::File::FindCode;

    my $finder = Ovid::Template::File::FindCode->new;

    for my $line (@lines) {
        $finder->parse($line);

        if ( $finder->is_in_code ) {
            # Currently inside a code block
            my $lang = $finder->language;  # e.g. 'perl', 'python', ''
        }

        if ( $finder->is_start_marker ) {
            # This line opens a new code block
        }

        if ( $finder->is_end_marker ) {
            # This line closes the current code block
        }
    }

=head1 DESCRIPTION

Ovid::Template::File::FindCode is a stateful parser that tracks whether the
current line of a template file is inside a code block. It recognizes two
styles of code block markers:

=over 4

=item Markdown triple-backtick fences

    ```perl
    my $code = 1;
    ```

=item Template Toolkit WRAPPER directives

    [% WRAPPER include/code.tt language="perl" %]
    my $code = 1;
    [% END %]

=back

The parser correctly matches opening and closing markers, ensuring that a
Markdown fence is only closed by another Markdown fence and a TT WRAPPER
block is only closed by its corresponding C<[% END %]>.

This module consumes the L<Ovid::Template::Role::Debug> and
L<Ovid::Template::Role::File> roles.

=head1 METHODS

=head2 parse

    $finder->parse($line);

Parses a single line of template content and updates the internal state.
Call this method once per line, in order. Returns true.

After calling C<parse>, you can query the state with C<is_in_code>,
C<is_start_marker>, C<is_end_marker>, and C<language>.

=head2 is_in_code

    if ( $finder->is_in_code ) { ... }

Returns true if the parser is currently inside a code block (i.e., between
an opening and closing marker).

=head2 is_start_marker

    if ( $finder->is_start_marker ) { ... }

Returns true if the most recently parsed line was a code block opening marker.

=head2 is_end_marker

    if ( $finder->is_end_marker ) { ... }

Returns true if the most recently parsed line was a code block closing marker.

=head2 language

    my $lang = $finder->language;

Returns the language identifier from the most recent code block opening
marker (e.g., C<'perl'>, C<'python'>). Returns an empty string if no
language was specified.

=cut
