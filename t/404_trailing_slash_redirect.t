#!/usr/bin/env perl

# The 404 page's trailing-slash redirect runs in the browser. The function
# is small enough to extract from the rendered HTML and exercise via Node
# with a stubbed `location` and `fetch`. This catches regressions if the
# script is dropped or its decision logic changes (e.g. losing the
# search/hash preservation, or stopping the short-circuit on /).

use Test::Most;
use Path::Tiny;
use IPC::Run3;
use JSON::MaybeXS qw(decode_json);

my $built_404 = path('404.html');
plan skip_all => '404.html not built' unless $built_404->exists;

my $html = $built_404->slurp_utf8;

like $html, qr/GitHub Pages doesn't strip trailing slashes/,
    'redirect comment is present in the built 404 page';

# Source-level sanity: the gating short-circuits and the HEAD-then-replace
# shape must remain intact. These complement the behavioral test below.
like $html, qr/path === '\/' \|\| !path\.endsWith\('\/'\)/,
    'short-circuits when path is "/" or has no trailing slash';
like $html, qr/method: 'HEAD'/,
    'uses HEAD to probe whether the slash-less form exists';
like $html, qr/location\.replace\(target \+ location\.search \+ location\.hash\)/,
    'preserves ?query and #hash when redirecting';
like $html, qr/visibility: hidden/,
    'hides body during the probe to avoid flashing 404 content';

# Behavioral check: extract the IIFE and run it in Node with stubbed
# location + fetch.
SKIP: {
    my $node = `command -v node 2>/dev/null`;
    chomp $node;
    skip 'node not available', 1 unless $node;

    # Pull the IIFE out of the built page. The marker comment makes it
    # easy to anchor on, and we grab up through the closing })();
    my ($iife) = $html =~ m{
        (\(function\(\)\s*\{
         .*?
         \}\)\(\);
        )
    }xs;
    ok defined $iife, 'extracted redirect IIFE from built 404 page'
        or skip 'no IIFE extracted', 1;

    # Each case: { path, head_ok, expect_redirect, expect_target_suffix? }
    # `head_ok` controls whether the stubbed fetch resolves r.ok = true.
    my @cases = (
        {
            name => 'extensionless 404 (no slash) — no redirect',
            path => '/articles/foo',
            head_ok => 1,
            expect_redirect => 0,
        },
        {
            name => 'root / — never redirect',
            path => '/',
            head_ok => 1,
            expect_redirect => 0,
        },
        {
            name => 'trailing slash, slash-less form exists → redirect',
            path => '/articles/foo/',
            head_ok => 1,
            expect_redirect => 1,
            expect_target => '/articles/foo',
        },
        {
            name => 'trailing slash, slash-less form 404s → stay on 404',
            path => '/articles/genuinely-missing/',
            head_ok => 0,
            expect_redirect => 0,
        },
        {
            name => 'trailing slash with query+hash preserved',
            path => '/articles/foo/',
            search => '?utm=1',
            hash => '#section',
            head_ok => 1,
            expect_redirect => 1,
            expect_target => '/articles/foo?utm=1#section',
        },
    );

    my $harness = <<~"JS";
        const cases = $iife;
        // The IIFE above runs at import time using location/fetch globals
        // — we need to swap stubs in BEFORE each invocation. Wrap it:
        JS
    my $j = JSON::MaybeXS->new( allow_nonref => 1 );
    # Build a self-contained script per case, run each independently.
    for my $case (@cases) {
        my $search = $case->{search} // '';
        my $hash   = $case->{hash}   // '';
        my $script = <<~"JS";
            globalThis.fetchCalls = [];
            globalThis.replaceCalls = [];
            globalThis.location = {
                pathname: @{[ $j->encode($case->{path}) ]},
                search:   @{[ $j->encode($search) ]},
                hash:     @{[ $j->encode($hash) ]},
                replace:  function(url) { globalThis.replaceCalls.push(url); },
            };
            globalThis.fetch = function(url, opts) {
                globalThis.fetchCalls.push({ url: url, method: opts && opts.method });
                return Promise.resolve({ ok: @{[ $case->{head_ok} ? 'true' : 'false' ]} });
            };
            // Minimal document stub: just enough for createElement + head.appendChild.
            const fakeStyle = { textContent: '', remove: function() { globalThis.styleRemoved = true; } };
            globalThis.styleRemoved = false;
            globalThis.document = {
                createElement: function() { return fakeStyle; },
                head: { appendChild: function() { globalThis.styleAppended = true; } },
            };
            globalThis.styleAppended = false;
            $iife
            // Give the promise microtask a chance to settle, then report.
            Promise.resolve().then(() => Promise.resolve()).then(() => {
                process.stdout.write(JSON.stringify({
                    fetchCalls: globalThis.fetchCalls,
                    replaceCalls: globalThis.replaceCalls,
                    styleAppended: globalThis.styleAppended,
                    styleRemoved: globalThis.styleRemoved,
                }));
            });
            JS

        my $stdout = '';
        my $stderr = '';
        run3 [ $node, '-e', $script ], \undef, \$stdout, \$stderr;
        is $?, 0, "$case->{name}: node exited cleanly (stderr: $stderr)"
            or next;
        my $result = decode_json($stdout);

        if ( $case->{expect_redirect} ) {
            is scalar @{ $result->{replaceCalls} }, 1,
                "$case->{name}: location.replace called exactly once";
            is $result->{replaceCalls}[0], $case->{expect_target},
                "$case->{name}: redirected to $case->{expect_target}";
        }
        else {
            is scalar @{ $result->{replaceCalls} }, 0,
                "$case->{name}: no redirect triggered";
        }
    }
}

done_testing;
