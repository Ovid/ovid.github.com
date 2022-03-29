package Ovid::Types {
    use Less::Boilerplate;
    use Type::Library -base;
    use Type::Utils -all;
    use Type::Params;
    our @EXPORT_OK;

    BEGIN {
      extends qw(
        Types::Standard
        Types::Common::Numeric
        Types::Common::String
      );
      push @EXPORT_OK => qw/compile compile_named/;
    }
}

1;

__END__

=head1 NAME

Ovid::Types - Basic Types

=head1 Types

All of the following types may be exported on demand:

=over 4

=item * C<Types::Standard>

=item * C<Types::Common::String>

=item * C<Types::Common::Numeric>

=back

Additionaly, the following functions may be exported on demand:

=over 4

=item * C<compile>

=item * C<compile_named>

=back
