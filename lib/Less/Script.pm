package Less::Script;

use Less::Boilerplate;
use Getopt::Long;
use Import::Into;
use Text::Unidecode;
use String::Util 'trim';
use DBI;
use autodie ':all';
use base qw(Exporter);

our @EXPORT = qw(
  article_type
  article
  make_slug
  splat
  slurp
  dbh
  trim
);

sub import ( $class, @exports ) {
    if (@exports) {
        $class->export_to_level( 1, $class, @exports );
    }
    else {
        $class->export_to_level(1);
    }
    Less::Boilerplate->import::into(1);
    Getopt::Long->import::into(1);
}

=head1 NAME

Less::Script - Common imports and utilities for CLI scripts

=head1 SYNOPSIS

    use Less::Script;

    my $slug = make_slug('My Article Title');
    my $type = article_type('blog');
    my $dbh  = dbh();

    my $text = slurp('input.txt');
    splat('output.txt', $text);

=head1 DESCRIPTION

C<Less::Script> is a convenience module for CLI scripts in the site build
toolchain. Importing it automatically enables L<Less::Boilerplate> (which
activates modern Perl features) and L<Getopt::Long>. It also exports several
utility functions for file I/O, slug generation, and database access.

=head1 METHODS

=head2 C<article_type>

    my $type = article_type('blog');
    say $type->{name};
    say $type->{directory};

=cut

sub article_type ($type) {
    my $article_type = dbh()->selectall_arrayref( <<'SQL', { Slice => {} }, $type )->[0];
    SELECT name, type, directory
      FROM article_types
     WHERE type = ?
SQL
    unless ( $article_type && keys $article_type->%* ) {
        croak("Could not fetch article_type information for '$type'");
    }
    return $article_type;
}

=head2 C<slurp>

    my $contents = slurp($filename);

Read contents of C<$filename> into a variable.

=cut

sub slurp($filename) {
    open my $fh, '<:encoding(UTF-8)', $filename;
    my $contents = do { local $/; <$fh> };
    return $contents;
}

=head2 C<splat>

    splat($filename, $contents);

Write C<$contents> to C<filename>.

=cut

sub splat ( $filename, $contents ) {
    open my $fh, '>:encoding(UTF-8)', $filename;
    print {$fh} $contents;
}

=head2 C<make_slug>

    my $slug = make_slug($name);

Creates a URI-friendly "slug" from text.

=cut

sub make_slug ($name) {

    # XXX bugs waiting to happen
    $name = trim( lc( unidecode($name) ) );
    $name =~ s/\s+/_/g;
    $name =~ tr/-/_/;
    $name =~ s/__*/_/g;
    $name =~ s/\W//g;
    $name =~ tr/_/-/;
    $name =~ s/--/-/g;
    return $name;
}

=head2 C<dbh>

    my $dbh = dbh;

Fetch a database handle.

=cut

sub dbh () {
    state $dbh = DBI->connect( "dbi:SQLite:dbname=db/ovid.db", "", "" )
      or croak("Could not find database handle: $DBI::errstr");
    return $dbh;
}

1;
