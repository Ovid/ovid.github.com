#!/usr/bin/env perl

use Test::Most;
use Path::Tiny;
use IPC::Run3;
use JSON::MaybeXS qw(decode_json);

my $js_file = path('static/dev-tools.js');

ok $js_file->exists, 'dev-tools.js exists';

my $content = $js_file->slurp_utf8;

like $content, qr/window\.DEV_MODE/,
    'Checks for DEV_MODE flag';

like $content, qr/createEditButton/,
    'Contains createEditButton function';

like $content, qr/urlToSourceFile/,
    'Contains urlToSourceFile function';

like $content, qr{/api/launch-editor},
    'Makes API call to launch-editor endpoint';

like $content, qr/addEventListener.*DOMContentLoaded/,
    'Waits for DOM ready';

# Behavioral check: load the file in Node and exercise urlToSourceFile
# against the URL shapes bin/review actually serves. A pure source grep
# would have missed the trailing-slash bug fixed in this branch.
SKIP: {
    my $node = `command -v node 2>/dev/null`;
    chomp $node;
    skip 'node not available', 1 unless $node;

    my @cases = (
        [ 'http://127.0.0.1:7007/',                     'root/index.tt' ],
        [ 'http://127.0.0.1:7007/blog',                 'root/blog.tt' ],
        [ 'http://127.0.0.1:7007/blog.html',            'root/blog.tt' ],
        [ 'http://127.0.0.1:7007/blog/some-post',       'root/blog/some-post.tt' ],
        [ 'http://127.0.0.1:7007/blog/some-post.html',  'root/blog/some-post.tt' ],
        [ 'http://127.0.0.1:7007/projects/extraction',  'root/projects/extraction.tt' ],
        [ 'http://127.0.0.1:7007/projects/extraction/', 'root/projects/extraction/index.tt' ],
        [ 'http://127.0.0.1:7007/projects/extraction/index.html',
                                                        'root/projects/extraction/index.tt' ],
        [ 'http://127.0.0.1:7007/paad/tramp-freighter/',
                                                        'root/paad/tramp-freighter/index.tt' ],
    );

    my $script = <<~'JS';
        const { urlToSourceFile } = require('./static/dev-tools.js');
        const cases = JSON.parse(process.argv[1]);
        const out = cases.map(([url]) => urlToSourceFile(url));
        process.stdout.write(JSON.stringify(out));
        JS

    my $payload = JSON::MaybeXS->new->encode( [ map { [ $_->[0] ] } @cases ] );
    my $stdout  = '';
    my $stderr  = '';
    run3 [ $node, '-e', $script, $payload ], \undef, \$stdout, \$stderr;
    is $?, 0, "node ran cleanly (stderr: $stderr)" or skip 'node failed', 1;

    my $got = decode_json($stdout);
    for my $i ( 0 .. $#cases ) {
        is $got->[$i], $cases[$i][1],
            "urlToSourceFile($cases[$i][0]) → $cases[$i][1]";
    }
}

done_testing;
