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

subtest 'config structure and common keys' => sub {
    my $config = config();

    # Test that we have a hash reference
    isa_ok $config, 'HASH', 'config() return value';

    # Test required config entries exist
    ok exists $config->{url}, 'Config should contain url key';

    # Test tagmap if it exists
    if ( exists $config->{tagmap} ) {
        isa_ok $config->{tagmap}, 'HASH', 'tagmap should be a hash reference';
    }
};

subtest 'config caching and consistency' => sub {
    my $config1 = config();
    my $config2 = config();

    # The configs should have the same values even if called multiple times
    is_deeply $config1, $config2, 'Multiple calls to config() should return consistent data';

    # Verify url is consistent
    if ( exists $config1->{url} ) {
        is $config1->{url}, $config2->{url}, 'URL should be consistent across calls';
    }
};

subtest 'template plugin method access' => sub {
    my $plugin = Template::Plugin::Config->new(undef);

    # Test that config entries can be accessed as methods via AUTOLOAD
    # Note: can() won't work because the methods are created via AUTOLOAD

    # Test actual url value is returned
    my $url = $plugin->url;
    ok defined($url), 'url method should return a defined value';
    like $url, qr{^https?://}, 'url should start with http:// or https://';
};

subtest 'error handling for invalid keys' => sub {
    my $plugin = Template::Plugin::Config->new(undef);

    # Test various invalid key formats
    throws_ok { $plugin->invalid_key_12345 }
    qr/No such config entry 'invalid_key_12345'/,
      'Should throw error for numeric suffix key';

    throws_ok { $plugin->_private_key }
    qr/No such config entry '_private_key'/,
      'Should throw error for private-looking key';

    throws_ok { $plugin->CONSTANT_KEY }
    qr/No such config entry 'CONSTANT_KEY'/,
      'Should throw error for constant-looking key';
};

done_testing;
