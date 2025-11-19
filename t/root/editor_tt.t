use v5.40;
use Test::Most;
use Path::Tiny;

my $file = path('root/editor.tt');
ok $file->exists, 'Template file exists';

my $content = $file->slurp_utf8;
like $content, qr/fetch\('\/api\/save'/, 'Contains save logic';
like $content, qr/Refresh Preview/, 'Contains refresh button';
like $content, qr/setTimeout\(saveContent, 1000\)/, 'Contains debounce logic';
like $content, qr/id="loading-overlay"/, 'Contains loading overlay';
like $content, qr/Building preview.../, 'Contains loading message';
like $content, qr/id="splitter"/, 'Contains splitter';
like $content, qr/id="theme-toggle"/, 'Contains theme toggle';

done_testing;
