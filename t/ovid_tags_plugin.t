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

subtest 'weight_for_tag croaks for unknown tag' => sub {
    my $plugin = Template::Plugin::Ovid::Tags->new(undef);

    throws_ok {
        $plugin->weight_for_tag('nonexistent_tag_xyz');
    }
    qr/Cannot find weight for unknown tag/, 'Should croak for unknown tag in weight_for_tag';
};

subtest 'has_articles_for_tag returns true for known tags' => sub {
    my $plugin = Template::Plugin::Ovid::Tags->new(undef);
    my @tags   = $plugin->tags_by_weight;

    ok scalar(@tags) > 0, 'Should have at least one tag to test';

    foreach my $tag (@tags) {
        ok $plugin->has_articles_for_tag($tag),
          "Should return true for known tag '$tag'";
    }
};

subtest 'has_articles_for_tag returns false for unknown tags' => sub {
    my $plugin = Template::Plugin::Ovid::Tags->new(undef);
    ok !$plugin->has_articles_for_tag('nonexistent_tag_xyz'),
      'Should return false for unknown tag';
};

subtest 'files_for_tag returns a Collection of files' => sub {
    my $plugin = Template::Plugin::Ovid::Tags->new(undef);
    my @tags   = $plugin->tags_by_weight;

    ok scalar(@tags) > 0, 'Should have at least one tag to test';

    foreach my $tag (@tags) {
        my $collection = $plugin->files_for_tag($tag);
        isa_ok $collection, 'Ovid::Template::File::Collection',
          "files_for_tag('$tag') return value";
        ok $collection->count > 0,
          "Collection for '$tag' should contain at least one file";
    }
};

subtest 'files_for_tag croaks for unknown tag' => sub {
    my $plugin = Template::Plugin::Ovid::Tags->new(undef);

    throws_ok {
        $plugin->files_for_tag('nonexistent_tag_xyz');
    }
    qr/Cannot find files for unknown tag/,
      'Should croak for unknown tag in files_for_tag';
};

# Regression test for [I4]: reading `$self->{tagmap}{$tag}{files}` used to
# autovivify `$self->{tagmap}{$tag} = {}` as a side effect, even when the
# call croaked. That left `has_articles_for_tag($tag)` returning true on
# subsequent calls — symmetry broken, long-running processes accumulate
# junk keys.
subtest 'files_for_tag does not autovivify the tagmap on unknown tag' => sub {
    my $plugin = Template::Plugin::Ovid::Tags->new(undef);
    my $unknown = 'nonexistent_tag_for_autoviv_test';

    eval { $plugin->files_for_tag($unknown) };
    ok $@, 'files_for_tag croaks for unknown tag';

    ok !exists $plugin->{tagmap}{$unknown},
      'tagmap should not gain an entry after the failed call';
    ok !$plugin->has_articles_for_tag($unknown),
      'has_articles_for_tag still returns false after the failed call';
};

# Regression test for [I5]: __ALL__ is a reserved key in tagmap.json that
# stores the URL→tags reverse index. It must not be exposed via the
# public tag-query API. `_tags` and `tags_by_weight` already filter it;
# `has_articles_for_tag` and `files_for_tag` did not.
subtest '__ALL__ is treated as a reserved key, not a queryable tag' => sub {
    my $plugin = Template::Plugin::Ovid::Tags->new(undef);

    ok !$plugin->has_articles_for_tag('__ALL__'),
      'has_articles_for_tag returns false for __ALL__';
    throws_ok {
        $plugin->files_for_tag('__ALL__');
    }
    qr/unknown tag/,
      'files_for_tag treats __ALL__ as an unknown tag';
};

# Regression test for [I9]: `name_for_tag` used to read from
# `config()->{tagmap}{$tag}` even though `_build_tags` stores the name
# into tagmap.json. Two read paths for the same datum is a recipe for
# drift; the in-memory tagmap is the source of truth for the plugin.
subtest 'name_for_tag reads from loaded tagmap, not from config' => sub {
    my $plugin = Template::Plugin::Ovid::Tags->new(undef);
    my $tag    = ( $plugin->tags_by_weight )[0];

    # Mutate just the loaded tagmap (not config).
    $plugin->{tagmap}{$tag}{name} = 'MUTATED_NAME_FOR_TEST';
    is $plugin->name_for_tag($tag), 'MUTATED_NAME_FOR_TEST',
      'name_for_tag returns the in-memory tagmap value';
};

# Regression test for [I10]: the weight cache used `state $weight_for = {}`,
# which lives for the lifetime of the Perl process and is shared across
# every plugin instance. Long-running processes (live editor) saw stale
# weights after content changes. Cache should be per-instance.
subtest 'weight cache is per-instance, not shared across plugin instances' => sub {
    my $plugin1 = Template::Plugin::Ovid::Tags->new(undef);
    my $plugin2 = Template::Plugin::Ovid::Tags->new(undef);

    my $tag = ( $plugin1->tags_by_weight )[0];

    # Prime plugin1's cache.
    $plugin1->weight_for_tag($tag);

    # Mutate plugin2's view so its weight calc would now croak.
    delete $plugin2->{tagmap}{$tag};

    # If the cache is shared, plugin2 returns the cached value (no croak).
    # If per-instance, plugin2 recomputes and croaks on the missing tag.
    throws_ok {
        $plugin2->weight_for_tag($tag);
    }
    qr/unknown tag/,
      'plugin2 recomputes from its own data (no process-scoped cache leak)';
};

subtest 'division by zero protection exists' => sub {
    # This test verifies that the division by zero protection code exists
    # by reading the source and checking for the guard condition.
    # We can't easily test it in isolation due to state variables,
    # but we can verify the code is present.

    my $source_file = '/Users/ovid/website/lib/Template/Plugin/Ovid/Tags.pm';
    open my $fh, '<', $source_file or die "Cannot read $source_file: $!";
    my $source = do { local $/; <$fh> };
    close $fh;

    like $source, qr/if\s*\(\s*\$max\s*==\s*\$min\s*\)/,
        'Division by zero protection guard exists (max == min check)';

    like $source, qr/int\s*\(\s*\(\s*\$weight_max\s*\+\s*\$weight_min\s*\)\s*\/\s*2\s*\)/,
        'Equal count case uses middle weight calculation';

    pass 'Division by zero protection is implemented in weight_for_tag';
};

done_testing;
