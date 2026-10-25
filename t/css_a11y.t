#!/usr/bin/env perl

# Pins the a11y-audit CSS values that have no other test. Each one was a
# measured failure in paad/a11y-reviews/a11y-2026-10-11-15-43-17.md.

use v5.40;
use Test::Most;
use Path::Tiny;

my $css = path('root/static/css/main.css')->slurp_utf8;

sub rule ($selector) {
    my ($body) = $css =~ /^\Q$selector\E\s*\{([^}]*)\}/m;
    return $body // '';
}

sub rem ( $body, $property ) {
    my ($value) = $body =~ /\b\Q$property\E:\s*([\d.]+)rem/;
    return $value // 0;
}

# Don't make nav labels too small.
cmp_ok rem( rule('.nav-links .nav-feed'), 'font-size' ), '>=', .55,
  'RSS nav labels are at least .55rem';

# M11: stacked tag links were ~20px tall on a ~21.8px pitch (2.5.8 needs 24px).
cmp_ok rem( rule('ul.inline'), 'gap' ), '>=', .3, 'stacked tag links have at least .3rem between them';

# M12: wrapped footer links had a ~19px pitch on phones.
my $colophon = rule('.colophon-links a');
like $colophon, qr/display:\s*inline-block/, 'footer links are inline-block so padding takes space';
cmp_ok rem( $colophon, 'padding' ), '>=', .3, '... with at least .3rem of vertical padding';

done_testing;
