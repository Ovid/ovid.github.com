#!/usr/bin/env perl

use Test::Most;
use Path::Tiny;

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

done_testing;
