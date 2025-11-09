package Less::Pager;

use Moose;
use namespace::autoclean;
use Moose::Util::TypeConstraints;
use Less::Script;

enum ArticleType => [qw/article blog/];

has items_per_page => (
    is      => 'ro',
    isa     => 'Int',
    default => sub { 10 },
);

has total => (
    is      => 'ro',
    isa     => 'Int',
    lazy    => 1,
    builder => '_build_total',
);

has oldest_first => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has type => (
    is       => 'ro',
    isa      => 'ArticleType',
    required => 1,
);

sub _build_total($self) {
    my $sql = <<'SQL';
    SELECT COUNT(*)
      FROM articles a
      JOIN article_types at ON at.article_type_id = a.article_type_id
     WHERE at.type = ?
SQL
    return dbh()->selectcol_arrayref( $sql, {}, $self->type )->[0];
}

has _current_offset => (
    is      => 'rw',
    isa     => 'Int',
    lazy    => 1,
    default => sub { 0 },
);

has current_page_number => (
    is      => 'ro',
    isa     => 'Int',
    writer  => '_set_page_number',
    default => sub { 0 },
);

sub total_pages ($self) {
    my $pages = $self->total / $self->items_per_page;
    return $pages == int($pages) ? $pages : int($pages) + 1;
}

# TODO (Coverage Improvement 001): Verify template usage before removal
# Static analysis shows no Perl code calls. May be used for pagination in templates.
# Note: Similar to next_post() but different signature. Verify if legacy code.
# See: specs/001-test-coverage-improvement/unused-code-decisions.md
sub next ($self) {
    return if $self->_current_offset >= $self->total;
    my $limit  = $self->items_per_page;
    my $offset = $self->_current_offset;
    my $order  = $self->oldest_first ? 'ASC' : 'DESC';
    my $records =
      dbh()->selectall_arrayref( <<"SQL", { Slice => {} }, $self->type );
    SELECT a.title,
           a.slug,
           a.description,
           at.type,
           a.sort_order
      FROM articles a
      JOIN article_types at ON at.article_type_id = a.article_type_id
     WHERE a.available = 1 AND at.type = ?
  ORDER BY sort_order $order LIMIT $limit OFFSET $offset;
SQL
    $self->_set_page_number( $self->current_page_number + 1 ) if @$records;
    $self->_current_offset( $self->_current_offset + $self->items_per_page );
    return $records;
}

sub prev_post ( $self, $directory, $slug ) {
    return $self->_get_prev_next( -1, $directory, $slug );
}

sub next_post ( $self, $directory, $slug ) {
    return $self->_get_prev_next( 1, $directory, $slug );
}

sub _get_prev_next ( $self, $direction, $directory, $slug ) {
    my $result = dbh()->selectall_arrayref( <<'SQL', {}, $directory, $slug );
    SELECT a.sort_order, a.article_type_id
      FROM articles a
      JOIN article_types at ON at.article_type_id = a.article_type_id
     WHERE at.directory = ?
       AND a.slug       = ?
SQL
    return unless $result->[0];
    my ( $sort_order, $article_type_id ) = $result->[0]->@*;

    my $func     = $direction < 0 ? 'MAX' : 'MIN';
    my $operator = $direction < 0 ? '<'   : '>';
    $result =
      dbh()
      ->selectall_arrayref(
        <<"SQL", { Slice => {} }, $article_type_id, $sort_order ) or return;
    SELECT a.title,
           a.slug,
           a.description,
           at.type,
           a.sort_order
      FROM articles a
      JOIN article_types at ON at.article_type_id = a.article_type_id
     WHERE a.available = 1
       AND a.article_type_id = ?
       AND sort_order = (SELECT $func(sort_order)
                           FROM articles
                          WHERE sort_order      $operator ?
                            AND article_type_id = a.article_type_id
                            AND available       = 1
                        );
SQL
    return $result->[0];
}

sub this_post ( $self, $directory, $slug ) {
    my $result =
      dbh()
      ->selectall_arrayref(
        <<"SQL", { Slice => {} }, $directory, $slug ) or return;
    SELECT a.title,
           a.slug,
           a.description,
           at.type,
           a.sort_order
      FROM articles a
      JOIN article_types at ON at.article_type_id = a.article_type_id
     WHERE a.available = 1
       AND at.directory = ?
       AND a.slug = ?
SQL
    return $result->[0];
}

# TODO (Coverage Improvement 001): Verify template usage before removal
# Static analysis shows no Perl code calls. May be iterator method for templates.
# Could be used to get all articles without pagination.
# See: specs/001-test-coverage-improvement/unused-code-decisions.md
sub all ($self) {
    my $order = $self->oldest_first ? 'ASC' : 'DESC';
    return dbh()->selectall_arrayref( <<"SQL", { Slice => {} }, $self->type );
    SELECT a.title,
           a.slug,
           a.description,
           at.type,
           a.sort_order
      FROM articles a
      JOIN article_types at ON at.article_type_id = a.article_type_id
     WHERE a.available = 1 AND at.type = ?
  ORDER BY sort_order $order;
SQL
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Less::Pager - Pagination for articles and blog posts

=head1 SYNOPSIS

    my $pager = Less::Pager->new(
        type           => 'article',
        items_per_page => 10,
    );

    my $records = $pager->next;

=head1 DESCRIPTION

This module provides a way to paginate through articles and blog posts.

=head1 ATTRIBUTES

=head2 items_per_page

The number of items to display per page.

=head2 total

The total number of items.

=head2 oldest_first

Whether to display the oldest items first.

=head2 type

The type of article to display. Values are C<article> or C<blog>.

=head2 current_page_number

The current page number.

=head1 METHODS

=head2 total_pages

Returns the total number of pages.

=head2 next

Returns the next set of records.

=head2 prev_post

Returns the previous post.

=head2 next_post

Returns the next post.

=head2 this_post

Returns the current post.

=cut
