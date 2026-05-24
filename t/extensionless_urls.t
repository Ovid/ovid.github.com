#!/usr/bin/env perl

use Test::Most;
use lib 'lib';
use Less::Boilerplate;
use Mojo::DOM;
use Path::Tiny qw(path);
use File::Find::Rule;

# Shared helper: parse $file, find elements matching $selector, return
# error strings for any whose text matches the .html-URL regex.
# The absolute-URL curtispoe.org host check from the spec is implicitly
# satisfied — current logic flags any URL ending in .html, regardless of
# host. For sitemap/RSS this is fine because those files only contain our
# own URLs anyway.
sub _violating_urls_in ( $file, $selector, $label ) {
    my $dom = Mojo::DOM->new->xml(1)->parse( path($file)->slurp_utf8 );
    # grep+map rather than map alone so the sub returns a plain list even
    # when called in scalar context (avoids comma-operator ambiguity when
    # the caller passes the result through scalar()).
    return grep { defined }
        map {
            my $url = $_->text;
            $url =~ m{\.html(?:[?#]|\z)}
                ? "$label '$url' ends in .html"
                : undef;
        } $dom->find($selector)->each;
}

sub sitemap_violations ($file) {
    return _violating_urls_in( $file, 'loc', '<loc>' );
}

sub rss_violations ($file) {
    # Collect into an array to force list context on both inner calls,
    # preventing Perl's comma-operator scalar-context behaviour from
    # swallowing the first call's count.
    my @errors = (
        _violating_urls_in( $file, 'item link', 'RSS <link>' ),
        _violating_urls_in( $file, 'item guid', 'RSS <guid>' ),
    );
    return @errors;
}

subtest 'sitemap pass against fixtures' => sub {
    cmp_ok( scalar sitemap_violations('t/fixtures/extensionless_urls/violating-sitemap.xml'),
        '==', 1, 'one violation in violating fixture' );
    cmp_ok( scalar sitemap_violations('t/fixtures/extensionless_urls/clean-sitemap.xml'),
        '==', 0, 'no violations in clean fixture' );
};

subtest 'RSS pass against fixtures' => sub {
    cmp_ok( scalar rss_violations('t/fixtures/extensionless_urls/violating-feed.rss'),
        '==', 1, 'one violation in violating fixture' );
    cmp_ok( scalar rss_violations('t/fixtures/extensionless_urls/clean-feed.rss'),
        '==', 0, 'no violations in clean fixture' );
};

subtest 'live sitemap.xml is clean' => sub {
    plan skip_all => 'no sitemap.xml built' unless -e 'sitemap.xml';
    my @errors = sitemap_violations('sitemap.xml');
    is scalar(@errors), 0, 'sitemap.xml has no .html violations'
        or diag join "\n", @errors;
};

subtest 'live *.rss are clean' => sub {
    my @feeds = grep {
        !m{^(?:\.worktrees|t/fixtures)/}
    } File::Find::Rule->file->name('*.rss')->in('.');
    plan skip_all => 'no .rss files built' unless @feeds;
    for my $feed (@feeds) {
        my @errors = rss_violations($feed);
        is scalar(@errors), 0, "$feed has no .html violations"
            or diag join "\n", @errors;
    }
};

done_testing;
