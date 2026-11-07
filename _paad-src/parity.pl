#!/usr/bin/env perl
# Compare the hand-written PAAD page with the one build-tutorial produces.
#   perl _paad-src/parity.pl paad/index.html /path/to/new.html
use v5.40;
use utf8;
use JSON::PP ();
use List::Util qw(min);
use Mojo::DOM;
use Path::Tiny qw(path);

my $tools = $ENV{EASY_TUTORIALS} // "$ENV{HOME}/projects/easy-tutorials";
require "$tools/bin/html2tut";

die "usage: parity.pl <old.html> <new.html>\n" unless @ARGV == 2;
my ( $old_html, $new_html ) = map { path($_)->slurp_utf8 } @ARGV;
my ( $old, $new ) = map { Mojo::DOM->new($_) } $old_html, $new_html;
binmode STDOUT, ':encoding(UTF-8)';

my $diffs = 0;
sub differ ( $where, $what, $x, $y ) { $diffs++; say "$where: $what differs\n  old: $x\n  new: $y" }
sub text ($html) { Mojo::DOM->new( $html // '' )->all_text =~ s/\s+/ /gr =~ s/\A | \z//gr }

sub first_diff ( $x, $y ) {
    my $i = 0;
    $i++ while $i < length $x && $i < length $y && substr( $x, $i, 1 ) eq substr( $y, $i, 1 );
    my $from = $i > 60 ? $i - 60 : 0;
    return ( substr( $x, $from, 120 ), substr( $y, $from, 120 ) );
}

# Page
differ( 'head', 'CSS', 'old <style>', 'new <style>' ) if $old->at('head style')->text ne $new->at('head style')->text;
for my $sel ( 'title', '.brand' ) {
    my ( $x, $y ) = map { text( $_->at($sel)->to_string ) } $old, $new;
    differ( 'page', $sel, $x, $y ) if $x ne $y;
}

# Sections
my @old_secs = $old->find('section.section')->each;
my %new_sec  = map { $_->attr('id') => $_ } $new->find('section.section')->each;
my ( $old_ids, $new_ids ) = map { join ' ', map { $_->attr('id') } $_->find('section.section')->each } $old, $new;
differ( 'page', 'section order', $old_ids, $new_ids ) if $old_ids ne $new_ids;
for my $o (@old_secs) {
    my $id = $o->attr('id');
    my $n  = $new_sec{$id} or do { differ( $id, 'presence', 'present', 'missing' ); next };
    for my $attr (qw(data-title data-group data-optional)) {
        my ( $x, $y ) = map { $_->attr($attr) // '' } $o, $n;
        differ( $id, $attr, $x, $y ) if $x ne $y;
    }
    my ( $x, $y ) = map { text( $_->to_string ) } $o, $n;
    differ( $id, 'text', first_diff( $x, $y ) ) if $x ne $y;
}

# Quiz, steps, score data
my $old_data = Html2Tut::js_data($old_html);
my $new_data = JSON::PP->new->decode( $new->at('#tutorial-data')->text );

for my $host ( $old->find('[data-quiz]')->each ) {
    my $sec    = $host->ancestors('section')->first->attr('id');
    my $n_host = $new_sec{$sec} && $new_sec{$sec}->at('[data-quiz]') or do { differ( $sec, 'quiz', 'present', 'missing' ); next };
    my ( $oq, $nq ) = ( $old_data->{quiz}{ $host->attr('data-quiz') }, $new_data->{quiz}{ $n_host->attr('data-quiz') } );
    differ( $sec, 'quiz length', scalar @$oq, scalar @$nq ) if @$oq != @$nq;
    for my $i ( 0 .. min( $#$oq, $#$nq ) ) {
        my ( $x, $y ) = ( $oq->[$i], $nq->[$i] );
        my $at = "$sec quiz question " . ( $i + 1 );
        differ( $at, 'answer', $x->{a}, $y->{a} ) if $x->{a} != $y->{a};
        for my $f (qw(q why)) {
            my ( $s, $t ) = map { text( $_->{$f} ) } $x, $y;
            differ( $at, $f, $s, $t ) if $s ne $t;
        }
        for my $k ( 0 .. 3 ) {
            my ( $s, $t ) = map { text( $_->{o}[$k] ) } $x, $y;
            differ( $at, 'option ' . ( $k + 1 ), $s, $t ) if $s ne $t;
        }
    }
}
my $final_sec = $old->at('[data-quiz="final"]')->ancestors('section')->first->attr('id');
my $final_key = $new_sec{$final_sec}->at('[data-quiz]')->attr('data-quiz');
differ( 'page', 'final quiz', $final_key, $new_data->{final} // 'none' ) if ( $new_data->{final} // '' ) ne $final_key;

my $loop_sec = $old->at('#loopDiagram')->ancestors('section')->first->attr('id');
my $steps    = $new_data->{steps}{ $new_sec{$loop_sec}->at('[data-steps]')->attr('data-steps') };
differ( $loop_sec, 'step count', scalar $old_data->{loop}->@*, scalar @$steps ) if $old_data->{loop}->@* != @$steps;
for my $i ( 0 .. min( $old_data->{loop}->$#*, $#$steps ) ) {
    my ( $x, $y ) = ( $old_data->{loop}[$i], $steps->[$i] );
    for my $f (qw(n tag tagl t sub body)) {
        my ( $s, $t ) = map { text( $_->{$f} ) } $x, $y;
        differ( "$loop_sec step " . ( $i + 1 ), $f, $s, $t ) if $s ne $t;
    }
}

my ( $os, $ns ) = map { JSON::PP->new->canonical->encode($_) } Html2Tut::score_messages($old_html), $new_data->{score};
differ( 'page', 'score messages', $os, $ns ) if $os ne $ns;

say $diffs ? "$diffs difference(s)" : 'no differences';
exit( $diffs ? 1 : 0 );
