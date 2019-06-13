package Less::Pager;

use Moose;
use Less::Script;
use namespace::autoclean;

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

sub _build_total($self) {
    return dbh( $self->db )
      ->selectcol_arrayref('SELECT COUNT(*) FROM articles')->[0];
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

sub next ($self) {
    my $total = $self->total;
    return if $self->_current_offset >= $self->total;
    my $limit  = $self->items_per_page;
    my $offset = $self->_current_offset;
    my $order  = $self->oldest_first ? 'ASC' : 'DESC';
    my $records =
      dbh( $self->db )->selectall_arrayref( <<"SQL", { Slice => {} } );
    SELECT title, slug, directory, created
      FROM articles
  ORDER BY created $order LIMIT $limit OFFSET $offset;
SQL
    $self->_set_page_number( $self->current_page_number + 1 ) if @$records;
    $self->_current_offset( $self->_current_offset + $self->items_per_page );
    return $records;
}

__PACKAGE__->meta->make_immutable;
