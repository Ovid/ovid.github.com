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
# the blog class is applied.

use Test::Most;
use lib 'lib';
use Test2::Plugin::UTF8;
use Less::Boilerplate;
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

    like $output, qr/class="row title blog"/,
      'header for a blog post should include the blog class';
};

subtest 'articles do not get the blog CSS class' => sub {
    my $output = '';
    $tt->process( 'include/header.tt', { type => 'article', title => 'x' }, \$output )
      or die $tt->error;

    unlike $output, qr/class="row title blog"/,
      'header for an article should not include the blog class';
    like $output, qr/class="row title"/,
      'header for an article should still have the row title class';
};

done_testing;
