package Ovid::Template::Role::Debug {
    use Moose::Role;
    use Less::Boilerplate;
    use Ovid::Types qw(
      Bool
      Maybe
      NonEmptySimpleStr
      PositiveOrZeroNum
    );

    has debug => (
        is      => 'rw',
        isa     => Bool,
        default => 0,
    );

    has filename => (
        is       => 'rw',
        isa      => NonEmptySimpleStr,
        required => 1,
    );

    has line_number => (
        is      => 'rw',
        isa     => Maybe [PositiveOrZeroNum],
        writer  => '_set_line_number',
        default => 0,
    );

    sub _debug ( $self, $message ) {
        return unless $self->debug;
        my $filename = $self->filename;
        if ( my $line_number = $self->line_number ) {
            say STDERR "$filename/$line_number: $message";
        }
        else {
            say STDERR "$filename: $message";
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

Prints the message to C<STDERR>, prepredended with filename or filename/line number.

=head2 C<debug>

May be passed to the constructor. If true, allows C<_debug> to print messages.

=head2 C<filename>

Must be passed to the constructor. Used to print filename in debug.

=head2 C<line_number>

May be passed to the constructor. If true, will be included in C<_debug> output.

Due to how our code base works, we will not always have a line number available.
