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
#
# The markup moved when analytics was gated to skip localhost: the static
# <script src="...?id=X"> became a script element built in JS, so the id is now
# delimited by single quotes rather than the double quotes of an HTML
# attribute. The guarantee under test is unchanged -- the id must interpolate
# and must never be left empty.
#
# The gate itself is covered here for the same reason. It compares
# location.hostname against Config.domain, so an empty domain would leave an
# unsatisfiable comparison that silently disables analytics *in production* --
# the same silent-failure mode as an empty id, just in the other direction.
subtest 'Google Analytics id is rendered into the header' => sub {
    my $ga_id  = config()->{google_analytics_id};
    my $domain = config()->{domain};
    ok $ga_id,  "config supplies a google_analytics_id ($ga_id)";
    ok $domain, "config supplies a domain ($domain)";

    my $output = '';
    $tt->process( 'include/header.tt', { type => 'article', title => 'x' }, \$output )
      or die $tt->error;

    like $output, qr/gtag\/js\?id=\Q$ga_id\E'/,
      'gtag.js script src includes the analytics id';
    like $output, qr/gtag\('config', '\Q$ga_id\E'\)/,
      "gtag('config') call includes the analytics id";
    unlike $output, qr/gtag\/js\?id='/,
      'gtag.js script src is never left with an empty id';
    unlike $output, qr/gtag\('config', ''\)/,
      "gtag('config') call is never left with an empty id";

    like $output, qr/location\.hostname === '\Q$domain\E'/,
      'localhost gate compares against the configured domain';
    unlike $output, qr/location\.hostname === ''/,
      'localhost gate is never left with an empty domain';
};

# Regression test: every page needs a <main> landmark, and the skip link needs
# a target that actually exists.
#
# <header>, <nav> and <footer> were all present but <main> was on none of the
# 150 generated pages, so assistive tech navigating by region had no way to
# reach the content (WCAG 2.1 §1.3.1). The skip link pointed at #article, which
# is emitted by include/wrapper.tt -- but the paginated indexes and 18 legacy
# articles include this header directly and never get that wrapper, leaving the
# link a dead anchor on 39 pages.
#
# Both are fixed by putting the landmark on .prose, which header.tt opens for
# every page, and pointing the skip link at it. The guarantee under test: the
# skip link's target must be an id this header actually emits.
subtest 'header provides a main landmark the skip link can reach' => sub {
    my $output = '';
    $tt->process( 'include/header.tt', { type => 'article', title => 'x' }, \$output )
      or die $tt->error;

    like $output, qr/<main\b[^>]*\bid="content"/,
      'header should open a <main> landmark';
    like $output, qr/<main\b[^>]*\bclass="prose"/,
      '... carrying the prose class the stylesheet targets';

    my ($target) = $output =~ /class="skip-link" href="#([^"]+)"/;
    ok $target, "skip link has a fragment target (#$target)";
    like $output, qr/\bid="\Q$target\E"/,
      '... and an element with that id exists in the header itself';
};

done_testing;
