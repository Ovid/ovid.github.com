#!/usr/bin/env perl

# vim: ft=perl

=comment

Install all dependencies with:

    cpanm --installdeps . --with-configure --with-develop --with-all-features

See https://metacpan.org/pod/CPAN::Meta::Spec#VERSION-NUMBERS for details.

=cut

requires 'Import::Into'    => '1.002005';
requires 'String::Util'    => '1.26';
requires 'Template'        => '2.28';
requires 'Text::Unidecode' => '1.30';
requires 'Test::Most'      => '0.35';
