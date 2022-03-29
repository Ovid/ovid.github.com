package Ovid::Template::File {

    # yes, this is a bit of a mess because it's a refactoring of what was
    # originally a quick hack. However, the original code was simple and
    # line-based. A proper parser would have an AST and maybe a grammar. Or at
    # least allow me to grab and process a stream of tokens in a procedural
    # style. No, we're doing this line-by-line like it's some damned interpreted
    # BASIC program. It's a perfect example of a simple program accumulating a
    # series of quick hacks until it eventually becomes "legacy code." I have no
    # self-respect.
    #
    # Further, older versions of templates are supported, even though I wish
    # they weren't (e.g., ``` vs WRAPPER for code blocks)
    use Moose;
    use Ovid::Template::File::FindCode;
    use Less::Script;
    use HTML::TokeParser::Simple;
    use Less::Config qw(config);

    has filename => (
        is       => 'rw',
        isa      => 'Str',
        required => 1,
    );

    has _code => (
        is       => 'rw',
        isa      => 'Str',
        required => 1,
        lazy     => 1,
        default  => sub ($self) { slurp( $self->filename ) }
    );

    has debug => (
        is      => 'rw',
        isa     => 'Bool',
        default => 0,
    );

    my @TEMPLATE_ATTRS = qw(title date type slug);
    foreach my $attr (@TEMPLATE_ATTRS) {
        has $attr => (
            is       => 'rw',
            writer   => "_set_$attr",
            isa      => 'Str',
            init_arg => undef,
        );
    }

    has line_number => (
        is       => 'rw',
        isa      => 'Int',
        writer   => '_set_line_number',
        init_arg => undef,
        default  => 0,
    );

    has _lines => (
        is       => 'ro',
        isa      => 'ArrayRef[Str]',
        required => 1,
        lazy     => 1,
        default  => sub ($self) { [ split /\n/ => $self->_code ] },
    );

    has _code_state => (
        is       => 'ro',
        isa      => 'Ovid::Template::File::FindCode',
        required => 1,
        lazy     => 1,
        default  => sub ($self) {
            return Ovid::Template::File::FindCode->new(
                filename => $self->filename,
                debug    => $self->debug,
            );
        },
        handles => [qw/is_in_code language/],
    );

    sub BUILD ( $self, @ ) {
        $self->_set_attrs_from_template;
    }

    # this is used for testing. We probably want to delete it.
    sub next ($self) {
        my @lines = $self->_lines->@*;
        return if $self->line_number + 1 > @lines;
        my $line = $lines[ $self->line_number ];
        $self->_set_line_number( $self->line_number + 1 );
        my $parser        = Ovid::Template::File::FindCode->new(
            filename => $self->filename,
            debug    => $self->debug,
        );
        $self->_code_state->line_number($self->line_number);
        $self->_code_state->parse($line);
        return $line;
    }

    sub rewrite ( $self, $destfile, $tagmap ) {
        my $contents = $self->_rewrite_code_blocks;
        my $tags;

        ( $contents, $tags ) = $self->_preprocess_macros($contents);
        return $self->_build_tags( $contents, $destfile, $tagmap, $tags );
    }

    sub _rewrite_code_blocks ($self) {
        my @lines         = $self->_lines->@*;
        my $rewritten     = '';
        my $in_code_block = 0;
        my $line_number   = 0;
        my $parser        = Ovid::Template::File::FindCode->new(
            filename => $self->filename,
            debug    => $self->debug,
        );
        LINE: foreach my $line (@lines) {
            $line_number++;
            $parser->line_number($line_number);
            $parser->parse($line);

            # we have found the start or end of a code block such as: ```perl
            my $language = $parser->language;
            if ( $parser->is_start_marker ) {
                $in_code_block = $line_number;
                if ($language) {
                    $rewritten .= "[% WRAPPER include/code.tt language='$language' -%]\n";
                }
                else {
                    $rewritten .= "[% WRAPPER include/code.tt -%]\n";
                }
            }
            elsif ( $parser->is_end_marker ) {
                $in_code_block = 0;
                $rewritten .= "[% END %]\n";
            }
            else {
                $rewritten .= "$line\n";
            }
        }

        if ($in_code_block) {
            croak("Got to EOF but we're still in a code block starting at line $in_code_block!");
        }
        return $rewritten;
    }

    sub _build_tags ( $self, $contents, $destfile, $tagmap, $tags ) {
        my $file   = $self->filename;
        my $config = config();
        if ( $tags->@* ) {
            my $title = $self->title
              or croak("Tags found for '$file' but could not determine title");

            # XXX nasty hack alert
            my $url = $destfile;
            $url =~ s{^tmp/}{};
            $url =~ s/\.tt(?:2markdown)?$/.html/;
            $tagmap->{__ALL__}{$url} = $tags;

            foreach my $tag ( $tags->@* ) {
                if ( my $name = $config->{tagmap}{$tag} ) {
                    $tagmap->{$tag}{name} = $name;
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

    sub _preprocess_macros ( $self, $contents ) {
        my $file = $self->filename;

        $self->_debug($contents);

        # XXX this is a simplistic heuristic. Need something better in the 
        # future.
        if ( $contents =~ m{\[%.*WRAPPER include/wrapper.*blogdown=1.*%\]} ) {

            # we need to preprocess the markdown, replacing '#' headers with their
            # appropriate HTML tag. This allows the subsequent HTML parsing logic
            # to build the TOC, but still allows the bulk of Markdown processing
            # to happen in the templates, where it should be.
            my $rewritten = '';
            my $parser = Ovid::Template::File::FindCode->new( filename => $file );
            my $line_number = 1;
            foreach my $line ( split /\n/ => $contents ) {
                $parser->line_number($line_number);
                $line_number++;
                $parser->parse($line);
                if ( !$parser->is_in_code && $line =~ /^((#+)(.*))$/ ) {
                    my $title = trim($3);
                    my $level = length($2);
                    $line = "<h$level>$title</h$level>";
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
                push @links => qq{    <li class="indent-$level"><a href="#$slug">$title</a></li>};
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
        if ( $rewritten =~ /^s*\{\{TAGS(.*)?\}\}/m ) {
            @tags = sort grep {/\w/} split /\s+/ => $1;
            $rewritten =~ s/^s*\{\{TAGS.*?\}\}\s*$//m;
        }

        return ( $rewritten, \@tags );
    }

    sub _set_attrs_from_template ($self) {
        state $is_required = { map { $_ => 1 } @TEMPLATE_ATTRS };

        # many pages don't have titles, so it's ok to skip them
        if ( $self->_code =~ m{\s*\[%(.*?)\[%.*?(?:INCLUDE|WRAPPER).*?%\]}s ) {
            my $header = $1;
            foreach my $line ( split /\n/ => $header ) {
                my ( $key, $value ) = map { trim($_) } split /=/ => $line;
                next unless $key && $is_required->{$key} && $value;
                my $set_attr = "_set_$key";
                $value =~ s/;$//;
                $value =~ s/^['"]//;
                $value =~ s/['"]$//;
                $self->$set_attr($value);
            }
        }
    }

    sub _debug ( $self, $message ) {
        return unless $self->debug;
        my $filename = $self->filename;
        if ( my $line_number = $self->line_number ) {
            say STDERR "$filename/$line_number: $message";
        }
        else {
            say STDERR "$filename: $message";
        }
    }

    __PACKAGE__->meta->make_immutable;
}
