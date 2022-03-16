#!/usr/bin/env perl

use Test::Most;
use lib 'lib';

use Less::Config 'config';
use Template::Plugin::Config;

subtest 'bare config' => sub {
    ok my $config = config(), 'We shoudl be able to fetch our config';
    is ref $config, 'HASH', '... and it should be a hash reference';
    ok exists $config->{url}, '... and we should have our base url';
    ok !exists $config->{no_such_config_entry}, '... and not have non-existent entries';
};

subtest 'template plugin' => sub {
    ok my $config = Template::Plugin::Config->new(undef),
      'We should be able to create a config plugin';
    like $config->url, qr{^https?://[^/]+/$},
      'We should be able to fetch individual config entries';
    throws_ok { $config->no_such_config_entry }
    qr/No such config entry 'no_such_config_entry'/,
      '... but requesting a non-existent one should be fatal';
};

done_testing;
