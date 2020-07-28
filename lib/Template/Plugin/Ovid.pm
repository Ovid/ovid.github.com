package Template::Plugin::Ovid;

use Less::Boilerplate;
use Less::Pager;
use base 'Template::Plugin';

sub new ( $class, $context ) {
    bless {
        _CONTEXT        => $context,
        footnote_number => 1,
        footnote_names  => {},
        footnotes       => [],
        pager           => Less::Pager->new( type => 'article' ),
    }, $class;
}

sub cite ( $self, $path, $name ) {
    return
      sprintf
'<a href="%s" target="_blank">%s</a> <span class="fa fa-external-link fa_custom"></span>'
      => $path,
      $name;
}

sub add_note ( $self, $note, $name = $self->{footnote_number} ) {
    $name =~ s/\s+/-/g;
    my $return = "$name-return";
    my $number = $self->{footnote_number}++;
    if ( exists $self->{footnote_names}{$name} ) {
        croak("Footnote '$name' already used");
    }
    $self->{footnote_names}{$name} = 1;
    my $html = <<"HTML";
<a href="#$name" class="popup-btn"> <span class="fa fa-clipboard fa_custom"></span></a>
<span id="$name" class="popup">
  <a href="#$return" class="close">&times;</a>
  <span class="popup-body">$note</span>
</span>
<a href="#$return" class="close-popup"></a>
HTML
#    push $self->{footnotes}->@* =>
#      qq{<p id="$name"><a href="#$return">[$number]</a> $note</p>};
    return $html;
}

sub youtube ($self, $youtube_id) {
    if ( $youtube_id =~ m{/} ) {
        croak("Youtube id '$youtube_id' id does not appear to be valid");
    }
    return <<"HTML";
<div class="video-responsive">
	<iframe width="560" height="315" src="https://www.youtube.com/embed/$youtube_id" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>
HTML
}

sub link ( $self, $path, $name ) {
    return sprintf '<a href="%s">%s</a>' => $path, $name;
}

sub get_footnotes($self) {
    return $self->{footnotes};
}

sub has_footnotes($self) {
    return scalar $self->{footnotes}->@*;
}

sub this_post($self, $type, $slug) {
    return $self->{pager}->this_post($type, $slug);
}

sub prev_post($self, $type, $slug) {
    return $self->{pager}->prev_post($type, $slug);
}

sub next_post($self, $type, $slug) {
    return $self->{pager}->next_post($type, $slug);
}

sub is_blog($self,$type) {
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
