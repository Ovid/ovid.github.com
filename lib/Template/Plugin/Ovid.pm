package Template::Plugin::Ovid;

use Less::Boilerplate;
use Less::Pager;
use Less::Script ();    # import nothing
use aliased 'Ovid::Template::File::Collection';
use Mojo::JSON 'decode_json';
use List::Util qw(sum0 max min);
use Less::Config 'config';
use Path::Tiny 'path';
use Ovid::Site::AI::Images;
use Ovid::Site::Utils qw(
  get_image_description
  set_image_description
);
use base 'Template::Plugin';

sub new ( $class, $context ) {
    open my $fh, '<', config()->{tagmap_file};
    my $json = do { local $/; <$fh> };
    bless {
        _CONTEXT        => $context,
        footnote_number => 1,
        footnote_names  => {},
        footnotes       => [],
        pager           => Less::Pager->new( type => 'article' ),
        tagmap          => decode_json($json),
    }, $class;
}

# NOTE: Called from Template Toolkit templates (root/include/header.tt)
# Used for og:image:type meta tags. Static analysis cannot detect this usage.
sub image_type ( $self, $image ) {
    return
        $image =~ /\.png$/   ? 'image/png'
      : $image =~ /\.gif/    ? 'image/gif'
      : $image =~ /\.jpe?g$/ ? 'image/jpeg'
      :                        croak("Cannot determine image type for '$image'");
}

sub cite ( $self, $path, $name ) {
    return sprintf '<a href="%s" target="_blank">%s</a> <span class="fa fa-external-link fa_custom"></span>' => $path,
      $name;
}

# TODO (Coverage Improvement 001): Verify template usage before removal
# Static analysis shows no Perl code calls, check .tt/.tt2markdown files
# See: specs/001-test-coverage-improvement/unused-code-decisions.md
sub tags ($self) {
    return sort grep { $_ ne '__ALL__' } keys $self->{tagmap}->%*;
}

# NOTE: Called from Template Toolkit templates (root/include/tags_for_article.tt)
# Returns array of tags for a given URL. Static analysis cannot detect template usage.
sub tags_for_url ( $self, $url ) {
    return $self->{tagmap}{__ALL__}{$url} // [];
}

# NOTE: Called from Template Toolkit templates (root/include/links.tt)
# Returns tags sorted by weight for tag cloud display. Static analysis cannot detect template usage.
sub tags_by_weight($self) {
    my %tags = map { $_ => $self->weight_for_tag($_) } $self->tags;

    # Perl's sort is stable, so by sorting the keys, we ensure
    # that tags with equal weight are sorted alphabetically.
    return sort { $tags{$b} <=> $tags{$a} } sort keys %tags;
}

# TODO (Coverage Improvement 001): Verify template usage before removal
# Static analysis shows no Perl code calls, check .tt/.tt2markdown files
# See: specs/001-test-coverage-improvement/unused-code-decisions.md
sub has_articles_for_tag ( $self, $tag ) {
    return exists $self->{tagmap}{$tag};
}

# TODO (Coverage Improvement 001): Verify template usage before removal
# Static analysis shows no Perl code calls, check .tt/.tt2markdown files
# See: specs/001-test-coverage-improvement/unused-code-decisions.md
sub name_for_tag ( $self, $tag ) {
    my $name = config()->{tagmap}{$tag}
      or croak("Cannot find name for unknown tag '$tag'");
    return $name;
}

sub weight_for_tag ( $self, $tag ) {

    # https://stackoverflow.com/questions/5294955/how-to-scale-down-a-range-of-numbers-with-a-known-min-and-max-value
    state $weight_for = {};
    state $weight_max = 9;
    state $weight_min = 1;
    unless ( exists $weight_for->{$tag} ) {
        my $counts = [ map { $self->count_for_tag($_) } $self->tags ];
        my $min    = min @$counts;
        my $max    = max @$counts;
        my $count  = $self->count_for_tag($tag);
        my $weight = $weight_min + ( ( $weight_max - $weight_min ) * ( $count - $min ) ) / ( $max - $min );
        $weight_for->{$tag} = int( $weight + .5 );
    }
    return $weight_for->{$tag};
}

sub count_for_tag ( $self, $tag ) {
    my $count = $self->{tagmap}{$tag}{count}
      or croak("Cannot find count for unknown tag '$tag'");
    return $count;
}

# TODO (Coverage Improvement 001): Verify template usage before removal
# Static analysis shows no Perl code calls, check .tt/.tt2markdown files
# See: specs/001-test-coverage-improvement/unused-code-decisions.md
sub files_for_tag ( $self, $tag ) {
    my $files = $self->{tagmap}{$tag}{files}
      or croak("Cannot find files for unknown tag '$tag'");
    return Collection->new( files => $files );
}

# TODO (Coverage Improvement 001): Verify template usage before removal
# Static analysis shows no Perl code calls, check .tt/.tt2markdown files
# See: specs/001-test-coverage-improvement/unused-code-decisions.md
sub title_for_tag_file ( $self, $tag, $file ) {
    my $title = $self->{tagmap}{$tag}{titles}{$file}
      or croak("Cannot find title for unknown tag '$tag'");
    return $title;
}

sub add_note ( $self, $note ) {
    my $number = $self->{footnote_number}++;
    my $id     = "note-$number";
    
    # JavaScript-enabled mode: span that triggers dialog
    my $dialog
      = qq{<span aria-label="Open Footnote" class="open-dialog" id="open-dialog-$number"> <i class="fa fa-clipboard fa_custom"></i> </span>};
    
    # NoScript mode: anchor link to footnote at end of article (Feature 002)
    my $noscript
      = qq{<noscript><a href="#footnote-$number" id="footnote-$number-return" aria-label="Footnote $number"> <i class="fa fa-clipboard fa_custom"></i> </a></noscript>};
    
    my $body = <<"HTML";
    <div id="dialog-$number" class="dialog" role="dialog" aria-labelledby="$id" aria-describedby="note-description-$number" aria-hidden="true">
        <strong id="$id">Footnotes</strong>
        <p id="note-description-$number" class="sr-only">Note number $number</p>
	    <div>$note</div>
        <button type="button" aria-label="Close Navigation" class="close-dialog" id="close-dialog-$number"> <i class="fa fa-times"></i> </button>
    </div>
HTML

    # the footnotes are read and displayed in the template footer
    # 'content' field added for noscript rendering (Feature 002)
    push $self->{footnotes}->@* => { 
        number  => $number, 
        body    => $body,
        content => $note,
    };
    
    # Return both JavaScript dialog trigger and noscript anchor link
    return $dialog . $noscript;
}

# NOTE: Called from Template Toolkit templates (multiple article templates)
# Used for creating footnotes. Static analysis cannot detect template usage.
# because I keep writing Ovid.note instead of Ovid.add_note
sub note ( $self, @args ) { $self->add_note(@args) }

# NOTE: Called from Template Toolkit templates (publicspeaking.tt, videos.tt2markdown, multiple articles)
# Embeds YouTube videos in responsive containers. Static analysis cannot detect template usage.
sub youtube ( $self, $youtube_id ) {
    if ( $youtube_id =~ m{/} ) {
        croak("Youtube id '$youtube_id' id does not appear to be valid");
    }
    return <<"HTML";
<div class="video-responsive">
	<iframe width="560" height="315" src="https://www.youtube.com/embed/$youtube_id" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>
HTML
}

sub describe_image( $self, $image ) {
    # OpenAI costs money, so let's see if we have an image description. If we
    # do, just return that. Otherwise, get it from OpenAI and cache it.
    $image = path($image);

    # unless image starts with root/, add that to the front of the path
    # because all of our images start in the root directory.
    unless ( $image =~ /^root\b/ ) {
        $image = path('root')->child($image);
    }
    unless ( $image->exists ) {
        croak "File does not exist or is not readable: $image\n";
    }
    my $description = get_image_description($image);
    return $description if $description;

    my $chat     = Ovid::Site::AI::Images->new;
    my $response = $chat->describe_image($image);
    say STDERR <<~"END";
    Image:       $image
    Description: $response
    END
    set_image_description( $image, $response );
    return $response;
}

sub link ( $self, $path, $name ) {
    return sprintf '<a href="%s">%s</a>' => $path, $name;
}

# NOTE: Called from Template Toolkit templates (root/include/footer.tt)
# Returns array of footnotes for rendering. Static analysis cannot detect template usage.
sub get_footnotes($self) {
    return $self->{footnotes};
}

# NOTE: Called from Template Toolkit templates (root/include/footer.tt)
# Checks if any footnotes exist before rendering footer. Static analysis cannot detect template usage.
sub has_footnotes($self) {
    return scalar $self->{footnotes}->@*;
}

sub this_post ( $self, $type, $slug ) {
    return $self->{pager}->this_post( $type, $slug );
}

sub prev_post ( $self, $type, $slug ) {
    return $self->{pager}->prev_post( $type, $slug );
}

sub next_post ( $self, $type, $slug ) {
    return $self->{pager}->next_post( $type, $slug );
}

# TODO (Coverage Improvement 001): Verify template usage before removal
# Static analysis shows no Perl code calls, check .tt/.tt2markdown files
# See: specs/001-test-coverage-improvement/unused-code-decisions.md
sub is_blog ( $self, $type ) {
    return $type eq 'blog';
}

1;

__END__

=head1 NAME

Template::Plugin::Ovid - Quick utils for my website

=head1 SYNOPSIS

    [% USE Ovid %]
    [% Ovid.link(url, name) %]
    [% Ovid.cite(url, name) %]

=head1 FUNCTIONS

=head2 C<link>

    [% Ovid.link(url, name) %]
    [% Ovid.link('/articles/some-article.html', 'Some Article') %]

Create an internal link to a page.

=head2 C<cite>

    [% Ovid.cite(url, name) %]

Lke C<Ovid.link>, but creates a link to an external site and opens in a new tab. However,
the link is a superscript number, (a C<< <sup> >> tag) to be small an unobtrusive.

We'll see later if this was a mistake.

=head2 C<add_note($text, $optional_name)>

    [% Ovid.add_note('Witty and insightful comment that would nonetheless be distracting') %]
    [% Ovid.add_note('This is a comment.', 'named comment') %]

Adds a footnote (shown as a link via a superscripted number) to the document.

=head2 C<get_footnotes()>

    [% FOR footnote IN Ovid.get_footnotes;
        footnote;
    END %]

Returns an array reference of all added footnotes. Each is enclosed in C<< <p> >> tags
and has a link back to the footnote reference.

=head2 C<has_footnotes()>

    [% IF Ovid.has_footnotes %]

Returns true if any footnotes have been added.
