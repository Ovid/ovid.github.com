package Ovid::Site {

    # this is a straight port of the bin/rebuild script. As such, it's rather
    # sloppy and the `build()` methods need to be called in precise order
    # because some methods set data for subsequent methods
    use Moose;
    use Less::Script;
    use Less::Pager;
    use Less::Config qw(config);
    use Ovid::Types qw(ArrayRef NonEmptySimpleStr HashRef);
    use Ovid::Template::File;
    use Template::Plugin::Ovid;
    use aliased 'Ovid::Template::File::Collection';

    use Capture::Tiny 'capture';
    use DateTime::Format::SQLite;
    use DateTime;
    use File::Basename qw(dirname basename);
    use File::Which qw(which);
    use File::Copy;
    use File::Find::Rule;
    use File::Path qw(mkpath);
    use File::Spec::Functions qw(catfile);
    use HTML::TokeParser::Simple;
    use Mojo::DOM;
    use Mojo::JSON qw(encode_json);
    use XML::RSS;

    has _files => (
        traits  => ['Array'],
        is      => 'rw',
        isa     => ArrayRef [NonEmptySimpleStr],
        handles => {
            count => 'count',
            all   => 'elements',
        },
    );

    has _tagmap => (
        is      => 'rw',
        isa     => HashRef,
        default => sub { {} },
    );

    sub build ($self) {
        $self->_assert_tt_config;
        $self->_set_files('root');
        $self->_preprocess_files;
        $self->_write_tag_templates;
        $self->_write_tagmap;
        $self->_build_tag_js;
        $self->_rebuild_article_pagination;
        $self->_rebuild_rss_feeds;
        $self->_run_ttree;
    }

    sub _build_tag_js ($self) {
       my $ovid = Template::Plugin::Ovid->new(undef);
       my $tags = '';
       foreach my $tag ($ovid->tags) {
            my $count = $ovid->count_for_tag($tag);
            $count = 9 if $count > 9;
            my $name = $ovid->name_for_tag($tag);
            if ($name =~ /'/) {
                die "Bad tagname. Contains a single quote: $name";
            }
            $tags .= qq{<li><a href=\\"/tags/$tag.html\\" data-weight=\\"$count\\">$name</a></li>};
        }
        my $js = <<"END";
// Autogenerated by Ovid::Site::_build_tag_js() via $0
document
    .getElementById("myTags")
    .innerHTML+="$tags";
END
        splat("root/static/js/tags.js", $js);
    }

    sub _set_files ( $self, $location ) {
        my @files = grep { !/\.(?:DS_Store|sw[pon])$/ } File::Find::Rule->file->in($location);
        $self->_files( \@files );
    }

    sub _preprocess_files ($self) {
        my @files = $self->_files->@*;

        # scrub our tmp directory
        system( 'rm', '-fr', 'tmp' );

        # format:
        #     $tag => {
        #         name  => $tagname,
        #         files => [$destfile. $destfile, ... ]
        my %tagmap;
        FILE: foreach my $file (@files) {
            next FILE if $file =~ /\.sw\w$/;    # ignore vim swapfiles
            my $is_tt_file = $file =~ /\.tt(?:2markdown)?$/;

            my $dir  = dirname($file);
            my $name = basename($file);

            if ( $dir !~ /static/ && !$is_tt_file ) {
                next FILE;
            }

            # make sure we have our destination directory
            my $destdir = $dir;
            $destdir =~ s/^root/tmp/;
            unless ( -d $destdir ) {
                mkpath($destdir);
            }

            my $destfile = catfile( $destdir, $name );

            if ( !$is_tt_file ) {

                # not a template toolkit file? Copy it over directly
                copy( $file, $destfile )
                  or croak("Could not copy $file to $destfile: $!");
            }
            else {
                my $parser = Ovid::Template::File->new( filename => $file );

                my $contents = $parser->rewrite( $destfile, \%tagmap )
                  if $is_tt_file;

                splat( $destfile, $contents );
            }
        }
        $self->_tagmap( \%tagmap );
    }

    sub _write_tag_templates($self) {

        # so long as there's a tagmap entry for a tag and an article or blog for
        # that tag, we'll always have a template for it.
        TAG: foreach my $tag ( keys config()->{tagmap}->%* ) {
            my $name     = config()->{tagmap}{$tag};
            my $file     = "root/tags/$tag.tt2markdown";
            my $template = <<~"END";
            [% 
                title = 'Tags: $name';
                type  = 'tags';
                slug  = '$tag';
                USE Ovid;
                WRAPPER include/wrapper.tt blogdown=1;
                    INCLUDE include/tags.tt tag="$tag";
                END;
            %]
            END
            splat( $file, $template );
        }
    }

    sub _write_tagmap($self) {
        my $tagmap = $self->_tagmap;
        foreach my $tag ( keys $tagmap->%* ) {
            next if '__ALL__' eq $tag;
            $tagmap->{$tag}{files} = [ sort $tagmap->{$tag}{files}->@* ];
        }
        splat( config()->{tagmap_file}, encode_json($tagmap) );
    }

    sub _rebuild_rss_feeds ($self) {
        my $base_url = 'https://ovid.github.io/';

        my $types = dbh()->selectall_arrayref(
            'SELECT name, type, directory, description FROM article_types',
            { Slice => {} }
        );

        foreach my $type ( $types->@* ) {
            my $rss_file = "$type->{type}.rss";
            my %already_added;
            if ( -e $rss_file ) {
                my $dom = Mojo::DOM->new( slurp($rss_file) );
                %already_added = map { $_->text => 1 } $dom->find('link')->each;
            }
            my $directory = $type->{directory};
            my $now       = DateTime->now;
            my $year      = $now->year;
            my $rss       = XML::RSS->new( version => '2.0' );
            $rss->add_module(
                prefix => 'atom',
                uri    => 'http://www.w3.org/2005/Atom'
            );
            $rss->channel(
                title       => $type->{description},
                link        => "$base_url$directory",
                description => $type->{description},
                language    => 'en-us',
                copyright   => "Copyright $year, Curtis \"Ovid\" Poe",
                atom        => {
                    'link' => {
                        'href' => "$base_url$type->{type}.rss",
                        'rel'  => 'self',
                        'type' => 'application/rss+xml'
                    }
                },

                # RSS 2.0 requires RFC822 dates
                pubDate        => $now->strftime("%a, %d %b %Y %H:%M:%S %z"),
                managingEditor => 'curtis.poe@gmail.com (Curtis "Ovid" Poe)',
            );
            my $articles = dbh()->selectall_arrayref( <<"SQL", { Slice => {} }, $type->{type} );
    SELECT a.title,
        a.slug,
        a.description,
        a.created
    FROM articles a
    JOIN article_types at ON at.article_type_id = a.article_type_id
    WHERE available = 1 AND at.type = ?
ORDER BY sort_order DESC
SQL

            my $new_links = 0;
            foreach my $article ( $articles->@* ) {
                my $created = DateTime::Format::SQLite->parse_datetime( $article->{created} );
                my $url     = "$base_url$directory/$article->{slug}.html";

                # Every time we changed an article, we kept updating the
                # publication date of the entire RSS feed. Now we only do this if
                # we have found at least one new article/blog entry.
                $new_links++ if not $already_added{$url};

                $rss->add_item(
                    title       => $article->{title},
                    link        => $url,
                    description => $article->{description},
                    creator     => 'Curtis "Ovid" Poe',
                    guid        => "$type->{type}/$article->{slug}",
                    pubDate     => $created->strftime("%a, %d %b %Y %H:%M:%S %z"),
                );
            }
            splat( $rss_file, $rss->as_string ) if $new_links;
        }
    }

    sub _rebuild_article_pagination ($self) {
        foreach my $type (qw/article blog/) {
            my $article_type = article_type($type);
            my $pager        = Less::Pager->new( type => $type );
            while ( my $records = $pager->next ) {
                my $page_number = $pager->current_page_number;
                my $title       = "$article_type->{name} by Ovid";
                if ( $pager->total_pages > 1 ) {
                    $title .= ", page $page_number";
                }
                my $articles   = $self->_get_article_list( $records, $article_type );
                my $pagination = $self->_get_pagination(
                    $pager->total_pages, $page_number,
                    $article_type
                );
                my $name       = $type eq 'article' ? 'articles'             : $type;
                my $identifier = $page_number > 1   ? "${name}_$page_number" : $name;
                my $template   = <<"END";
[%
    title      = '$title';
    identifier = '$identifier';
%]

[% INCLUDE include/header.tt %]

$articles
$pagination
[% IF $page_number == 1 -%]
<script>
    var latestArticle  = document.getElementById("articles").firstElementChild.innerHTML;
    document.getElementById("articles").firstElementChild.innerHTML = '<em>' + latestArticle + '</em> <span class="new">New!</span>'
</script>
[%- END %]

[% INCLUDE include/footer.tt %]
END
                my $article = $self->_article_page( $page_number, $article_type );
                splat( "root/$article.tt", $template );
            }
        }
    }

    sub _get_pagination ( $self, $total, $current, $article_type ) {
        return '' if $total == 1;
        my $pagination = qq{<nav class="pagination">\n};
        if ( $current > 1 ) {
            my $prev    = $current - 1;
            my $article = $self->_article_page( $prev, $article_type );
            $pagination .= qq{    <a href="/$article.html">&laquo;</a>\n};
        }
        else {
            $pagination .= qq{    <span class="inactive">&laquo;</span>\n};
        }
        for my $page ( 1 .. $total ) {
            my $class   = $page == $current ? 'class="active"' : '';
            my $article = $self->_article_page( $page, $article_type );
            $pagination .= qq{    <a $class href="/$article.html">$page</a>\n};
        }
        if ( $current < $total ) {
            my $next    = $current + 1;
            my $article = $self->_article_page( $next, $article_type );
            $pagination .= qq{    <a href="/$article.html">&raquo;</a>\n};
        }
        else {
            $pagination .= qq{    <span class="inactive">&raquo;</span>\n};
        }
        $pagination .= "</nav>";
        return $pagination;
    }

    sub _article_page ( $self, $number, $article_type ) {
        my $directory = $article_type->{directory};
        return 1 == $number ? $directory : "${directory}_$number";
    }

    sub _get_article_list ( $self, $records, $article_type ) {
        my $list = qq{<ul id="articles">\n};
        foreach my $article ( $records->@* ) {
            $list
              .= qq{    <li><a href="/$article_type->{directory}/$article->{slug}.html">$article->{title}</a></li>\n};
        }
        $list .= "</ul>";
        return $list;
    }

    sub _assert_tt_config ($self) {
        unless ( -f "$ENV{HOME}/.ttreerc" ) {
            warn <<"END";
No $ENV{HOME}/.ttreerc file found

It should have a structure like this:

	verbose
	recurse

	color=1

	src  = ~/Dropbox/Mine/projects/perl/ovid.github.com/root
	dest  = ~/Dropbox/Mine/projects/perl/ovid.github.com/

	ignore = \b(CVS|RCS|sw[pot])\b
	ignore = ^#
	ignore = ^.git

	suffix tt=html
	suffix tt2markdown=html
END
            exit 1;
        }
    }

    sub _run_ttree ($self) {
        # XXX my $ttree = which('ttree');
        my @args  = (
            'perl', '-Ilib',                                # make sure we can find our plugins
            'bin/otree',                                    # the ttree command
            '-a',                                           # process all files
            '-s'         => 'tmp',                          # use tmp/ as a source
            '-d'         => '.',                            # use . as the target
            '--copy'     => '\.(gif|png|jpg|jpeg|pdf)$',    # copy, don't process images
            '--binmode'  => 'utf8',                         # encoding of output file
            '--encoding' => 'utf8',                         # encoding of input files
        );
        my ( $stdout, $stderr, $exit ) = capture { system(@args) };

        if ( $stdout =~ /!.*file error/ ) {

            # yeah, ttree needs proper exit codes
            say STDERR "@args";
            croak($stdout);
        }
        say $stdout;
    }

    __PACKAGE__->meta->make_immutable;
}
