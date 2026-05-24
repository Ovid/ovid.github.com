#!/usr/bin/env perl

use Test::Most;
use lib 'lib';
use Less::Boilerplate;
use Path::Tiny qw(path);
use Cwd        qw(getcwd);
use IPC::Run3  qw(run3);

my $cwd    = getcwd();
my $script = path('bin/strip-html-urls')->absolute;

END { chdir $cwd }

# Runs $script from $dir with @args. Returns (combined_output, exit_err).
# combined_output is stdout+stderr merged so error messages are always visible.
# exit_err is non-empty string when process exits non-zero, empty otherwise.
sub run_in ( $dir, @args ) {
    chdir $dir;
    my $combined = '';
    run3( [ $^X, "$script", @args ], \undef, \$combined, \$combined );
    my $exit_err = $? ? sprintf( "exited %d", $? >> 8 ) : '';
    chdir $cwd;
    return ( $combined, $exit_err );
}

subtest 'CWD pre-flight gate rejects non-project directories' => sub {
    my $tmpdir = Path::Tiny->tempdir;
    my ( $out, $err ) = run_in( $tmpdir, '--dry-run' );
    ok $err, 'script aborts with non-zero exit outside a project root';
    like "$err$out", qr/project root|root\/, lib\/, bin\/rebuild/i,
        'error message mentions the missing project markers';
};

subtest 'dirty-tree gate rejects unless --force' => sub {
    my $tmproot = Path::Tiny->tempdir;
    $tmproot->child('root')->mkpath;
    $tmproot->child('lib')->mkpath;
    $tmproot->child('bin')->mkpath;
    $tmproot->child('bin/rebuild')->spew('# stub');
    $tmproot->child('root/test.tt')->spew('initial content');

    chdir $tmproot;
    system( 'git', 'init', '-q' );
    system( 'git', 'config', 'user.email', 't@t' );
    system( 'git', 'config', 'user.name',  't' );
    system( 'git', 'add', '-A' );
    system( 'git', 'commit', '-q', '-m', 'init' );

    $tmproot->child('root/test.tt')->spew('dirty content');

    my ( $out, $err ) = run_in( $tmproot, '--dry-run' );
    ok $err, 'aborts when root/ has uncommitted changes';
    like "$err$out", qr/uncommitted|dirty|--force/i,
        'error message references --force escape hatch';

    ( $out, $err ) = run_in( $tmproot, '--dry-run', '--force' );
    ok !$err, '--force bypasses dirty-tree gate';

    chdir $cwd;
};

subtest 'quote-form survey gate rejects single-quoted or space-padded hrefs' => sub {
    my $tmproot = Path::Tiny->tempdir;
    $tmproot->child('root')->mkpath;
    $tmproot->child('lib')->mkpath;
    $tmproot->child('bin')->mkpath;
    $tmproot->child('bin/rebuild')->spew('# stub');

    $tmproot->child('root/bad.tt')->spew(q{<a href='/foo.html'>x</a>});

    chdir $tmproot;
    system( 'git', 'init', '-q' );
    system( 'git', 'config', 'user.email', 't@t' );
    system( 'git', 'config', 'user.name',  't' );
    system( 'git', 'add', '-A' );
    system( 'git', 'commit', '-q', '-m', 'init' );

    my ( $out, $err ) = run_in( $tmproot, '--dry-run' );
    ok $err, 'aborts when single-quoted root-relative .html href present';
    like "$err$out", qr/quote.?form|single.?quote|widen.*regex/i,
        'error message mentions the form the rewriter cannot handle';

    chdir $cwd;
};

subtest 'rewrite logic transforms root-relative .html hrefs' => sub {
    my $tmproot = Path::Tiny->tempdir;
    $tmproot->child('root')->mkpath;
    $tmproot->child('lib')->mkpath;
    $tmproot->child('bin')->mkpath;
    $tmproot->child('bin/rebuild')->spew('# stub');

    my $fixture = <<~'EOT';
        <a href="/index.html">Home</a>
        <a href="/blog/foo.html">Foo</a>
        <a href="/articles/bar.html#section">Bar w/ fragment</a>
        <a href="/blog/baz.html?utm=1">Baz w/ query</a>
        <a href="https://example.com/x.html">External</a>
        <a href="foo.html">Relative</a>
        <a href="mailto:x@y.z">Mail</a>
        <a href="/[% IF prev; type _ '/' _ prev.slug _ '.html'; END %]">Templated</a>
        See [Markdown](/articles/intro.html) for more.
        [% Ovid.link('/articles/about.html', 'About') %]
        [% Ovid.cite('/articles/foo.html', 'Foo') %]
        EOT
    $tmproot->child('root/all-cases.tt')->spew_utf8($fixture);

    chdir $tmproot;
    system( 'git', 'init', '-q' );
    system( 'git', 'config', 'user.email', 't@t' );
    system( 'git', 'config', 'user.name',  't' );
    system( 'git', 'add', '-A' );
    system( 'git', 'commit', '-q', '-m', 'init' );

    my ( $out, $err ) = run_in( $tmproot );
    ok !$err, 'rewrite runs cleanly';

    my $after = $tmproot->child('root/all-cases.tt')->slurp_utf8;

    like   $after, qr{href="/">Home},                       'index.html → /';
    like   $after, qr{href="/blog/foo">Foo},                'root-relative .html stripped';
    like   $after, qr{href="/articles/bar#section">},       '#fragment preserved';
    like   $after, qr{href="/blog/baz\?utm=1">},            '?query preserved';
    like   $after, qr{href="https://example.com/x\.html">}, 'external untouched';
    like   $after, qr{href="foo\.html">},                   'relative untouched';
    like   $after, qr{href="mailto:},                       'mailto untouched';
    like   $after, qr{prev\.slug _ '\.html'},               'templated TT untouched';
    like   $after, qr{\]\(/articles/intro\)},               'Markdown link .html stripped';
    like   $after, qr{Ovid\.link\('/articles/about',},      'Ovid.link .html stripped';
    like   $after, qr{Ovid\.cite\('/articles/foo',},        'Ovid.cite rewritten';

    chdir $cwd;
};

subtest 'Step C rewrites Markdown links' => sub {
    my $tmproot = Path::Tiny->tempdir;
    $tmproot->child('root')->mkpath;
    $tmproot->child('lib')->mkpath;
    $tmproot->child('bin')->mkpath;
    $tmproot->child('bin/rebuild')->spew('# stub');

    my $fixture = <<~'EOT';
        [Root link](/articles/intro.html)
        [Fragment link](/articles/intro.html#section)
        [Query link](/articles/intro.html?utm=1)
        [External](https://example.com/page.html)
        [Relative](foo.html)
        EOT
    $tmproot->child('root/md-cases.tt2markdown')->spew_utf8($fixture);

    chdir $tmproot;
    system( 'git', 'init', '-q' );
    system( 'git', 'config', 'user.email', 't@t' );
    system( 'git', 'config', 'user.name',  't' );
    system( 'git', 'add', '-A' );
    system( 'git', 'commit', '-q', '-m', 'init' );

    my ( $out, $err ) = run_in( $tmproot );
    ok !$err, 'Markdown rewrite runs cleanly';

    my $after = $tmproot->child('root/md-cases.tt2markdown')->slurp_utf8;

    like   $after, qr{\]\(/articles/intro\)},          'root-relative .html stripped';
    like   $after, qr{\]\(/articles/intro#section\)},  '#anchor preserved after strip';
    like   $after, qr{\]\(/articles/intro\?utm=1\)},   '?query preserved after strip';
    like   $after, qr{\]\(https://example\.com/page\.html\)}, 'external link untouched';
    like   $after, qr{\]\(foo\.html\)},                'relative link untouched';

    chdir $cwd;
};

subtest 'Step D rewrites Ovid.link calls' => sub {
    my $tmproot = Path::Tiny->tempdir;
    $tmproot->child('root')->mkpath;
    $tmproot->child('lib')->mkpath;
    $tmproot->child('bin')->mkpath;
    $tmproot->child('bin/rebuild')->spew('# stub');

    my $fixture = <<~'EOT';
        [% Ovid.link('/articles/about.html', 'About') %]
        [% Ovid.link('/articles/about.html#section', 'About section') %]
        [% Ovid.link('/articles/about.html?q=1', 'About q') %]
        EOT
    $tmproot->child('root/ovid-link.tt')->spew_utf8($fixture);

    chdir $tmproot;
    system( 'git', 'init', '-q' );
    system( 'git', 'config', 'user.email', 't@t' );
    system( 'git', 'config', 'user.name',  't' );
    system( 'git', 'add', '-A' );
    system( 'git', 'commit', '-q', '-m', 'init' );

    my ( $out, $err ) = run_in( $tmproot );
    ok !$err, 'Ovid.link rewrite runs cleanly';

    my $after = $tmproot->child('root/ovid-link.tt')->slurp_utf8;

    like   $after, qr{Ovid\.link\('/articles/about',},         '.html stripped';
    like   $after, qr{Ovid\.link\('/articles/about#section',}, '#anchor preserved';
    like   $after, qr{Ovid\.link\('/articles/about\?q=1',},    '?query preserved';

    chdir $cwd;
};

subtest 'Step E rewrites Ovid.cite calls' => sub {
    my $tmproot = Path::Tiny->tempdir;
    $tmproot->child('root')->mkpath;
    $tmproot->child('lib')->mkpath;
    $tmproot->child('bin')->mkpath;
    $tmproot->child('bin/rebuild')->spew('# stub');

    my $fixture = <<~'EOT';
        [% Ovid.cite('/articles/paper.html', 'Paper') %]
        [% Ovid.cite('/articles/paper.html#section', 'Paper section') %]
        [% Ovid.cite('/articles/paper.html?q=1', 'Paper q') %]
        EOT
    $tmproot->child('root/ovid-cite.tt')->spew_utf8($fixture);

    chdir $tmproot;
    system( 'git', 'init', '-q' );
    system( 'git', 'config', 'user.email', 't@t' );
    system( 'git', 'config', 'user.name',  't' );
    system( 'git', 'add', '-A' );
    system( 'git', 'commit', '-q', '-m', 'init' );

    my ( $out, $err ) = run_in( $tmproot );
    ok !$err, 'Ovid.cite rewrite runs cleanly';

    my $after = $tmproot->child('root/ovid-cite.tt')->slurp_utf8;

    like   $after, qr{Ovid\.cite\('/articles/paper',},         '.html stripped';
    like   $after, qr{Ovid\.cite\('/articles/paper#section',}, '#anchor preserved';
    like   $after, qr{Ovid\.cite\('/articles/paper\?q=1',},    '?query preserved';

    chdir $cwd;
};

subtest 'Steps C, D, and E are idempotent' => sub {
    my $tmproot = Path::Tiny->tempdir;
    $tmproot->child('root')->mkpath;
    $tmproot->child('lib')->mkpath;
    $tmproot->child('bin')->mkpath;
    $tmproot->child('bin/rebuild')->spew('# stub');

    my $fixture = <<~'EOT';
        [Markdown link](/articles/intro.html)
        [% Ovid.link('/articles/about.html', 'About') %]
        [% Ovid.cite('/articles/paper.html', 'Paper') %]
        EOT
    $tmproot->child('root/idem.tt')->spew_utf8($fixture);

    chdir $tmproot;
    system( 'git', 'init', '-q' );
    system( 'git', 'config', 'user.email', 't@t' );
    system( 'git', 'config', 'user.name',  't' );
    system( 'git', 'add', '-A' );
    system( 'git', 'commit', '-q', '-m', 'init' );
    chdir $cwd;

    run_in( $tmproot );
    chdir $tmproot;
    system( 'git', 'add', '-A' );
    system( 'git', 'commit', '-q', '-m', 'first pass' );
    chdir $cwd;

    run_in( $tmproot );
    chdir $tmproot;
    my $diff = `git diff --stat`;
    chdir $cwd;
    is $diff, '', 'second pass produces no further changes (C, D, and E idempotent)';
};

subtest 'rewrite is idempotent' => sub {
    my $tmproot = Path::Tiny->tempdir;
    $tmproot->child('root')->mkpath;
    $tmproot->child('lib')->mkpath;
    $tmproot->child('bin')->mkpath;
    $tmproot->child('bin/rebuild')->spew('# stub');
    $tmproot->child('root/x.tt')->spew('<a href="/blog/foo.html">x</a>');

    chdir $tmproot;
    system( 'git', 'init', '-q' );
    system( 'git', 'config', 'user.email', 't@t' );
    system( 'git', 'config', 'user.name',  't' );
    system( 'git', 'add', '-A' );
    system( 'git', 'commit', '-q', '-m', 'init' );
    chdir $cwd;

    run_in( $tmproot );
    chdir $tmproot;
    system( 'git', 'add', '-A' );
    system( 'git', 'commit', '-q', '-m', 'first pass' );
    chdir $cwd;

    run_in( $tmproot );
    chdir $tmproot;
    my $diff = `git diff --stat`;
    chdir $cwd;
    is $diff, '', 'second pass produces no further changes';
};

subtest '--dry-run does not write' => sub {
    my $tmproot = Path::Tiny->tempdir;
    $tmproot->child('root')->mkpath;
    $tmproot->child('lib')->mkpath;
    $tmproot->child('bin')->mkpath;
    $tmproot->child('bin/rebuild')->spew('# stub');
    $tmproot->child('root/x.tt')->spew('<a href="/blog/foo.html">x</a>');

    chdir $tmproot;
    system( 'git', 'init', '-q' );
    system( 'git', 'config', 'user.email', 't@t' );
    system( 'git', 'config', 'user.name',  't' );
    system( 'git', 'add', '-A' );
    system( 'git', 'commit', '-q', '-m', 'init' );
    chdir $cwd;

    run_in( $tmproot, '--dry-run' );

    my $after = $tmproot->child('root/x.tt')->slurp_utf8;
    like $after, qr{href="/blog/foo\.html"}, '--dry-run did not modify the file';
};

done_testing;
