#!/usr/bin/env perl

use Test::Most;
use lib 'lib';
use Test2::Plugin::UTF8;
use Less::Boilerplate;
use Less::Config 'config';
use Template::Plugin::Ovid::Tags;

# Test the new Tags plugin
subtest 'Tags plugin loads and initializes' => sub {
    my $plugin = Template::Plugin::Ovid::Tags->new(undef);
    isa_ok $plugin, 'Template::Plugin::Ovid::Tags';
    ok exists $plugin->{tagmap}, 'Plugin should have tagmap data';
};

subtest 'tags_by_weight returns sorted tags' => sub {
    my $plugin = Template::Plugin::Ovid::Tags->new(undef);
    my @tags   = $plugin->tags_by_weight;

    ok scalar(@tags) > 0, 'Should return some tags';

    # Verify it excludes __ALL__
    ok !( grep { $_ eq '__ALL__' } @tags ), 'Should not include __ALL__';

    # Verify tags are valid (exist in config)
    my $config = config();
    foreach my $tag (@tags) {
        ok exists $config->{tagmap}{$tag}, "Tag '$tag' should exist in config";
    }
};

subtest 'weight_for_tag calculates weights' => sub {
    my $plugin = Template::Plugin::Ovid::Tags->new(undef);
    my @tags   = $plugin->tags_by_weight;

    foreach my $tag (@tags) {
        my $weight = $plugin->weight_for_tag($tag);
        like $weight, qr/^\d+$/, "Weight for '$tag' should be an integer";
        ok $weight >= 1 && $weight <= 9, "Weight should be 1-9, got $weight";
    }
};

subtest 'name_for_tag returns display names' => sub {
    my $plugin = Template::Plugin::Ovid::Tags->new(undef);
    my $config = config();

    foreach my $tag ( keys $config->{tagmap}->%* ) {
        my $name = $plugin->name_for_tag($tag);
        is $name, $config->{tagmap}{$tag}, "Name for '$tag' should match config";
    }
};

subtest 'name_for_tag croaks for unknown tag' => sub {
    my $plugin = Template::Plugin::Ovid::Tags->new(undef);

    throws_ok {
        $plugin->name_for_tag('nonexistent_tag_xyz');
    }
    qr/Cannot find name for unknown tag/, 'Should croak for unknown tag';
};

done_testing;
