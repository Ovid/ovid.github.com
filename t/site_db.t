#!/usr/bin/env perl

use Test::Most;
use lib 'lib';
use lib 't/lib';
use Less::Boilerplate;
use Test2::Plugin::UTF8;
use DBI;
use Ovid::Site;

subtest 'Ovid::Site accepts an injected dbh attribute' => sub {
    my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', { RaiseError => 1 });
    my $site = Ovid::Site->new( dbh => $dbh );
    is $site->dbh, $dbh, 'dbh accessor returns the injected handle';
};

use Cwd qw(getcwd);
use Path::Tiny qw(path);
use XML::RSS;
use TestHelper::Site qw(make_test_dbh);

my $cwd = getcwd();
END { chdir $cwd }

subtest '_rebuild_rss_feeds writes blog.rss and article.rss from the dbh' => sub {
    my $dbh     = make_test_dbh();
    my $tempdir = Path::Tiny->tempdir;
    chdir $tempdir;

    my $site = Ovid::Site->new( dbh => $dbh );
    $site->_rebuild_rss_feeds;

    ok -e 'blog.rss',    'blog.rss written';
    ok -e 'article.rss', 'article.rss written';

    my $rss = XML::RSS->new;
    $rss->parsefile('blog.rss');
    is $rss->channel('title'), 'Personal blog posts', 'blog channel title';
    my $blog_items = $rss->{items};
    is scalar @$blog_items, 1, 'one available blog item (unavailable filtered out)';
    is $blog_items->[0]{title}, 'Test Blog Post', 'blog item title';
    like $blog_items->[0]{link}, qr{/blog/test-blog-post$}, 'blog item link is extensionless';

    $rss = XML::RSS->new;
    $rss->parsefile('article.rss');
    is scalar @{ $rss->{items} }, 1, 'one article';
    is $rss->{items}[0]{title}, 'Test Article', 'article title';

    chdir $cwd;
};

subtest '_rebuild_rss_feeds emits extensionless links and non-permalink guids' => sub {
    my $dbh     = make_test_dbh();
    my $tempdir = Path::Tiny->tempdir;
    chdir $tempdir;

    my $site = Ovid::Site->new( dbh => $dbh );
    $site->_rebuild_rss_feeds;

    for my $rss_file (qw/blog.rss article.rss/) {
        next unless -e $rss_file;
        my $rss = XML::RSS->new;
        $rss->parsefile($rss_file);

        for my $item ( $rss->{items}->@* ) {
            unlike $item->{link}, qr/\.html(?:[?#]|$)/,
                "$rss_file item link is extensionless: $item->{link}";

            my $body      = path($rss_file)->slurp_utf8;
            my $guid_node = $item->{guid};
            if ( ref $guid_node eq 'HASH' ) {
                is $guid_node->{isPermaLink}, 'false',
                    "$rss_file item guid is marked isPermaLink=false";
            }
            else {
                like $body,
                    qr{<guid\s+isPermaLink="false">},
                    "$rss_file raw guid carries isPermaLink=\"false\"";
            }
        }
    }

    chdir $cwd;
};

subtest '_article_type_lookup returns the row for a known type' => sub {
    my $dbh  = make_test_dbh();
    my $site = Ovid::Site->new( dbh => $dbh );

    my $row = $site->_article_type_lookup('blog');
    is_deeply [ sort keys %$row ], [ 'directory', 'name', 'type' ],
        'returns hashref with directory, name, type keys';
    is $row->{type}, 'blog', 'type matches input';
};

subtest '_article_type_lookup croaks for an unknown type' => sub {
    my $dbh  = make_test_dbh();
    my $site = Ovid::Site->new( dbh => $dbh );

    throws_ok { $site->_article_type_lookup('nonexistent') }
        qr/Could not fetch article_type information for 'nonexistent'/,
        'croak message includes the bad type';
};

done_testing;
