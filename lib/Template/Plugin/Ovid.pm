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
use Template::Plugin::Blogdown;
use base 'Template::Plugin';

sub new ( $class, $context ) {
    open my $fh, '<', config()->{tagmap_file};
    my $json = do { local $/; <$fh> };
    bless {
        _CONTEXT                   => $context,
        footnote_number            => 1,
        footnote_names             => {},
        footnotes                  => [],
        collapsible_section_number => 1,
        pager                      => Less::Pager->new( type => 'article' ),
        tagmap                     => decode_json($json),
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

sub tags ($self) {
    return sort grep { $_ ne '__ALL__' } keys $self->{tagmap}->%*;
}

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
    # Hidden when JS is disabled via CSS (see static/css/dialog.css)
    my $dialog
      = qq{<span aria-label="Open Footnote" class="open-dialog js-only" id="open-dialog-$number"> <i class="fa fa-clipboard fa_custom"></i> </span>};
    
    # NoScript mode: anchor link to footnote at end of article (Feature 002)
    # Shows superscript number instead of icon for better UX
    my $noscript
      = qq{<noscript><a href="#footnote-$number" id="footnote-$number-return" aria-label="Footnote $number"><sup>[$number]</sup></a></noscript>};
    
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

sub collapse ( $self, $short_description, $full_content ) {
    # Parameter validation (T013)
    if ( !defined($short_description) || $short_description !~ /\S/ ) {
        croak("collapse() requires short_description parameter");
    }
    if ( !defined($full_content) || $full_content !~ /\S/ ) {
        croak("collapse() requires full_content parameter");
    }

    # Increment counter and generate unique IDs (T014, T015)
    my $number     = $self->{collapsible_section_number}++;
    my $trigger_id = "collapsible-trigger-$number";
    my $content_id = "collapsible-content-$number";

    # Process full_content through blogdown (for Phase 5/US3)
    my $blogdown = Template::Plugin::Blogdown->new( $self->{_CONTEXT} );
    my $processed_content = $blogdown->filter($full_content);

    # Build HTML structure with ARIA attributes (T016, T017, T018)
    # Progressive enhancement: content visible by default (no-JS), hidden by JavaScript
    my $html = <<"HTML";
<div class="collapsible-section">
    <div class="collapsible-trigger"
         id="$trigger_id"
         role="button"
         tabindex="0"
         aria-expanded="false"
         aria-controls="$content_id"
         aria-label="Expand: $short_description">
        <i class="fa fa-chevron-right collapsible-icon" aria-hidden="true"></i>
        <span class="collapsible-short">$short_description</span>
    </div>
    <div id="$content_id"
         class="collapsible-content"
         role="region"
         aria-labelledby="$trigger_id">
        $processed_content
    </div>
</div>
HTML

    return $html;
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

=head2 C<collapse($short_description, $full_content)>

    [% Ovid.collapse("Click to see code example", "~~~perl
    use v5.40;
    say 'Hello, World!';
    ~~~") %]

Creates a collapsible section that displays a short description by default and expands
to show full content when clicked. The full content supports blogdown Markdown formatting
including code blocks, lists, bold/italic text, and external links.

B<Parameters:>

=over 4

=item * C<$short_description> (required)

The summary text displayed in the collapsed state. This appears in the clickable trigger
area with a chevron icon. Must be non-empty and contain non-whitespace characters.

=item * C<$full_content> (required)

The detailed content shown when expanded. Supports full blogdown Markdown syntax:

=over 4

=item * Code blocks with syntax highlighting: C<~~~perl ... ~~~>

=item * Markdown lists: C<- Item 1>, C<* Item 2>

=item * Bold/italic: C<**bold**>, C<*italic*>

=item * External links: Auto-adds C<target="_blank"> and external link icon

=item * Headings, tables, and other standard Markdown features

=back

Must be non-empty and contain non-whitespace characters.

=back

B<Returns:>

An HTML string containing:

=over 4

=item * Interactive collapsible section with unique IDs

=item * ARIA attributes for accessibility (aria-expanded, aria-controls, role="button")

=item * Keyboard navigation support (Enter/Space keys)

=item * Noscript fallback showing both short and full content

=back

B<Examples:>

Basic usage:

    [% Ovid.collapse("Summary", "Details go here") %]

With code highlighting:

    [% Ovid.collapse(
        "Example Code",
        "Here's a Perl example:
    
    ~~~perl
    use v5.40;
    
    sub fibonacci ($n) {
        return $n if $n < 2;
        return fibonacci($n - 1) + fibonacci($n - 2);
    }
    ~~~"
    ) %]

With lists and formatting:

    [% Ovid.collapse(
        "Key Features",
        "Main benefits:
    
    - **Progressive disclosure**: Readers choose depth
    - **Better organization**: Group related details
    - Code highlighting support
    - External link handling"
    ) %]

With external links:

    [% Ovid.collapse(
        "Further Reading",
        "See [the Wikipedia article](https://en.wikipedia.org/wiki/Progressive_disclosure) for details."
    ) %]

Multiple sections in one article:

    [% Ovid.collapse("Section 1", "Content 1") %]
    
    <p>Regular article content</p>
    
    [% Ovid.collapse("Section 2", "Content 2") %]
    [% Ovid.collapse("Section 3", "Content 3") %]

Each section operates independently with unique identifiers.

B<Accessibility Features:>

=over 4

=item * Keyboard accessible (Enter/Space to toggle)

=item * Screen reader support with ARIA attributes

=item * Focus indicators meet WCAG 2.1 AA standards

=item * No JavaScript required (progressive enhancement)

=item * Noscript fallback displays all content expanded and indented

=back

B<Error Handling:>

Throws an error (via C<croak>) if:

=over 4

=item * C<$short_description> is undefined, empty, or whitespace-only

=item * C<$full_content> is undefined, empty, or whitespace-only

=back

All errors are fatal during template processing to prevent invalid HTML generation.

B<Technical Details:>

Each call generates unique IDs for the trigger and content elements
(e.g., C<collapsible-trigger-1>, C<collapsible-content-1>) to ensure multiple
sections on the same page operate independently. The counter increments with each
call within a template processing session.

The full content is processed through Template::Plugin::Blogdown for Markdown
rendering before being inserted into the HTML structure.

Requires C<static/css/collapsible.css> and C<static/js/collapsible.js> to be
included in the page wrapper for styling and interactive behavior.

=cut

