#!/usr/bin/env perl

use Test::Most;
use lib 'lib';

subtest 'Pager plugin is thin wrapper for Less::Pager' => sub {
    require_ok('Template::Plugin::Pager');

    my $plugin = Template::Plugin::Pager->new( undef, { type => 'article' } );
    isa_ok $plugin, 'Less::Pager', 'Should return Less::Pager instance';

    can_ok $plugin, qw(prev_post next_post this_post);
};

done_testing;
