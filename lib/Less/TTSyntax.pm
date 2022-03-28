package Less::TTSyntax;

use Less::Script;
use Exporter 'import';
use Less::Config qw(
  config
);

our @EXPORT_OK = qw(
  build_tags
  rewrite_code_blocks
);

my $CODE_BLOCK_MARKER = qr/^
    ```
    \s*
    (?<language>\w+)?
    \s*
$/x;

sub build_tags {
    my ( $contents, $file, $destfile, $tagmap ) = @_;

    my $config = config();
    my $tags;
    ( $contents, $tags ) = preprocess_macros( $file, $contents );
    if ( $tags->@* ) {
        my $title = get_title_from_template( $file, $contents );
        unless ($title) {
            croak("Tags found for '$file' but could not determine title");
        }

        # XXX nasty hack alert
        my $url = $destfile;
        $url =~ s{^tmp/}{};
        $url =~ s/\.tt(?:2markdown)?$/.html/;
        $tagmap->{__ALL__}{$url} = $tags;

        foreach my $tag ( $tags->@* ) {
            if ( my $name = $config->{tagmap}{$tag} ) {
                $tagmap->{$tag}{name} = $name;
                warn $name;
                $tagmap->{$tag}{count}++;
                $tagmap->{$tag}{files} //= [];
                $tagmap->{$tag}{titles}{$url} = $title;
                push $tagmap->{$tag}{files}->@* => $url;
            }
            else {
                die "No tagmap: entry found for tag '$tag' in file '$file'";
            }

        }
    }
    return $contents;
}
sub simplify_tt_code($tt) {

    # obviously, more might be added later
    return rewrite_code_blocks($tt);
}

sub get_title_from_template ($file, $contents ) {
    # many pages don't have titles, so it's ok to skip them
    if ( $contents =~
        m{\s*\[%(.*?)\[%.*?(?:INCLUDE|WRAPPER).*?%\]}s )
    {
        my $header = $1;
        foreach my $line ( split /\n/ => $header ) {
            my ( $key, $value ) = map { trim($_) } split /=/ => $line;
            next unless $key && $value;
            next if 'title' ne $key;
            $value =~ s/;$//;
            $value =~ s/^['"]//;
            $value =~ s/['"]$//;
            return $value if 'title' eq $key;
        }
    }
    return;
}

sub rewrite_code_blocks ($tt) {
    my @lines = split /\n/ => $tt;

    my $rewritten = '';
    my $in_code_block = 0;

    my $line_number = 0;
    my $debug = 1;
  LINE: foreach my $line (@lines) {
      $line_number++;
        if ( $line !~ $CODE_BLOCK_MARKER ) {
            $rewritten .= "$line\n";
            next LINE;
        }

        # we have found the start or end of a code block such as: ```perl
        my $language = $+{language};
        if ( not $in_code_block ) {
            $in_code_block = $line_number;
            if ($language) {
                $rewritten .=
                  "[% WRAPPER include/code.tt language='$language' -%]\n";
            }
            else {
                $rewritten .= "[% WRAPPER include/code.tt -%]\n";
            }
        }
        else {
            $in_code_block = 0;
            $rewritten .= "[% END %]\n";
        }
    }

    if ($in_code_block) {
        croak("Got to EOF but we're still in a code block starting at line $in_code_block!");
    }
    return $rewritten;
}

sub preprocess_macros ( $file, $contents ) {
warn $file;
    # XXX this is a simplistic heuristic. Need something better in the future.
    if ( $contents =~ m{\[%.*WRAPPER include/wrapper.*blogdown=1.*%\]} ) {

        # we need to preprocess the markdown, replacing '#' headers with their
        # appropriate HTML tag. This allows the subsequent HTML parsing logic
        # to build the TOC, but still allows the bulk of Markdown processing
        # to happen in the templates, where it should be.
        my %replacement_for;
        my $rewritten = '';
        my $in_code_block = 0;
        foreach my $line (split /\n/ => $contents){
            if ( $line =~ $CODE_BLOCK_MARKER ) {
                $in_code_block = $in_code_block ? 0 : 1;
            }
            if ( !$in_code_block && $line =~ /^((#+)\s*(.*))$/ ) {
                my $title     = $3;
                my $this_line = $1;
                my $level     = length($2);
                #$DB::single = 1 if $file =~ /managing/;
                $line       = "<h$level>$title</h$level>";
            }
            $rewritten .= "$line\n";
        }
        $contents = $rewritten;
    }
    my $p = HTML::TokeParser::Simple->new( string => $contents );

    state $seen = {};

    my $rewritten = '';
    my @links;
    while ( my $token = $p->get_token ) {
        if ( $token->is_start_tag(qr/^h[1-6]$/i) ) {
    $DB::single=$file=~/moose/;
            $rewritten .= $token->as_is;
            my $tag = $token->get_tag;
            $tag =~ /^h([1-6])$/i or croak("Bad 'h' tag in $file: $tag");
            my $level = $1;
            my $title = $p->peek(1);
            my $slug  = make_slug($title);
            if ( $seen->{$file}{$slug}++ ) {
                croak("Already seen heading '$title/$slug' in '$file'");
            }
            $rewritten .= qq{<a name="$slug"></a>};
            push @links =>
qq{    <li class="indent-$level"><a href="#$slug">$title</a></li>};
        }
        else {
            $rewritten .= $token->as_is;
        }
    }
    my $links = join "\n" => @links;
    my $toc   = <<"TOC";
<nav role="navigation" class="table-of-contents">
    <ul>
$links
    </ul>
</nav>
<hr>
TOC
    # rewrite the table of contents
    $rewritten =~ s/^s*\{\{TOC\}\}\s*$/$toc/m;

    # remove the tags
    my @tags;
    # XXX This should probably be used in the tag map and pushed into the 
    # template layer.
    if ($rewritten =~ /^s*\{\{TAGS(.*)?\}\}/m ) {
        @tags = sort grep {/\w/} split /\s+/ => $1;
        $rewritten =~ s/^s*\{\{TAGS.*?\}\}\s*$//m;
    }

    return ( $rewritten, \@tags );
}
1;

__END__

=head1 NAME

Less::TTSyntax - Simplify our TT syntax

=head1 SYNOPSIS

    use Less::TTSyntax qw(simplify_tt_code);
    $contents = simplify_tt_code($contents);

=head1 DESCRIPTION

This module runs in the blog preprocess phase, allowing us to use an alternate
syntax for the files, requiring less syntax. Currently it only rewrites this:

    ```$language
    some
    code
    here
    ```

To this:

    [% WRAPPER include/code.tt language='$language' -%]
    some
    code
    here
    [% END %]

The language is optional.
