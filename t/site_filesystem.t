#!/usr/bin/env perl

use Test::Most;
use lib 'lib';
use lib 't/lib';
use Less::Boilerplate;
use Test2::Plugin::UTF8;
use Path::Tiny qw(path);
use Cwd        qw(getcwd);
use Test::MockModule;
use JSON::MaybeXS qw(decode_json);
use TestHelper::Site qw(setup_tempdir_site);

# The config() function is imported by each module at compile time, so we must
# mock the per-package copies that are already in place.  The modules that
# call config() during the code paths exercised below are Ovid::Site and
# Ovid::Template::File.

my $fake_config = sub {
    return {
        tagmap_file => 'tagmap.json',
        tagmap      => {
            perl        => 'Perl',
            programming => 'Software',
        },
    };
};

my $site_mock = Test::MockModule->new('Ovid::Site');
$site_mock->mock( 'config', $fake_config );

my $file_mock = Test::MockModule->new('Ovid::Template::File');
$file_mock->mock( 'config', $fake_config );

my $cwd = getcwd();
END { chdir $cwd }

sub _with_site {
    my ($code) = @_;
    my ( $site, $tempdir ) = setup_tempdir_site();
    eval { $code->( $site, $tempdir ); 1 } or do {
        my $err = $@;
        chdir $cwd;
        die $err;
    };
    chdir $cwd;
}

subtest '_set_files populates _files with non-swap files in a directory' => sub {
    _with_site sub {
        my ( $site, $tempdir ) = @_;
        $tempdir->child('root/include/a.tt')->spew('a');
        $tempdir->child('root/include/b.tt')->spew('b');
        $tempdir->child('root/include/.foo.swp')->spew('vim swap');
        $tempdir->child('root/include/.DS_Store')->spew('mac junk');

        $site->_set_files('root/include');
        my @files = sort $site->_files->@*;
        is scalar @files, 2, 'two files collected';
        like $files[0], qr{root/include/a\.tt$}, 'a.tt included';
        like $files[1], qr{root/include/b\.tt$}, 'b.tt included';
    };
};

subtest '_clean_tmp_directory removes the tmp directory' => sub {
    _with_site sub {
        my ( $site, $tempdir ) = @_;
        $tempdir->child('tmp')->mkpath;
        $tempdir->child('tmp/file.txt')->spew('content');
        ok -d $tempdir->child('tmp'), 'tmp exists before';

        $site->_clean_tmp_directory;
        ok !-d $tempdir->child('tmp'), 'tmp removed after';
    };
};

subtest '_copy_to_tmp copies non-tt files from static dirs verbatim' => sub {
    _with_site sub {
        my ( $site, $tempdir ) = @_;
        $tempdir->child('root/static/css')->mkpath;
        $tempdir->child('root/static/css/main.css')->spew('body { color: red; }');

        my $dest = $site->_copy_to_tmp('root/static/css/main.css');
        like $dest, qr{tmp/static/css/main\.css$}, 'returned tmp path';
        is $tempdir->child('tmp/static/css/main.css')->slurp,
           'body { color: red; }',
           'file contents copied unchanged';
    };
};

subtest '_preprocess_files cleans tmp, processes files, and sets _tagmap' => sub {
    _with_site sub {
        my ( $site, $tempdir ) = @_;
        $tempdir->child('root/include/x.tt')->spew('[% PERL %]print 42;[% END %]');
        $tempdir->child('tmp')->mkpath;
        $tempdir->child('tmp/stale.txt')->spew('left over from a previous build');

        $site->_preprocess_files('root/include');

        ok !-e $tempdir->child('tmp/stale.txt'), 'stale tmp content cleaned';
        ok  -e $tempdir->child('tmp/include/x.tt'), 'tt file copied through';
        is_deeply $site->_tagmap, {}, 'no tags in this template, empty tagmap';
    };
};

subtest '_write_tag_templates writes a stub for each configured tag' => sub {
    _with_site sub {
        my ( $site, $tempdir ) = @_;
        $site->_write_tag_templates;

        for my $tag (qw/ perl programming /) {
            my $f = $tempdir->child("root/tags/$tag.tt2markdown");
            ok -e $f, "$tag tag template exists";
            my $content = $f->slurp;
            like $content, qr/title = 'Tags: /, "title key present in $tag";
            like $content, qr{INCLUDE include/tags\.tt}, "INCLUDE present in $tag";
            like $content, qr/slug\s+=\s+'$tag'/, "slug key matches tag in $tag";
        }
    };
};

subtest '_write_tagmap serializes _tagmap to the configured file as JSON' => sub {
    _with_site sub {
        my ( $site, $tempdir ) = @_;
        $site->_tagmap({
            perl => {
                name  => 'Perl',
                files => [ 'b.html', 'a.html' ],   # intentionally unsorted
            },
            __ALL__ => { name => 'All', files => [ 'a.html', 'b.html' ] },
        });

        $site->_write_tagmap;
        my $tagmap_json = $tempdir->child('tagmap.json');
        ok -e $tagmap_json, 'tagmap.json written';
        my $data = decode_json( $tagmap_json->slurp );
        is_deeply $data->{perl}{files}, [ 'a.html', 'b.html' ],
            'files sorted for non-__ALL__ tag';
        is_deeply $data->{__ALL__}{files}, [ 'a.html', 'b.html' ],
            '__ALL__ tag passes through unsorted';
    };
};

subtest '_write_sitemap writes sitemap.xml with urlset entries' => sub {
    _with_site sub {
        my ( $site, $tempdir ) = @_;
        $tempdir->child('index.html')->spew('<html></html>');
        $tempdir->child('articles')->mkpath;
        $tempdir->child('articles/foo.html')->spew('<html></html>');

        $site->_write_sitemap;
        my $sitemap = $tempdir->child('sitemap.xml');
        ok -e $sitemap, 'sitemap.xml written';
        my $xml = $sitemap->slurp_utf8;
        like $xml, qr{<\?xml version="1\.0" encoding="UTF-8"\?>}, 'xml declaration';
        like $xml, qr{<urlset xmlns="http://www\.sitemaps\.org/schemas/sitemap/0\.9">}, 'urlset open';
        like $xml, qr{<loc>https://curtispoe\.org/</loc>}, 'index.html entry collapsed to /';
        like $xml, qr{<loc>https://curtispoe\.org/articles/foo</loc>}, 'articles/foo extensionless entry';
        like $xml, qr{<priority>(?:1\.0|1)</priority>},   'priority assigned for index';
        like $xml, qr{<changefreq>monthly</changefreq>}, 'changefreq assigned for index';
        like $xml, qr{</urlset>}, 'urlset close';
    };
};

done_testing;
