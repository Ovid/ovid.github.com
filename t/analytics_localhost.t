#!/usr/bin/env perl

# The Google Analytics tag must fire in production and stay silent when Ovid is
# browsing locally, so dev traffic doesn't skew the site statistics.
#
# The generated HTML is what GitHub Pages serves, so these tests read the built
# pages rather than root/include/header.tt: the template being right is no use
# if the build doesn't carry the guard through.

use Test::Most;
use lib 'lib';
use Less::Boilerplate;

use Less::Config 'config';
use Path::Tiny;
use IPC::Run3;
use JSON::MaybeXS qw(decode_json);
use File::Find::Rule;

my $domain = config()->{domain};
my $ga_id  = config()->{google_analytics_id};

my @blog     = sort File::Find::Rule->file->name('*.html')->in('blog');
my @articles = sort File::Find::Rule->file->name('*.html')->in('articles');

# One page per generation path: hand-written, blog post, article, paginated index.
my @pages = grep { path($_)->exists } ( 'index.html', $blog[0], $articles[0], 'articles_2.html' );

sub ga_script ($html) {

    # The inline block that owns the gtag bootstrap.
    return $html =~ m{<script>\s*(if \(location\.hostname.*?)</script>}s ? $1 : undef;
}

subtest 'every generated page guards the tag' => sub {
    foreach my $page (@pages) {
        my $html = path($page)->slurp_utf8;
        ok defined ga_script($html), "$page has a hostname-guarded gtag block";
    }
};

subtest 'no page loads gtag.js unconditionally' => sub {

    # A bare <script src="...gtag/js..."> would run regardless of the guard,
    # which is exactly the bug this test exists to prevent from coming back.
    my @offenders;
    foreach my $page ( 'index.html', File::Find::Rule->file->name('*.html')->in( 'blog', 'articles' ) ) {
        my $html = path($page)->slurp_utf8;
        push @offenders, $page
          if $html =~ m{<script[^>]*\ssrc=["']https://www\.googletagmanager\.com}i;
    }
    is_deeply \@offenders, [], 'no static googletagmanager script tags in generated HTML'
      or diag "offending pages: @offenders";
};

# Behavioural check: run the extracted guard in Node against a stub DOM and see
# whether it actually appends the tag. Asserting on the source text alone would
# pass even if the condition were inverted.
SKIP: {
    my $node = `command -v node 2>/dev/null`;
    chomp $node;
    skip 'node not available', 1 unless $node;

    my $js = ga_script( path('index.html')->slurp_utf8 )
      or skip 'no gtag block to execute', 1;

    my @cases = (
        [ $domain,            1, 'the production domain fires the tag' ],
        [ "www.$domain",      1, '... as does the www subdomain' ],
        [ '127.0.0.1',        0, 'bin/review on 127.0.0.1 stays silent' ],
        [ 'localhost',        0, '... as does localhost (bin/launch)' ],
        [ '',                 0, '... as does a file:// page, which has no hostname' ],
        [ "evil$domain",      0, '... as does a domain merely ending in ours' ],
        [ "$domain.evil.com", 0, '... as does our domain used as a subdomain elsewhere' ],
    );

    my $harness = <<~'JS';
        const vm = require('vm');
        const [js, payload] = process.argv.slice(1);
        const out = JSON.parse(payload).map(hostname => {
            const appended = [];
            // A fresh context per hostname, so `const` declarations don't collide
            // and `window` is the global object as it is in a browser -- the
            // snippet's `window.dataLayer = ...` has to create a real global.
            const sandbox = {
                location: { hostname },
                document: {
                    createElement: () => ({}),
                    head: { appendChild: el => appended.push(el) },
                },
            };
            sandbox.window = sandbox;
            vm.runInNewContext(js, sandbox);
            return appended.map(el => el.src);
        });
        process.stdout.write(JSON.stringify(out));
        JS

    my ( $stdout, $stderr ) = ( '', '' );
    my $payload = JSON::MaybeXS->new->encode( [ map { $_->[0] } @cases ] );
    run3 [ $node, '-e', $harness, $js, $payload ], \undef, \$stdout, \$stderr;
    is $?, 0, "node ran cleanly (stderr: $stderr)" or skip 'node failed', 1;

    my $got = decode_json($stdout);
    for my $i ( 0 .. $#cases ) {
        my ( $hostname, $should_fire, $name ) = $cases[$i]->@*;
        my $srcs = $got->[$i];
        if ($should_fire) {
            is scalar $srcs->@*, 1, $name;
            like $srcs->[0], qr/\Qid=$ga_id\E/, "... requesting our GA id on $hostname";
        }
        else {
            is_deeply $srcs, [], $name;
        }
    }
}

done_testing;
