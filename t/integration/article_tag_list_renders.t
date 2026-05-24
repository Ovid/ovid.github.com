#!/usr/bin/env perl

# Canary for the coordinated tagmap-key change between
# lib/Ovid/Template/File.pm (key construction) and
# root/include/tags_for_article.tt (lookup). If either side drifts,
# articles' tag lists go silently empty.

use Test::Most;
use lib 'lib';
use Test2::Plugin::UTF8;
use Less::Boilerplate;
use Path::Tiny qw(path);
use HTML::TokeParser::Simple;

subtest 'rendered article page contains a non-empty tag list' => sub {
    my ($article) = glob('articles/*.html');
    plan skip_all => 'no built articles to inspect' unless $article;

    my $html   = path($article)->slurp_utf8;
    my $parser = HTML::TokeParser::Simple->new( string => $html );

    my $in_tag_nav = 0;
    my $tag_links  = 0;
    while ( my $token = $parser->get_token ) {
        if ( $token->is_start_tag('ul') ) {
            my $aria = $token->get_attr('aria-label') // '';
            $in_tag_nav = 1 if $aria =~ /Tag list/;
        }
        elsif ( $token->is_end_tag('ul') ) {
            $in_tag_nav = 0;
        }
        elsif ( $in_tag_nav && $token->is_start_tag('a') ) {
            $tag_links++;
        }
    }

    cmp_ok $tag_links, '>', 0,
        "article '$article' renders at least one <a> in its tag list";
};

done_testing;
