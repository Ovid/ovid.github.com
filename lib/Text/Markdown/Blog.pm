package Text::Markdown::Blog;

use Less::Boilerplate;
use parent 'Text::Markdown';
use Const::Fast;

# this is because Text::Markdown keeps parsing text _after_ it's processed in
# _GenerateAnchor, causing spurious HTML that we have to fix
#
const my $FA_CUSTOM => '{{FA-CUSTOM}}';
const my $BLANK     => '{{-BLANK}}';
my %REPLACEMENTS = (
    $FA_CUSTOM => 'fa_custom',
    $BLANK     => '_blank',
);

sub blogdown ( $self, $text, $options = {} ) {
    my $markdown = $self->markdown( $text, $options );
    while ( my ( $marker, $replacement ) = each %REPLACEMENTS ) {
        $markdown =~ s/\Q$marker\E/$replacement/g;
    }
    return $markdown;
}

sub _GenerateAnchor (
    $self, $whole_match, $link_text, $link_id,
    $url        = undef,
    $title      = undef,
    $attributes = undef
  )
{
    my $result;

    $attributes = '' unless defined $attributes;

    if ( !defined $url && defined $self->{_urls}{$link_id} ) {
        $url = $self->{_urls}{$link_id};
    }

    if ( !defined $url ) {
        return $whole_match;
    }

    $url =~ s! \* !$Text::Markdown::g_escape_table{'*'}!gox
      ;    # We've got to encode these to avoid
    $url =~ s!  _ !$Text::Markdown::g_escape_table{'_'}!gox
      ;    # conflicting with italics/bold.
    $url =~ s{^<(.*)>$}{$1};    # Remove <>'s surrounding URL, if present

    $result = qq{<a href="$url"};

    my $external = 0;
    if ( $url =~ m{^\w+://} ) {
        $external = 1;
    }
    if ($external) {
        $result .= qq' target="$BLANK"';
    }

    if (  !defined $title
        && defined $link_id
        && defined $self->{_titles}{$link_id} )
    {
        $title = $self->{_titles}{$link_id};
    }

    if ( defined $title ) {
        $title =~ s/"/&quot;/g;
        $title =~ s! \* !$Text::Markdown::g_escape_table{'*'}!gox;
        $title =~ s!  _ !$Text::Markdown::g_escape_table{'_'}!gox;
        $result .= qq{ title="$title"};
    }

    $result .= "$attributes>$link_text</a>";
    if ($external) {
        $result .= qq' <span class="fa fa-external-link $FA_CUSTOM"></span>';
    }

    return $result;
}

1;

__END__

=head1 NAME

Text::Markdown::Blog - Ovid's Markdown hack

=head1 DESCRIPTION

No user-serviceable parts inside.

Just like L<Text::Markdown>, but if a link C<< [...](...) >> has a URL
beginning with C<^\w+://>, then we add extra processing to ensure it works for
Ovid's blog setup.
