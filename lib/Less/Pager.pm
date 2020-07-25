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

__PACKAGE__->meta->make_immutable;
