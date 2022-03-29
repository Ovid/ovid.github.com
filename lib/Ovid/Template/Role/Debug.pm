package Ovid::Template::Role::Debug {
    use Moose::Role;
    use Less::Boilerplate;
    use Ovid::Types qw(
      Bool
    );

    has debug => (
        is      => 'rw',
        isa     => Bool,
        default => 0,
    );

    sub _debug ( $self, $message ) {
        return unless $self->debug;
        if ( $self->DOES('Ovid::Template::Role::File') ) {
            my $filename = $self->filename;
            if ( my $line_number = $self->line_number ) {
                say STDERR "$filename/$line_number: $message";
            }
            else {
                say STDERR "$filename: $message";
            }
        }
        else {
            say STDERR $message;
        }
    }
}

1;

__END__

=head1 NAME

Ovid::Template::Role::Debug - Simple debugging tool

=head1 SYNOPSIS

    package Some::Package;
    use Moose;
    with qw(Ovid::Template::Role::Debug);

=head1 REQUIRED METHODS

Requires no methods

=head1 PROVIDED METHODS

=head2 C<_debug>

    $self->_debug($messsage);

Does nothing unless C<debug> is true.

Prints the message to C<STDERR>, preprended with filename or filename/line
number if C<Ovid::Template::Role::File> is also used.

=head2 C<debug>

May be passed to the constructor. If true, allows C<_debug> to print messages.
