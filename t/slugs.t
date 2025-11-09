#!/usr/bin/env perl

use Test::Most;
use lib 'lib';
use Less::Script;

my $dbh = dbh;

foreach my $type (qw/article blog/) {
    my $articles = dbh()->selectall_arrayref( <<"SQL", { Slice => {} }, $type );
    SELECT a.slug
      FROM articles a
      JOIN article_types at ON at.article_type_id = a.article_type_id
     WHERE a.available = 1 AND at.type = ?
SQL
    my $dir = article_type($type)->{directory};
    foreach my $article (@$articles) {
        my $slug = $article->{slug};
        my ($filename) = grep { -e $_ } filenames( $dir, $slug );
        if ($filename) {
            pass "$filename exists for $slug";
            is $slug, get_slug_from_file($filename),
              "Actual slug and file slug should match";
        }
        else {
            fail "Cannot find filename for $slug";
        }
    }
}

done_testing;

sub filenames ( $dir, $slug ) {

    # new extensions are now .tt2markdown
    return ( "root/$dir/$slug.tt", "root/$dir/$slug.tt2markdown" );
}

sub get_slug_from_file ($filename) {
    my $template = slurp($filename);
    $template =~ /\s+slug\s+=\s*['"](?<slug>[-a-z0-9]+)['"]/;
    return $+{slug} // '<undef>';
}
