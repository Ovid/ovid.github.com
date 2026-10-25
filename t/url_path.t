#!/usr/bin/env perl

use Test::Most;
use lib 'lib';
use Less::Boilerplate;
use Path::Tiny;
use Ovid::Util::URLPath qw(url_to_file);

my $root = Path::Tiny->tempdir->realpath;
$root->child($_)->touchpath
  for qw(index.html blog.html blog/post.html tags/trench.html projects/extraction/index.html static/css/main.css);

my $outside = Path::Tiny->tempdir->realpath;
$outside->child('secret.html')->touchpath;
symlink $outside->child('secret.html'), $root->child('escape.html') or die "Cannot symlink: $!";

sub resolves_to ( $url, $expected ) {
    my ( $file, $status ) = url_to_file( $root, split m{/}, $url, -1 );
    is $status,                           200,       "'$url' should be found";
    is $file->relative($root)->stringify, $expected, "... and served from '$expected'";
}

sub fails_with ( $url, $expected ) {
    my ( undef, $status ) = url_to_file( $root, split m{/}, $url, -1 );
    is $status, $expected, "'$url' should return $expected";
}

subtest 'URLs map to generated files' => sub {
    resolves_to '',                     'index.html';
    resolves_to 'tags/trench',          'tags/trench.html';
    resolves_to 'tags/trench.html',     'tags/trench.html';
    resolves_to 'blog',                 'blog.html';
    resolves_to 'projects/extraction',  'projects/extraction/index.html';
    resolves_to 'projects/extraction/', 'projects/extraction/index.html';
    resolves_to 'static/css/main.css',  'static/css/main.css';
};

subtest 'Missing and forbidden paths' => sub {
    fails_with 'tags/nope',  404;
    fails_with 'nope.css',   404;
    fails_with '.git/HEAD',  403;
    fails_with 'blog/../db', 403;
    fails_with 'escape',     403;
};

done_testing;
