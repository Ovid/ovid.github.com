package Ovid::Template::File::FindCode {
    use Moose;
    use Less::Boilerplate;
    with qw(
      Ovid::Template::Role::Debug
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
        isa      => 'Bool',
        default  => 0,
        init_arg => undef,
    );

    foreach my $marker (qw/_start_marker _end_marker/) {
        has $marker => (
            is       => 'rw',
            writer   => "_set_is$marker",
            isa      => 'Bool',
            default  => 0,
            init_arg => undef,
        );
    }

    has language => (
        is      => 'rw',
        isa     => 'Str',
        writer  => "_set_language",
        default => '',
    );

    has _marker => (
        is      => 'rw',
        isa     => 'Str',
        writer  => "_set_marker",
        default => '',
    );

    sub is_start_marker ($self) {
        return $self->_marker ne 'END' && $self->_start_marker;
    }

    sub is_end_marker ($self) {
        return $self->_end_marker;
    }

    sub _matches_code_block_marker ($self, $line = '' ) {
        if ( $line =~ /$CODE_BLOCK_MARKER/ ) {
            if ( 'END' eq $+{marker} && !$self->_markers_match($+{marker}) ) {
                # We may have hit a code block example of TT syntax, or we hit
                # an [% END %] tag that closes a non-code block section
                return;
            }
            return ($+{marker}, $+{language} // '' );
        }
        return;
    }

    sub parse ( $self, $line = '' ) {
        $self->_set_is_start_marker(0);
        $self->_set_is_end_marker(0);
        if ( my ( $marker, $language ) = $self->_matches_code_block_marker($line) ) {
            if ( !$self->is_in_code) {
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
