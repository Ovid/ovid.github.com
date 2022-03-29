package Ovid::Template::Role::File {
    use Moose::Role;
    use Less::Boilerplate;
    use Ovid::Types qw(
      Maybe
      NonEmptySimpleStr
      PositiveOrZeroNum
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
}

1;

__END__

=head1 NAME

Ovid::Template::Role::File - File tools

=head1 SYNOPSIS

    package Some::Package;
    use Moose;
    with qw(Ovid::Template::Role::File);

=head1 REQUIRED METHODS

Requires no methods

=head1 PROVIDED METHODS

=head2 C<filename>

Must be passed to the constructor. Used to print filename in debug if
C<Ovid::Template::Role::Debug> is used.

=head2 C<line_number>

May be passed to the constructor. If true, will be included in C<_debug>
output if C<Ovid::Template::Role::Debug> is used.

Due to how our code base works, we will not always have a line number available.
