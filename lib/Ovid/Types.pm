package Ovid::Types {
    use Less::Boilerplate;
    use Type::Library
      -base,
      -declare => qw(
      EmptyStr
    );
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
    declare EmptyStr,
      as Str,
      where { defined && $_ eq '' };
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

The following functions may be exported on demand:

=over 4

=item * C<compile>

=item * C<compile_named>

=back

=head1 Custom Types

The following custom types are exported:

=over 4

=item * C<EmptyStr>

Must be an empty string.

=back
