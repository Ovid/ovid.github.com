#!/usr/bin/env perl

use Test::Most;
use lib 'lib';
use Template::Plugin::Config;

ok my $config = Template::Plugin::Config->new(undef),
  'We should be able to create a config plugin';
like $config->url, qr{^https?://[^/]+/$},
  'We should be able to fetch individual config entries';
throws_ok { $config->no_such_config_entry }
qr/No such config entry 'no_such_config_entry'/,
  '... but requesting a non-existent one should be fatal';

done_testing;
