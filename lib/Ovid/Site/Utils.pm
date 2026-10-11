package Ovid::Site::Utils;

use Less::Boilerplate;
use Less::Script ();
use parent 'Exporter';

our @EXPORT_OK = qw(
  use_smart_quotes
  get_image_description
  set_image_description
  human_date
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

my @MONTH = qw(
  January February March April May June
  July August September October November December
);

# '2026-08-08' => '8 August 2026'. Anything that isn't an ISO date passes
# through untouched: a bare $MONTH[$month - 1] on a malformed date wraps
# round the end of the array and silently reports December.
sub human_date ($date) {
    my ( $year, $month, $day ) = ( $date // '' ) =~ /\A(\d{4})-(\d{2})-(\d{2})\z/
      or return $date;
    return $date unless $month >= 1 && $month <= 12;
    return sprintf '%d %s %d', $day, $MONTH[ $month - 1 ], $year;
}

1;

__END__

=head1 NAME

Ovid::Site::Utils - Utility functions for building our site.

=head1 SYNOPSIS

    use Ovid::Site::Utils qw(
      use_smart_quotes
      get_image_description
      set_image_description
    );

    my $pretty = use_smart_quotes($raw_text);

    my $desc = get_image_description('photo.jpg');
    set_image_description('photo.jpg', 'A sunset over the ocean.');

=head1 DESCRIPTION

Exports utility functions used across the site build pipeline. Provides
typographic smart-quote conversion and accessors for the image description
table in the SQLite database.

=head1 FUNCTIONS

=head2 use_smart_quotes

   $text = use_smart_quotes($text);

=head2 get_image_description

   $description = get_image_description($image);

=head2 set_image_description

    set_image_description($image, $description);

=head2 human_date

    $spoken = human_date('2026-08-08');    # '8 August 2026'

Spells out an ISO C<YYYY-MM-DD> date. Anything else, including an
out-of-range month, is returned unchanged rather than guessed at.

=cut
