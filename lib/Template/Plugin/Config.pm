package Template::Plugin::Config;
use Less::Boilerplate;
use Less::Config qw(config);
use base qw (Template::Plugin);

our $VERSION = 0.02;

sub new ( $class, $context ) {
    bless {
        _CONTEXT    => $context,
        ovid_config => config(),
    }, $class;
}

sub AUTOLOAD ($self) {
    our $AUTOLOAD;    # keep 'use strict' happy
    my $var = $AUTOLOAD;
    $var =~ s/.*:://;
    my $config = $self->{ovid_config};
    if ( exists $config->{$var} ) {
        return $config->{$var};
    }
    croak("No such config entry '$var'");
}

1;

__END__

=head1 NAME

Template::Plugin::Config - TT plugin for Config ddata

=head1 SYNOPSIS

  [% USE Config  -%]
  Base url is [% Config.url %]

=head1 DESCRIPTION

Template::Plugin::Config is an easy config file plugin

Dead simple key/value config. Assumes flat key/value pairs. Any key becomes a
"method" that you can call on the config object to fetch its value.
Non-existent keys will cause this code to croak.


=head1 SEE ALSO

L<Template>, L<Config::Any>

=head1 AUTHOR

    Ovid.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

