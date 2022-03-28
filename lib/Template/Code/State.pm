package Template::Code::State {
    use Moose;
    use Less::Boilerplate;

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
            (?:<marker>WRAPPER) 
            \s+
            include/code.tt
            \s+
            (?:language\s*=\s*['"](?<lanuage>\w+)['"]\s+)? # optional language
            -?%\]
        |
            \s*
            \[%-?                                          # tt2 code block end
            \s+
            (?:<marker>END) 
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

    sub parse ( $self, $line = '' ) {
        if ( $line =~ /$CODE_BLOCK_MARKER/ ) {
            my $language = $+{language} // '';
            my $marker   = $+{marker}   // '';

            # if we're in a code block, only switch state if start marker type
            # matches new marker type
            # otherwise, we're not in code and it's safe to start
            if ((   $self->is_in_code && ( $self->_is_markdown && $self->_is_markdown($marker)
                        || $self->_is_tt && $self->_is_tt($marker) )
                )
                || !$self->is_in_code
              )
            {
                $self->_set_is_in_code( $self->is_in_code ? 0 : 1 );
                $self->_set_language($language);
                $self->_set_marker($marker);
            }
        }
        return 1;
    }

    sub _is_markdown ( $self, $marker = $self->_marker ) {
        return $self->is_in_code && $marker eq '```';
    }

    sub _is_tt ( $self, $marker = $self->_marker ) {
        return $self->is_in_code && $self->_marker eq 'WRAPPER';
    }

    __PACKAGE__->meta->make_immutable;
}
