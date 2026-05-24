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
    use Ovid::Types  qw(
      ArrayRef
      InstanceOf
      NonEmptySimpleStr
      NonEmptyStr
      Str
    );
    with qw(
      Ovid::Template::Role::Debug
      Ovid::Template::Role::File
    );

    has _code => (
        is       => 'rw',
        isa      => NonEmptyStr,
        required => 1,
        lazy     => 1,
        default  => sub ($self) { slurp( $self->filename ) }
    );

    my @TEMPLATE_ATTRS = qw(title date type slug tags);
    foreach my $attr (@TEMPLATE_ATTRS) {
        has $attr => (
            is       => 'rw',
            isa      => $attr eq 'tags' ? ArrayRef [NonEmptySimpleStr] : NonEmptySimpleStr,
            writer   => "_set_$attr",
            init_arg => undef,
        );
    }

    has _lines => (
        is       => 'ro',
        isa      => ArrayRef [Str],                                   # some lines are empty strings
        required => 1,
        lazy     => 1,
        default  => sub ($self) { [ split /\n/ => $self->_code ] },
    );

    has _code_state => (
        is       => 'ro',
        isa      => InstanceOf ['Ovid::Template::File::FindCode'],
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

    # TODO (Coverage Improvement 001): Verify if still needed or can be removed
    # Comment says "this is used for testing. We probably want to delete it."
    # Check if any tests or templates depend on this before removal.
    # See: specs/001-test-coverage-improvement/unused-code-decisions.md
    # this is used for testing. We probably want to delete it.
    sub next ($self) {
        my @lines = $self->_lines->@*;
        return if $self->line_number + 1 > @lines;
        my $line = $lines[ $self->line_number ];
        $self->_set_line_number( $self->line_number + 1 );
        my $parser = Ovid::Template::File::FindCode->new(
            filename => $self->filename,
            debug    => $self->debug,
        );
        $self->_code_state->_set_line_number( $self->line_number );
        $self->_code_state->parse($line);
        return $line;
    }

    # TODO (Coverage Improvement 001): Verify usage in build scripts
    # May be administrative/build function. Check bin/rebuild and other scripts.
    # See: specs/001-test-coverage-improvement/unused-code-decisions.md
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
            $parser->_set_line_number($line_number);
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
            my $tagmap_key = $destfile;
            $tagmap_key =~ s{^tmp/}{};
            $tagmap_key =~ s/\.tt(?:2markdown)?$//;
            $tagmap->{__ALL__}{$tagmap_key} = $tags;

            foreach my $tag ( $tags->@* ) {
                if ( my $name = $config->{tagmap}{$tag} ) {
                    $tagmap->{$tag}{name} = $name;
                    $tagmap->{$tag}{count}++;
                    $tagmap->{$tag}{files} //= [];
                    $tagmap->{$tag}{titles}{$tagmap_key} = $title;
                    push $tagmap->{$tag}{files}->@* => $tagmap_key;
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
            my $rewritten   = '';
            my $parser      = Ovid::Template::File::FindCode->new( filename => $file );
            my $line_number = 1;
            foreach my $line ( split /\n/ => $contents ) {
                $parser->_set_line_number($line_number);
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

        my $seen = {};

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

                    # we've already seen it, so let's prepend the number on the
                    # heading slug so we can have unique links
                    $slug = "$slug-$seen->{$file}{$slug}";
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

    __PACKAGE__->meta->make_immutable;
}

__END__

=head1 NAME

Ovid::Template::File - Preprocessor for individual Template Toolkit source files

=head1 SYNOPSIS

    use Ovid::Template::File;

    my $file = Ovid::Template::File->new( filename => 'root/blog/my-post.tt' );

    # Access metadata extracted from the template preamble
    say $file->title;    # 'My Post Title'
    say $file->date;     # '2025-11-16'
    say $file->type;     # 'article' or 'blog'
    say $file->slug;     # 'my-post'
    say $file->tags;     # ['perl', 'testing']

    # Preprocess and rewrite the file for the build pipeline
    my $tagmap = {};
    my $contents = $file->rewrite( 'tmp/blog/my-post.tt', $tagmap );

=head1 DESCRIPTION

C<Ovid::Template::File> handles preprocessing of a single Template Toolkit
source file (C<.tt> or C<.tt2markdown>) as part of the site build pipeline.
On construction, it parses the template preamble to extract metadata such as
title, date, type, slug, and tags.

The C<rewrite> method performs the full preprocessing pass: converting
triple-tilde fenced code blocks into C<[% WRAPPER include/code.tt %]>
directives, expanding C<{{TOC}}> markers into a generated table of contents,
extracting C<{{TAGS ...}}> declarations into a tag map, and converting
Markdown headings into HTML with anchor links.

This module consumes the L<Ovid::Template::Role::Debug> and
L<Ovid::Template::Role::File> roles, and delegates code block detection to
L<Ovid::Template::File::FindCode>.

=head1 METHODS

=head2 new

    my $file = Ovid::Template::File->new(
        filename => 'root/articles/some-article.tt',
    );

Constructor. Requires C<filename>, the path to a Template Toolkit source
file. Automatically parses the template preamble to populate metadata
attributes.

=head2 title

    my $title = $file->title;

Returns the article title extracted from the template preamble, or C<undef>
if not present.

=head2 date

    my $date = $file->date;

Returns the publication date string from the template preamble.

=head2 type

    my $type = $file->type;

Returns the content type (typically C<'article'> or C<'blog'>).

=head2 slug

    my $slug = $file->slug;

Returns the URL slug for the content.

=head2 tags

    my $tags = $file->tags;    # arrayref of strings

Returns an arrayref of tag strings declared in the template preamble.

=head2 rewrite

    my $contents = $file->rewrite( $destfile, $tagmap );

Preprocesses the template file and returns the rewritten content as a string.
This method:

=over 4

=item * Converts triple-tilde fenced code blocks (e.g., C<~~~perl>) into
Template Toolkit C<WRAPPER> directives for syntax highlighting.

=item * Converts Markdown headings (C<#>, C<##>, etc.) into HTML heading
tags with anchor links.

=item * Generates a table of contents from headings and inserts it at the
C<{{TOC}}> marker.

=item * Extracts C<{{TAGS tag1 tag2 ...}}> declarations and populates the
provided C<$tagmap> hashref with tag metadata including file URLs and titles.

=back

C<$destfile> is the destination path (used to derive the URL for the tag
map). C<$tagmap> is a hashref that accumulates tag data across multiple
files during a build.

=head2 next

    my $line = $file->next;

Returns the next line from the file, advancing the internal line counter and
updating code block state. Returns C<undef> when all lines have been
consumed. Primarily used for testing.

=head2 is_in_code

    if ( $file->is_in_code ) { ... }

Returns true if the current line position is inside a code block. Delegated
from L<Ovid::Template::File::FindCode>.

=head2 language

    my $lang = $file->language;

Returns the language identifier for the current code block (e.g., C<'perl'>),
or C<undef> if not in a code block or no language was specified. Delegated
from L<Ovid::Template::File::FindCode>.

=cut
