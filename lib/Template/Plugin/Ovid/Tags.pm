package Template::Plugin::Ovid::Tags;

use Less::Boilerplate;
use Less::Config 'config';
use Mojo::JSON 'decode_json';
use List::Util qw(max min);
use Path::Tiny 'path';
use base 'Template::Plugin';

sub new ( $class, $context ) {
    my $tagmap_file = config()->{tagmap_file}
      or croak("tagmap_file not configured");

    my $path = path($tagmap_file);
    croak("Tagmap file not found: $tagmap_file") unless $path->exists;

    my $json = $path->slurp_utf8;

    bless {
        _CONTEXT => $context,
        tagmap   => decode_json($json),
    }, $class;
}

sub tags_by_weight ($self) {
    my %tags = map { $_ => $self->weight_for_tag($_) } $self->_tags;

    # Perl's sort is stable, so by sorting the keys, we ensure
    # that tags with equal weight are sorted alphabetically.
    return sort { $tags{$b} <=> $tags{$a} } sort keys %tags;
}

sub _tags ($self) {
    return sort grep { $_ ne '__ALL__' } keys $self->{tagmap}->%*;
}

sub weight_for_tag ( $self, $tag ) {

    # https://stackoverflow.com/questions/5294955/how-to-scale-down-a-range-of-numbers-with-a-known-min-and-max-value
    state $weight_for = {};
    state $weight_max = 9;
    state $weight_min = 1;
    unless ( exists $weight_for->{$tag} ) {
        croak("Cannot find weight for unknown tag '$tag'")
          unless exists $self->{tagmap}{$tag};

        my $counts = [ map { $self->{tagmap}{$_}{count} } $self->_tags ];
        my $min    = min @$counts;
        my $max    = max @$counts;
        my $count  = $self->{tagmap}{$tag}{count};

        my $weight;
        if ( $max == $min ) {

            # All tags have equal count, use middle weight
            $weight = int( ( $weight_max + $weight_min ) / 2 );
        }
        else {
            $weight = $weight_min + ( ( $weight_max - $weight_min ) * ( $count - $min ) ) / ( $max - $min );
        }
        $weight_for->{$tag} = int( $weight + .5 );
    }
    return $weight_for->{$tag};
}

sub name_for_tag ( $self, $tag ) {
    my $name = config()->{tagmap}{$tag}
      or croak("Cannot find name for unknown tag '$tag'");
    return $name;
}

sub tags_for_url ( $self, $url ) {
    return $self->{tagmap}{__ALL__}{$url} // [];
}

1;

__END__

=head1 NAME

Template::Plugin::Ovid::Tags - Tag operations for Template Toolkit

=head1 SYNOPSIS

    [% USE tags = Ovid.Tags %]
    [% FOREACH tag IN tags.tags_by_weight %]
        <a href="/tags/[% tag %].html"
           data-weight="[% tags.weight_for_tag(tag) %]">
            [% tags.name_for_tag(tag) %]
        </a>
    [% END %]

=head1 METHODS

=head2 C<tags_by_weight()>

Returns list of tags sorted by weight (article count), heaviest first.

=head2 C<weight_for_tag($tag)>

Returns display weight for tag (1-9 scale) based on article count.

=head2 C<name_for_tag($tag)>

Returns display name for tag from config.

=head2 C<tags_for_url($url)>

Returns array reference of tags for a given URL. Returns empty arrayref if URL has no tags.

=cut
