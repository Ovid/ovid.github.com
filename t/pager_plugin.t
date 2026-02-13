#!/usr/bin/env perl

use Test::Most;
use lib 'lib';

subtest 'Pager plugin is thin wrapper for Less::Pager' => sub {
    require_ok('Template::Plugin::Pager');

    my $plugin = Template::Plugin::Pager->new( undef, { type => 'article' } );
    isa_ok $plugin, 'Less::Pager', 'Should return Less::Pager instance';

    can_ok $plugin, qw(prev_post next_post this_post);
};

subtest 'Pager plugin maps directory names to article types' => sub {
    # Test 'articles' directory maps to 'article' type
    my $plugin = Template::Plugin::Pager->new( undef, { type => 'articles' } );
    isa_ok $plugin, 'Less::Pager', 'Should handle directory name "articles"';
    is $plugin->type, 'article', 'Should map "articles" to "article"';

    # Test 'blog' remains unchanged
    $plugin = Template::Plugin::Pager->new( undef, { type => 'blog' } );
    is $plugin->type, 'blog', 'Should keep "blog" unchanged';

    # Test empty string defaults to 'article'
    $plugin = Template::Plugin::Pager->new( undef, { type => '' } );
    is $plugin->type, 'article', 'Should default empty string to "article"';

    # Test missing type defaults to 'article'
    $plugin = Template::Plugin::Pager->new( undef, {} );
    is $plugin->type, 'article', 'Should default missing type to "article"';
};

done_testing;
