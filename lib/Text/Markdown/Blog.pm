package Text::Markdown::Blog;

use Less::Boilerplate;
use parent 'Text::Markdown';
use HTML::TokeParser::Simple;
use HTML::Entities;
use Const::Fast;

sub new ( $class, %args ) {
    $args{use_smart_quotes} //= 1;
    return $class->next::method(%args);
}

sub should_use_smart_quotes ($self) {
    return $self->{use_smart_quotes};
}

# I should consider biting the bullet and going full multi-markdown?

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
    my $html = $self->markdown( $text, $options );
    while ( my ( $marker, $replacement ) = each %REPLACEMENTS ) {
        $html =~ s/\Q$marker\E/$replacement/g;
    }
    $self->_use_smart_quotes($html);
}

sub _use_smart_quotes ( $self, $text ) {
    return $text unless $self->should_use_smart_quotes;
    my $parser = HTML::TokeParser::Simple->new( string => $text );

    my $html  = '';
    my $punct = '[[:punct:]]';
    while ( my $token = $parser->get_token ) {
        if ( $token->is_text ) {
            my $text = $token->as_is;

            # this is a case where we have a double-quote character embedded
            # between two letters. We can't tell which smart quote that should
            # be, so we encode it and skip it.
            $text =~ s/(\w)"(\w)/$1&quot;$2/smg;

            $text =~ s/\"($punct|\w)/“$1/smg;    # leading smart quote
            $text =~ s/(\w|$punct)\"/$1”/smg;    # trailing smart quote
            $text =~ s/(\w)'(\w)/$1’$2/smg;      # contractions: don’t
            $text =~ s/(\W)'(\w)/$1‘$2/smg;      # ‘tis the season

            # special-cases of single quote starting a string. We handle it
            # independently to avoid complicating the above regexes
            $text =~ s/^'(\w)/‘$1/;    # ‘tis the season
            $html .= $text;
        }
        else {
            $html .= $token->as_is;
        }
    }
    return $html;
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

# _DoHeaders and _DoTables copied from
# https://metacpan.org/release/Text-MultiMarkdown/source/lib/Text/MultiMarkdown.pm
sub _DoHeaders ( $self, $text ) {
    $text = $self->SUPER::_DoHeaders($text);

# Do tables to populate the table id's for cross-refs
# (but after headers as the tables can contain cross-refs to other things, so we want the header cross-refs)
    $text = $self->_DoTables($text);
}

sub _DoTables ( $self, $text ) {
    return $text if $self->{disable_tables};

    my $less_than_tab = $self->{tab_width} - 1;

    # Algorithm inspired by PHP Markdown Extra's
    # <http://www.michelf.com/projects/php-markdown/>

    # Reusable regexp's to match table

    my $line_start = qr{
        [ ]{0,$less_than_tab}
    }mx;

    my $table_row = qr{
        [^\n]*?\|[^\n]*?\n
    }mx;

    my $first_row = qr{
        $line_start
        \S+.*?\|.*?\n
    }mx;

    my $table_rows = qr{
        (\n?$table_row)
    }mx;

    my $table_caption = qr{
        $line_start
        \[.*?\][ \t]*\n
    }mx;

    my $table_divider = qr{
        $line_start
        [\|\-\:\.][ \-\|\:\.]* \| [ \-\|\:\.]*
    }mx;

    my $whole_table = qr{
        ($table_caption)?       # Optional caption
        ($first_row             # First line must start at beginning
        ($table_row)*?)?        # Header Rows
        $table_divider          # Divider/Alignment definitions
        $table_rows+            # Body Rows
        ($table_caption)?       # Optional caption
    }mx;

    # Find whole tables, then break them up and process them

    $text =~ s{
        ^($whole_table)         # Whole table in $1
        (\n|\Z)                 # End of file or 2 blank lines
    }{
        my $table = $1;
        my $result = "<table>\n";
        my @alignments;
        my $use_row_header = 0;
 
        # Add Caption, if present
 
        if ($table =~ s/^$line_start\[\s*(.*?)\s*\](\[\s*(.*?)\s*\])?[ \t]*$//m) {
            if (defined $3) {
                # add caption id to cross-ref list
                my $table_id = $self->_Header2Label($3);
                $result .= qq{<caption id="$table_id">} . $self->_RunSpanGamut($1). "</caption>\n";
 
                $self->{_crossrefs}{$table_id} = "#$table_id";
                $self->{_titles}{$table_id} = "$1";
            }
            else {
                $result .= "<caption>" . $self->_RunSpanGamut($1). "</caption>\n";
            }
        }
 
        # If a second "caption" is present, treat it as a summary
        # However, this is not valid in XHTML 1.0 Strict
        # But maybe in future
 
        # A summary might be longer than one line
        if ($table =~ s/\n$line_start\[\s*(.*?)\s*\][ \t]*\n/\n/s) {
            # $result .= "<summary>" . $self->_RunSpanGamut($1) . "</summary>\n";
        }
 
        # Now, divide table into header, alignment, and body
 
        # First, add leading \n in case there is no header
 
        $table = "\n" . $table;
 
        # Need to be greedy
 
        $table =~ s/\n($table_divider)\n(($table_rows)+)//s;
 
        my $alignment_string = $1;
        my $body = $2;
 
        # Process column alignment
        while ($alignment_string =~ /\|?\s*(.+?)\s*(\||\Z)/gs) {
            my $cell = $self->_RunSpanGamut($1);
            if ($cell =~ /\:$/) {
                if ($cell =~ /^\:/) {
                    $result .= qq[<col align="center"$self->{empty_element_suffix}\n];
                    push(@alignments,"center");
                }
                else {
                    $result .= qq[<col align="right"$self->{empty_element_suffix}\n];
                    push(@alignments,"right");
                }
            }
            else {
                if ($cell =~ /^\:/) {
                    $result .= qq[<col align="left"$self->{empty_element_suffix}\n];
                    push(@alignments,"left");
                }
                else {
                    if (($cell =~ /^\./) || ($cell =~ /\.$/)) {
                        $result .= qq[<col align="char"$self->{empty_element_suffix}\n];
                        push(@alignments,"char");
                    }
                    else {
                        $result .= "<col$self->{empty_element_suffix}\n";
                        push(@alignments,"");
                    }
                }
            }
        }
 
        # Process headers
        $table =~ s/^\n+//s;
 
        $result .= "<thead>\n";
 
        # Strip blank lines
        $table =~ s/\n[ \t]*\n/\n/g;
 
        foreach my $line (split(/\n/, $table)) {
            # process each line (row) in table
            $result .= "<tr>\n";
            my $count=0;
            while ($line =~ /\|?\s*([^\|]+?)\s*(\|+|\Z)/gs) {
                # process contents of each cell
                my $cell = $self->_RunSpanGamut($1);
                my $ending = $2;
                my $colspan = "";
                if ($ending =~ s/^\s*(\|{2,})\s*$/$1/) {
                    $colspan = " colspan=\"" . length($ending) . "\"";
                }
                $result .= "\t<th$colspan>$cell</th>\n";
                if ( $count == 0) {
                    if ($cell =~ /^\s*$/) {
                        $use_row_header = 1;
                    }
                    else {
                        $use_row_header = 0;
                    }
                }
                $count++;
            }
            $result .= "</tr>\n";
        }
 
        # Process body
 
        $result .= "</thead>\n<tbody>\n";
 
        foreach my $line (split(/\n/, $body)) {
            # process each line (row) in table
            if ($line =~ /^\s*$/) {
                $result .= "</tbody>\n\n<tbody>\n";
                next;
            }
            $result .= "<tr>\n";
            my $count=0;
            while ($line =~ /\|?\s*([^\|]+?)\s*(\|+|\Z)/gs) {
                # process contents of each cell
                no warnings 'uninitialized';
                my $cell = $self->_RunSpanGamut($1);
                my $ending = $2;
                my $colspan = "";
                my $cell_type = "td";
                if ($count == 0 && $use_row_header == 1) {
                    $cell_type = "th";
                }
                if ($ending =~ s/^\s*(\|{2,})\s*$/$1/) {
                    $colspan = " colspan=\"" . length($ending) . "\"";
                }
                if ($alignments[$count] !~ /^\s*$/) {
                    $result .= "\t<$cell_type$colspan align=\"$alignments[$count]\">$cell</$cell_type>\n";
                }
                else {
                    $result .= "\t<$cell_type$colspan>$cell</$cell_type>\n";
                }
                $count++;
            }
            $result .= "</tr>\n";
        }
 
        $result .= "</tbody>\n</table>\n";
        $result
    }egmx;

    my $table_body = qr{
        (                               # wrap whole match in $2
 
            (.*?\|.*?)\n                    # wrap headers in $3
 
            [ ]{0,$less_than_tab}
            ($table_divider)    # alignment in $4
 
            (                           # wrap cells in $5
                $table_rows
            )
        )
    }mx;

    return $text;
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
