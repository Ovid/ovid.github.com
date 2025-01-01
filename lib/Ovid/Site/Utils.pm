package Ovid::Site::Utils;

use Less::Boilerplate;
use Less::Script ();
use parent 'Exporter';

our @EXPORT_OK = qw(
  use_smart_quotes
  get_image_description
  set_image_description
);

sub use_smart_quotes($text) {
    my $punct = '[[:punct:]]';

    # this is a case where we have a double-quote character embedded
    # between two letters. We can't tell which smart quote that should
    # be, so we encode it and skip it.
    $text =~ s/(\w)"(\w)/$1&quot;$2/smg;

    $text =~ s/(?<!\w)\"($punct|\w)/“$1/smg;    # leading smart quote
    $text =~ s/(\w|$punct)\"/$1”/smg;           # trailing smart quote
    $text =~ s/(\w)'(\w)/$1’$2/smg;             # contractions: don’t
    $text =~ s/(\W)'(\w)/$1‘$2/smg;             # ‘tis the season

    # special-cases of single quote starting a string. We handle it
    # independently to avoid complicating the above regexes
    $text =~ s/^'(\w)/‘$1/;    # ‘tis the season
    return $text;
}

sub get_image_description ($image) {
    my ($description) = Less::Script::dbh()->selectrow_array(
        'SELECT description FROM images WHERE filename = ?',
        { Slice => {} },
        $image
    );
    return $description;
}

sub set_image_description ( $image, $description ) {
    my $sql
      = get_image_description($image)
      ? 'UPDATE images SET description = ? WHERE filename = ?'
      : 'INSERT INTO images (description, filename) VALUES (?, ?)';
    Less::Script::dbh()->do( $sql, {}, $description, $image );
}

1;

__END__

=head1 NAME

Ovid::Site::Utils - Utility functions for building our site.

=head1 FUNCTIONS

=head2 use_smart_quotes

   $text = use_smart_quotes($text);

=head2 get_image_description

   $description = get_image_description($image);

=head2 set_image_description

    set_image_description($image, $description);

=cut
