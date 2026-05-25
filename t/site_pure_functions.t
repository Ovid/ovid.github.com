#!/usr/bin/env perl

use Test::Most;
use lib 'lib';
use Less::Boilerplate;
use Test2::Plugin::UTF8;
use Path::Tiny qw(path);
use Ovid::Site;

my $site = Ovid::Site->new;

subtest '_clean_text strips and collapses whitespace' => sub {
    is $site->_clean_text("hello"),         'hello',       'no whitespace passes through';
    is $site->_clean_text("  hello  "),     'hello',       'leading/trailing stripped';
    is $site->_clean_text("hello   world"), 'hello world', 'internal runs collapsed';
    is $site->_clean_text("\thello\nworld\t"), 'hello world', 'tabs and newlines treated as whitespace';
    is $site->_clean_text(''), '', 'empty string in, empty string out';
};

subtest '_get_sitemap_priority assigns priorities by filename and parent' => sub {
    is $site->_get_sitemap_priority( path('index.html') ),       1.0, 'homepage';
    is $site->_get_sitemap_priority( path('articles.html') ),    0.8, 'main section';
    is $site->_get_sitemap_priority( path('blog.html') ),        0.8, 'main section (blog)';
    is $site->_get_sitemap_priority( path('videos.html') ),      0.8, 'main section (videos)';
    is $site->_get_sitemap_priority( path('articles_2.html') ),  0.6, 'pagination page 2';
    is $site->_get_sitemap_priority( path('blog_3.html') ),      0.5, 'pagination page 3';
    is $site->_get_sitemap_priority( path('articles_7.html') ),  0.4, 'pagination beyond page 3';
    is $site->_get_sitemap_priority( path('articles/foo.html') ),0.6, 'article in subdirectory';
    is $site->_get_sitemap_priority( path('blog/bar.html') ),    0.6, 'blog post in subdirectory';
    is $site->_get_sitemap_priority( path('about.html') ),       0.7, 'other top-level html';
    is $site->_get_sitemap_priority( path('static/foo.css') ),   0.5, 'non-html default';
};

subtest '_get_change_frequency assigns frequencies by filename' => sub {
    is $site->_get_change_frequency( path('index.html') ),       'monthly', 'homepage monthly';
    is $site->_get_change_frequency( path('articles.html') ),    'weekly',  'articles weekly';
    is $site->_get_change_frequency( path('blog.html') ),        'weekly',  'blog weekly';
    is $site->_get_change_frequency( path('videos.html') ),      'yearly',  'videos yearly';
    is $site->_get_change_frequency( path('articles_2.html') ),  'monthly', 'paginated pages monthly';
    is $site->_get_change_frequency( path('blog_5.html') ),      'monthly', 'paginated pages monthly';
    is $site->_get_change_frequency( path('articles/foo.html') ),'yearly',  'individual article yearly';
};

subtest '_article_page returns directory or directory_N' => sub {
    my $article_type = { directory => 'blog', name => 'Blog Entries' };
    is $site->_article_page( 1, $article_type ), 'blog',   'page 1 returns directory';
    is $site->_article_page( 2, $article_type ), 'blog_2', 'page N returns directory_N';
    is $site->_article_page( 7, $article_type ), 'blog_7', 'page 7 returns directory_7';
};

subtest '_get_article_list renders an HTML list of articles' => sub {
    my $article_type = { directory => 'blog', name => 'Blog Entries' };
    my $records = [
        { slug => 'first',  title => 'First Post'  },
        { slug => 'second', title => 'Second Post' },
    ];
    my $html = $site->_get_article_list( $records, $article_type );
    like   $html, qr{<ul id="articles">},                                'wraps in <ul id="articles">';
    like   $html, qr{<a href="/blog/first">First Post</a>},              'first entry rendered';
    like   $html, qr{<a href="/blog/second">Second Post</a>},            'second entry rendered';
    like   $html, qr{</ul>\z},                                           'closes with </ul>';

    my $empty = $site->_get_article_list( [], $article_type );
    is $empty, qq{<ul id="articles">\n</ul>}, 'empty records produce empty list';
};

subtest '_get_pagination produces nav HTML or empty string' => sub {
    my $article_type = { directory => 'blog', name => 'Blog Entries' };

    is $site->_get_pagination( 1, 1, $article_type ), '',
        'single page total returns empty string';

    my $page1 = $site->_get_pagination( 3, 1, $article_type );
    like $page1, qr{<nav class="pagination">},               'opens nav';
    like $page1, qr{<span class="inactive">&laquo;</span>},  'prev is inactive on page 1';
    like $page1, qr{<a class="active" href="/blog">1</a>},   'page 1 marked active';
    like $page1, qr{<a  href="/blog_2">2</a>},               'page 2 link present';
    like $page1, qr{<a  href="/blog_3">3</a>},               'page 3 link present';
    like $page1, qr{<a href="/blog_2">&raquo;</a>},          'next links to page 2';
    like $page1, qr{</nav>\z},                                'closes nav';

    my $page2 = $site->_get_pagination( 3, 2, $article_type );
    like $page2, qr{<a href="/blog">&laquo;</a>},            'prev links back to page 1';
    like $page2, qr{<a class="active" href="/blog_2">2</a>}, 'page 2 marked active';
    like $page2, qr{<a href="/blog_3">&raquo;</a>},          'next links to page 3';

    my $page3 = $site->_get_pagination( 3, 3, $article_type );
    like $page3, qr{<a href="/blog_2">&laquo;</a>},          'prev links to page 2';
    like $page3, qr{<a class="active" href="/blog_3">3</a>}, 'page 3 marked active';
    like $page3, qr{<span class="inactive">&raquo;</span>},  'next is inactive on last page';
};

subtest '_get_pagination emits extensionless hrefs' => sub {
    my $type = { directory => 'articles', name => 'Articles' };
    my $html = $site->_get_pagination( 3, 2, $type );
    unlike $html, qr/\.html"/, 'no .html" appears in paginator anchors';
    like $html, qr{href="/articles"},          'page-1 anchor extensionless';
    like $html, qr{href="/articles_3"},        'last-page anchor extensionless';
    like $html, qr{href="/articles_2"},        'current-page anchor extensionless';
};

subtest '_get_article_list emits extensionless hrefs' => sub {
    my $type    = { directory => 'blog', name => 'Blog' };
    my $records = [
        { slug => 'foo', title => 'Foo' },
        { slug => 'bar', title => 'Bar' },
    ];
    my $html = $site->_get_article_list( $records, $type );
    unlike $html, qr/\.html"/, 'no .html" appears in article list';
    like $html, qr{href="/blog/foo">Foo}, 'foo link extensionless';
    like $html, qr{href="/blog/bar">Bar}, 'bar link extensionless';
};

subtest '_sitemap_loc maps on-disk filename to public URL' => sub {
    my $base = 'https://curtispoe.org';
    is $site->_sitemap_loc( $base, 'index.html' ),       "$base/",                'index.html → /';
    is $site->_sitemap_loc( $base, 'articles.html' ),    "$base/articles",        'top-level → /articles';
    is $site->_sitemap_loc( $base, 'blog/foo.html' ),    "$base/blog/foo",        'nested → /blog/foo';
    is $site->_sitemap_loc( $base, 'articles_2.html' ),  "$base/articles_2",      'pagination → /articles_2';
};

subtest '_tinysearch_url_for_file builds extensionless click-through URLs' => sub {
    is $site->_tinysearch_url_for_file('index.html'),            '/',               'index.html collapses to /';
    is $site->_tinysearch_url_for_file('blog/foo.html'),         '/blog/foo',       'nested html';
    is $site->_tinysearch_url_for_file('articles/bar.html'),     '/articles/bar',   'articles html';
    is $site->_tinysearch_url_for_file('/already/leading.html'), '/already/leading','leading slash preserved, .html stripped';
};

subtest '_html_to_text extracts title and article text' => sub {
    my $tmp = Path::Tiny->tempfile( SUFFIX => '.html' );
    $tmp->spew_utf8( <<~'HTML' );
        <!DOCTYPE html>
        <html>
        <head><title>The Title</title></head>
        <body>
            <header>Ignored header text</header>
            <article>
                <h1>Heading</h1>
                <p>First paragraph.</p>
                <p>Second   paragraph.</p>
            </article>
            <footer>Ignored footer text</footer>
        </body>
        </html>
        HTML

    my ( $title, $text ) = $site->_html_to_text( $tmp->stringify );
    is $title, 'The Title', 'title extracted from <title>';
    like $text,   qr/Heading/,           'heading text included';
    like $text,   qr/First paragraph\./, 'first paragraph included';
    like $text,   qr/Second paragraph\./,'whitespace collapsed in second paragraph';
    unlike $text, qr/Ignored header text/,'header text excluded (outside article)';
    unlike $text, qr/Ignored footer text/,'footer text excluded (outside article)';
};

done_testing;
