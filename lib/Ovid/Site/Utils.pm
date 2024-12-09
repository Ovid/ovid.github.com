package Ovid::Site::Utils;

use Less::Boilerplate;
use parent 'Exporter';

our @EXPORT_OK = qw(
  use_smart_quotes
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

1;

__END__

=head1 NAME

Ovid::Site::Utils - Utility functions for building our site.

=head1 FUNCTIONS

=head2 use_smart_quotes

   $text = use_smart_quotes($text);
