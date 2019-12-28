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

has db => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
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
    return dbh( $self->db )->selectcol_arrayref( $sql, {}, $self->type )->[0];
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
    my $total = $self->total;
    return if $self->_current_offset >= $self->total;
    my $limit  = $self->items_per_page;
    my $offset = $self->_current_offset;
    my $order  = $self->oldest_first ? 'ASC' : 'DESC';
    my $records =
      dbh( $self->db )->selectall_arrayref( <<"SQL", { Slice => {} }, $self->type );
    SELECT a.title,
           a.slug,
           at.type,
           a.sort_order
      FROM articles a
      JOIN article_types at ON at.article_type_id = a.article_type_id
     WHERE at.type = ?
  ORDER BY sort_order $order LIMIT $limit OFFSET $offset;
SQL
    $self->_set_page_number( $self->current_page_number + 1 ) if @$records;
    $self->_current_offset( $self->_current_offset + $self->items_per_page );
    return $records;
}

__PACKAGE__->meta->make_immutable;
