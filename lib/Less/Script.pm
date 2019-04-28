package Less::Script;

use Less::Boilerplate;
use Getopt::Long;
use Import::Into;
use Text::Unidecode;
use String::Util 'trim';
use autodie ':all';
use base qw(Exporter);

our @EXPORT = qw(
  make_slug
  splat
  slurp
);

sub import ( $class, %arg_for ) {
    $class->export_to_level(1);
    Less::Boilerplate->import::into(1);
    Getopt::Long->import::into(1);
}

sub slurp($filename) {
warn $filename;
    open my $fh, '<', $filename;
    my $contents = do { local $/; <$fh> };
    return $contents;
}

sub splat ( $filename, $contents ) {
    open my $fh, '>', $filename;
    print {$fh} $contents;
}

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
