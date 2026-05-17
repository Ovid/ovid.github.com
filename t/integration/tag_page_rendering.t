#!/usr/bin/env perl

# Regression test for the "template calls a missing plugin method" failure
# mode. When Template Toolkit can't find a plugin method, it silently returns
# undef instead of failing — so a refactor that drops a method only surfaces
# when someone notices empty pages in production.
#
# This test renders root/include/tags.tt against the real tagmap and asserts
# the rendered page actually contains article links, not the "No articles
# found" fallback message.

use Test::Most;
use lib 'lib';
use Test2::Plugin::UTF8;
use Less::Boilerplate;
use Less::Config 'config';
use Template;

my $tt = Template->new(
    {   INCLUDE_PATH => 'root',
        PLUGIN_BASE  => 'Template::Plugin',
        ABSOLUTE     => 0,
    }
) or die Template->error;

subtest 'tag page lists articles for a known tag' => sub {
    my $output = '';
    $tt->process( 'include/tags.tt', { tag => 'ai' }, \$output )
      or die $tt->error;

    unlike $output, qr/No articles found/,
      'Known tag should not render the empty-state message';
    like $output, qr{<li><a href="/articles/[^"]+\.html">[^<]+</a>}i,
      'Known tag should render at least one article link';
};

subtest 'tag page shows empty state for an unknown tag' => sub {
    my $output = '';
    $tt->process( 'include/tags.tt', { tag => 'no-such-tag-xyz' }, \$output )
      or die $tt->error;

    like $output, qr/No articles found for 'no-such-tag-xyz'/,
      'Unknown tag should render the empty-state message';
};

done_testing;
