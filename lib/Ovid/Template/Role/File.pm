package Ovid::Template::Role::File {
    use Moose::Role;
    use Less::Boilerplate;
    use Ovid::Types qw(
      Maybe
      NonEmptySimpleStr
      PositiveOrZeroInt
    );

    has filename => (
        is       => 'rw',
        isa      => NonEmptySimpleStr,
        required => 1,
    );

    has references => (
        is       => 'ro',
        isa      => Maybe [NonEmptySimpleStr],
        required => 0,
    );

    has line_number => (
        is      => 'rw',
        isa     => Maybe [PositiveOrZeroInt],
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

=head2 C<references>

May be passed to the contructor. Some files might reference a different file
(an HTML file might reference a tempplate and vice versa).
