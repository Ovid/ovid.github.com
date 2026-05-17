package Template::Plugin::Ovid::Tags;

use Less::Boilerplate;
use Less::Config 'config';
use Mojo::JSON 'decode_json';
use List::Util qw(max min);
use Path::Tiny 'path';
use aliased 'Ovid::Template::File::Collection';
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
    my @sorted = sort { $tags{$b} <=> $tags{$a} } sort keys %tags;
    return @sorted;
}

sub _tags ($self) {
    my @tags = sort grep { $_ ne '__ALL__' } keys $self->{tagmap}->%*;
    return @tags;
}

sub weight_for_tag ( $self, $tag ) {

    # https://stackoverflow.com/questions/5294955/how-to-scale-down-a-range-of-numbers-with-a-known-min-and-max-value
    state $weight_max = 9;
    state $weight_min = 1;
    my $weight_for = $self->{_weight_for} //= {};
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
    croak("Cannot find name for unknown tag '$tag'")
      unless exists $self->{tagmap}{$tag}
      && exists $self->{tagmap}{$tag}{name};
    return $self->{tagmap}{$tag}{name};
}

sub tags_for_url ( $self, $url ) {
    return [] unless exists $self->{tagmap}{__ALL__};
    return $self->{tagmap}{__ALL__}{$url} // [];
}

sub has_articles_for_tag ( $self, $tag ) {
    return $tag ne '__ALL__' && exists $self->{tagmap}{$tag};
}

sub files_for_tag ( $self, $tag ) {
    croak("Cannot find files for unknown tag '$tag'")
      if $tag eq '__ALL__'
      || !exists $self->{tagmap}{$tag}
      || !exists $self->{tagmap}{$tag}{files};
    return Collection->new( files => $self->{tagmap}{$tag}{files} );
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

Returns the display name for the tag from the loaded tagmap. Croaks
when called for an unknown tag (one without a tagmap entry). The
tagmap's C<name> field is populated by L<Ovid::Template::File> at
build time from C<Less::Config>'s C<tagmap> mapping, so config remains
the upstream source — but render-time lookups go through the in-memory
tagmap to avoid drift between two read paths.

=head2 C<tags_for_url($url)>

Returns array reference of tags for a given URL. Returns empty arrayref if URL has no tags.

=head2 C<has_articles_for_tag($tag)>

Returns true if the tagmap contains an entry for the given tag.

=head2 C<files_for_tag($tag)>

Returns an L<Ovid::Template::File::Collection> of files associated with the
given tag. Croaks if the tag is unknown.

=cut
