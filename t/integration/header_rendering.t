#!/usr/bin/env perl

# Regression test for the "template calls a missing plugin method" failure
# mode in root/include/header.tt. The header used to call Ovid.is_blog(type)
# to apply a `blog` CSS class to the title row on blog posts, but the
# is_blog method was removed from Template::Plugin::Ovid as part of the
# plugin-separation refactor and the template caller was never updated.
# Template Toolkit silently returns undef for missing-method calls, so the
# blog class was missing from every blog post's header with no error.
#
# This test renders root/include/header.tt with type='blog' and asserts
# the blog marker class is applied.
#
# The marker moved with the editorial redesign: the old title row
# (class="row title blog") became the article opener, so the hook is now
# `opener--blog` on the opener itself. The guarantee under test is unchanged
# -- blog posts must carry a marker distinguishing them from technical
# articles, and it must not go missing silently.

use Test::Most;
use lib 'lib';
use Test2::Plugin::UTF8;
use Less::Boilerplate;
use Less::Config qw(config);
use Template;

my $tt = Template->new(
    {   INCLUDE_PATH => 'root',
        PLUGIN_BASE  => 'Template::Plugin',
        ABSOLUTE     => 0,
    }
) or die Template->error;

subtest 'blog posts get the blog CSS class on the title row' => sub {
    my $output = '';
    $tt->process( 'include/header.tt', { type => 'blog', title => 'x' }, \$output )
      or die $tt->error;

    like $output, qr/class="opener opener--blog"/,
      'header for a blog post should include the blog marker class';
};

subtest 'articles do not get the blog CSS class' => sub {
    my $output = '';
    $tt->process( 'include/header.tt', { type => 'article', title => 'x' }, \$output )
      or die $tt->error;

    unlike $output, qr/opener--blog/,
      'header for an article should not include the blog marker class';
    like $output, qr/class="opener"/,
      'header for an article should still have the opener class';
};

# Regression test: the Google Analytics ID must render into the gtag markup.
# The gtag block references Config.google_analytics_id, but `USE Config` used
# to appear *below* that block, so Config was uninstantiated when the block
# ran and TT silently rendered an empty id (id="" / gtag('config', '')) into
# every page whose source predated the config extraction.
subtest 'Google Analytics id is rendered into the header' => sub {
    my $ga_id = config()->{google_analytics_id};
    ok $ga_id, "config supplies a google_analytics_id ($ga_id)";

    my $output = '';
    $tt->process( 'include/header.tt', { type => 'article', title => 'x' }, \$output )
      or die $tt->error;

    like $output, qr/gtag\/js\?id=\Q$ga_id\E"/,
      'gtag.js script src includes the analytics id';
    like $output, qr/gtag\('config', '\Q$ga_id\E'\)/,
      "gtag('config') call includes the analytics id";
    unlike $output, qr/gtag\/js\?id="/,
      'gtag.js script src is never left with an empty id';
};

done_testing;
