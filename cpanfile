#!/usr/bin/env perl

# vim: ft=perl

=comment

Install all dependencies with:

    cpanm --installdeps . --with-configure --with-develop --with-all-features

See https://metacpan.org/pod/CPAN::Meta::Spec#VERSION-NUMBERS for details.

=cut

requires 'DateTime::Format::SQLite'   => '0.11';
requires 'DBD::SQLite'                => '1.62';
requires 'DBI'                        => '1.642';
requires 'File::Find::Rule'           => '0.34';
requires 'HTML::Lint'                 => '2.32';
requires 'HTML::TokeParser::Simple'   => '3.16';
requires 'Import::Into'               => '1.002005';
requires 'Moose'                      => '2.2011';
requires 'String::Util'               => '1.26';
requires 'Template'                   => '2.28';
requires 'Template::Plugin::Markdown' => '0.02';
requires 'Test::Most'                 => '0.35';
requires 'Text::Unidecode'            => '1.30';
requires 'autodie'                    => '2.29';
requires "XML::RSS"                   => '1.59';
