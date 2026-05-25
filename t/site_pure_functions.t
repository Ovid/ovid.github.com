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

subtest '_html_to_text falls back to <div class="...article..."> when no <article> tag' => sub {
    my $tmp = Path::Tiny->tempfile( SUFFIX => '.html' );
    $tmp->spew_utf8( <<~'HTML' );
        <!DOCTYPE html>
        <html>
        <head><title>Legacy Page</title></head>
        <body>
            <header>Ignored header text</header>
            <div class="row">
                <div class="two columns sidebar">Sidebar links</div>
                <div class="ten columns verticalLine article">
                    <h1>Legacy Heading</h1>
                    <p>Legacy paragraph body.</p>
                    <div class="prevNext">prev next nav</div>
                </div>
            </div>
            <footer>Ignored footer text</footer>
        </body>
        </html>
        HTML

    my ( $title, $text ) = $site->_html_to_text( $tmp->stringify );
    is $title, 'Legacy Page', 'title extracted';
    like $text,   qr/Legacy Heading/,         'heading inside legacy article div included';
    like $text,   qr/Legacy paragraph body\./,'paragraph inside legacy article div included';
    like $text,   qr/prev next nav/,          'nested content inside the article div included';
    unlike $text, qr/Sidebar links/,          'sibling div content excluded';
    unlike $text, qr/Ignored header text/,    'header excluded';
    unlike $text, qr/Ignored footer text/,    'footer excluded';
};

subtest '_html_to_text prefers <article> over <div class="article"> when both present' => sub {
    my $tmp = Path::Tiny->tempfile( SUFFIX => '.html' );
    $tmp->spew_utf8( <<~'HTML' );
        <!DOCTYPE html>
        <html>
        <head><title>Both</title></head>
        <body>
            <div class="article">Should NOT appear (we have a real article tag)</div>
            <article>Real article body.</article>
        </body>
        </html>
        HTML

    my ( $title, $text ) = $site->_html_to_text( $tmp->stringify );
    is $title, 'Both', 'title extracted';
    like   $text, qr/Real article body\./, 'article tag content extracted';
    unlike $text, qr/Should NOT appear/,   'div fallback skipped when article tag present';
};

subtest '_html_to_text skips <script> and <style> bodies inside <article>' => sub {
    my $tmp = Path::Tiny->tempfile( SUFFIX => '.html' );
    $tmp->spew_utf8( <<~'HTML' );
        <!DOCTYPE html>
        <html>
        <head><title>Modern With Script</title></head>
        <body>
            <article>
                <p>The word function appears in prose here.</p>
                <script>
                    function showOverlay(img) { document.getElementById('x'); }
                    const wpm = 250;
                </script>
                <style>.foo { color: red; }</style>
                <p>More real prose after the script.</p>
            </article>
        </body>
        </html>
        HTML

    my ( undef, $text ) = $site->_html_to_text( $tmp->stringify );
    like   $text, qr/word function appears in prose/, 'prose text retained';
    like   $text, qr/More real prose/,                'post-script prose retained';
    unlike $text, qr/showOverlay/,                    'script function name excluded';
    unlike $text, qr/getElementById/,                 'script DOM call excluded';
    unlike $text, qr/const wpm/,                      'script variable excluded';
    unlike $text, qr/color: red/,                     'style rules excluded';
};

subtest '_html_to_text skips <script> and <style> bodies inside legacy article div' => sub {
    my $tmp = Path::Tiny->tempfile( SUFFIX => '.html' );
    $tmp->spew_utf8( <<~'HTML' );
        <!DOCTYPE html>
        <html>
        <head><title>Legacy With Script</title></head>
        <body>
            <div class="ten columns verticalLine article">
                <p>Legacy prose with the word function in it.</p>
                <script>
                    function showOverlay(img) { document.getElementById('x'); }
                    const wpm = 350;
                </script>
                <style>.bar { color: blue; }</style>
                <p>Closing prose.</p>
            </div>
        </body>
        </html>
        HTML

    my ( undef, $text ) = $site->_html_to_text( $tmp->stringify );
    like   $text, qr/Legacy prose with the word function/, 'legacy prose retained';
    like   $text, qr/Closing prose/,                       'post-script prose retained';
    unlike $text, qr/showOverlay/,                         'script function name excluded';
    unlike $text, qr/getElementById/,                      'script DOM call excluded';
    unlike $text, qr/const wpm/,                           'script variable excluded';
    unlike $text, qr/color: blue/,                         'style rules excluded';
};

subtest '_html_to_text returns empty body when neither container present' => sub {
    my $tmp = Path::Tiny->tempfile( SUFFIX => '.html' );
    $tmp->spew_utf8( <<~'HTML' );
        <!DOCTYPE html>
        <html>
        <head><title>Bare</title></head>
        <body><p>Loose content with no recognised container.</p></body>
        </html>
        HTML

    my ( $title, $text ) = $site->_html_to_text( $tmp->stringify );
    is $title, 'Bare', 'title still extracted';
    is $text,  '',     'no body extracted when no container present';
};

subtest '_is_searchable picks content pages and rejects listings/build dirs' => sub {
    # Content pages: top-level pages
    ok $site->_is_searchable('index.html'),         'index.html is content';
    ok $site->_is_searchable('hireme.html'),        'hireme.html is content';
    ok $site->_is_searchable('projects.html'),      'projects.html is content';
    ok $site->_is_searchable('publicspeaking.html'),'publicspeaking.html is content';
    ok $site->_is_searchable('starmap.html'),       'starmap.html is content';
    ok $site->_is_searchable('tau-station.html'),   'tau-station.html is content';
    ok $site->_is_searchable('videos.html'),        'videos.html is content (previously missing)';
    ok $site->_is_searchable('wildagile.html'),     'wildagile.html is content';

    # Content pages: subdirectory content
    ok $site->_is_searchable('articles/foo.html'),       'articles/* is content';
    ok $site->_is_searchable('blog/bar.html'),           'blog/* is content';
    ok $site->_is_searchable('Extraction/index.html'),   'Extraction/ subpage indexed';
    ok $site->_is_searchable('tramp-freighter/index.html'), 'tramp-freighter/ subpage indexed';
    ok $site->_is_searchable('projects/extraction/index.html'), 'projects/extraction/ subpage indexed';

    # Reject: listing/pagination pages
    ok !$site->_is_searchable('articles.html'),     'articles.html (listing) excluded';
    ok !$site->_is_searchable('articles-all.html'), 'articles-all.html (listing) excluded';
    ok !$site->_is_searchable('articles_2.html'),   'articles_2 (paginated) excluded';
    ok !$site->_is_searchable('articles_7.html'),   'articles_7 (paginated) excluded';
    ok !$site->_is_searchable('blog.html'),         'blog.html (listing) excluded';
    ok !$site->_is_searchable('blog-all.html'),     'blog-all.html (listing) excluded';
    ok !$site->_is_searchable('blog_3.html'),       'blog_3 (paginated) excluded';

    # Reject: tag/admin/error pages
    ok !$site->_is_searchable('tags/perl.html'),    'tag pages (listings) excluded';
    ok !$site->_is_searchable('404.html'),          '404 page excluded';
    ok !$site->_is_searchable('editor.html'),       'editor (dev tool) excluded';
    ok !$site->_is_searchable('escape.html'),       'escape (JS game with no prose) excluded';

    # Reject: build / dev / generated / template subtrees
    ok !$site->_is_searchable('tmp/anything.html'),        'tmp/ excluded';
    ok !$site->_is_searchable('root/index.tt'),            'root/ source excluded';
    ok !$site->_is_searchable('include/header.html'),      'include/ fragments excluded';
    ok !$site->_is_searchable('static/js/search/demo.html'),'static/ excluded';
    ok !$site->_is_searchable('wasm_output/demo.html'),    'wasm_output/ excluded';
    ok !$site->_is_searchable('coverage-report/foo.html'), 'coverage report excluded';
    ok !$site->_is_searchable('nytprof/index.html'),       'nytprof excluded';
    ok !$site->_is_searchable('node_modules/x/y.html'),    'node_modules excluded';
    ok !$site->_is_searchable('cover_db/foo.html'),        'cover_db excluded';

    # Reject: git worktree checkouts and node_modules at any depth
    ok !$site->_is_searchable('.worktrees/foo/index.html'),
      '.worktrees/ (sibling checkouts) excluded';
    ok !$site->_is_searchable('.worktrees/foo/blog/bar.html'),
      'nested .worktrees content excluded';
    ok !$site->_is_searchable('tramp-freighter/node_modules/three/foo.html'),
      'nested node_modules excluded';
    ok !$site->_is_searchable('Extraction/node_modules/x/y.html'),
      'nested node_modules under content dir excluded';

    # Reject anything in a dot-directory (eg .git, .worktrees, .cache)
    ok !$site->_is_searchable('.git/foo.html'), '.git/ excluded';

    # Reject build-output dist/ directories at any depth (avoid
    # duplicate-indexing built copies of sibling source pages).
    ok !$site->_is_searchable('tramp-freighter/dist/index.html'),
      'nested dist/ excluded';
    ok !$site->_is_searchable('dist/foo.html'), 'top-level dist/ excluded';
};

done_testing;
