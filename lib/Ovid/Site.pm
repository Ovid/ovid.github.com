package Ovid::Site {

    # this is a straight port of the bin/rebuild script. As such, it's rather
    # sloppy and the `build()` methods need to be called in precise order
    # because some methods set data for subsequent methods
    use Moose;
    use Less::Script;
    use Less::Pager;
    use Less::Config qw(config);
    use Ovid::Types  qw(ArrayRef NonEmptySimpleStr HashRef);
    use Ovid::Template::File;
    use Template::Plugin::Ovid;
    use aliased 'Ovid::Template::File::Collection';

    use autodie ':all';
    use Capture::Tiny 'capture';
    use Cwd 'abs_path';
    use DateTime::Format::SQLite;
    use DateTime;
    use File::Basename qw(dirname basename);
    use File::Which    qw(which);
    use File::Copy;
    use File::Find::Rule;
    use File::Path            qw(mkpath);
    use File::Spec::Functions qw(catfile);
    use HTML::TokeParser::Simple;
    use Mojo::DOM;
    use Path::Tiny;
    use File::Find::Rule;
    use POSIX               qw(strftime);
    use IPC::System::Simple ();

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

    has _base_url => (
        is      => 'ro',
        isa     => NonEmptySimpleStr,
        default => 'https://curtispoe.org/',
    );

    has _tagmap => (
        is      => 'rw',
        isa     => HashRef,
        default => sub { {} },
    );

    has release => (
        is      => 'ro',
        isa     => 'Bool',
        default => 0,
    );

    has file => (
        is       => 'ro',
        isa      => NonEmptySimpleStr,
        required => 0,
    );

    sub build ($self) {
        say STDERR "Preprocessing files ...";
        if ( $self->file ) {
            return $self->_build_single_file;
        }
        $self->_assert_tt_config;
        $self->_set_files('root');
        $self->_preprocess_files;
        $self->_write_tag_templates;
        $self->_write_tagmap;
        $self->_rebuild_rss_feeds;
        $self->_rebuild_article_pagination;
        $self->_run_ttree;
        $self->_write_sitemap;
        $self->_build_tinysearch if $self->release;
    }

    sub _build_single_file ($self) {
        printf STDERR "Rebuilding single file: %s\n", $self->file;

        $self->_clean_tmp_directory;

        # First, we need to do a full preprocess to build the tagmap
        # and other context that templates might need.
        say STDERR "Preprocessing all files to build context...";
        $self->_assert_tt_config;
        $self->_set_files('root');
        $self->_preprocess_files;
        $self->_write_tag_templates;
        $self->_write_tagmap;
        $self->_rebuild_rss_feeds;
        $self->_rebuild_article_pagination;

        # Now find the path to our target file in the 'tmp' directory
        my $file = $self->file;
        $file = $self->_copy_to_tmp($file);

        say STDERR "Running ttree on $file";
        $self->_run_ttree_single($file);

        # We should probably update the sitemap too
        $self->_write_sitemap;
        say STDERR "Single file rebuild complete.";
    }

    sub _run_ttree_single ( $self, $file ) {

        # Die if the source file doesn't exist so we know where the problem is.
        unless ( -f $file ) {
            die "FATAL: Source file '$file' does not exist before calling ttree.";
        }

        # The file path for ttree must be relative to the --src directory
        my $relative_file = $file;
        $relative_file =~ s/^tmp\///;

        my ( $stdout, $stderr ) = $self->_execute_ttree(
            '--verbose',
            '--lib=include',
            $relative_file,
        );

        print $stdout;
        print $stderr;
    }

    sub _set_files ( $self, $location ) {
        my @files = grep { !/\.(?:DS_Store|sw[pon])$/ } File::Find::Rule->file->in($location);
        $self->_files( \@files );
    }

    sub _clean_tmp_directory ($self) {

        # scrub our tmp directory
        system( 'rm', '-fr', 'tmp' );

    }

    sub _preprocess_files ($self) {
        my @files = $self->_files->@*;
        $self->_clean_tmp_directory;

        # format:
        #     $tag => {
        #         name  => $tagname,
        #         files => [$destfile. $destfile, ... ]
        my %tagmap;
        FILE: foreach my $file (@files) {
            next FILE if $file =~ /\.sw\w$/;    # ignore vim swapfiles
            $self->_copy_to_tmp( $file, \%tagmap );
        }
        $self->_tagmap( \%tagmap );
    }

    sub _copy_to_tmp ( $self, $file, $tagmap = {} ) {
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

            my $contents = $parser->rewrite( $destfile, $tagmap )
              if $is_tt_file;

            splat( $destfile, $contents );
        }
        return $destfile;
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
            my $base_url  = $self->_base_url;
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
            my $name         = $type eq 'article' ? 'articles' : $type;

            # Handle paginated versions
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
                my $identifier = $page_number > 1 ? "${name}_$page_number" : $name;
                my $template   = <<~"END";
                [%
                    INCLUDE include/header.tt 
                    title         = '$title'
                    identifier    = '$identifier'
                    canonical_url = "$name-all.html"
                %]

                $articles

                <p><a href="/$name-all.html">All $article_type->{name} in a single page</a></p>

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

            # Handle "all" version
            my $all_records = $pager->all;
            my $title       = "All $article_type->{name} by Ovid";
            my $identifier  = "$name-all";
            my $articles    = $self->_get_article_list( $all_records, $article_type );
            my $template    = <<~"END";
            [%
                INCLUDE include/header.tt 
                title         = '$title'
                identifier    = '$identifier'
                canonical_url = "$name-all.html"
            %]

            $articles

            [% INCLUDE include/footer.tt %]
            END
            splat( "root/${name}-all.tt", $template );
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

    src  = ~/website/root
    dest  = ~/website

    ignore = \b(CVS|RCS|sw[pot])\b
    ignore = ^#
    ignore = ^.git

    suffix tt=html
    suffix tt2markdown=html
END
            exit 1;
        }
    }

    sub _execute_ttree ( $self, @args ) {
        my $ttree = which('ttree');
        unless ($ttree) {
            die "Could not find ttree command in PATH\n";
        }

        my @command = (
            'perl', '-Ilib',
            $ttree,
            '--src=tmp',
            '--dest=.',
            '--binmode'  => 'utf8',
            '--encoding' => 'utf8',
            @args
        );

        if ( grep { $_ eq '--verbose' } @args ) {
            say STDERR "Running command: @command";
        }

        my ( $stdout, $stderr, $exit ) = capture { system(@command) };

        if ( $exit != 0 ) {
            say STDERR "Command failed: @command";
            die "ttree failed with exit code $exit.\nSTDOUT:\n$stdout\nSTDERR:\n$stderr\n";
        }

        if ( $stdout =~ /!.*file error/ ) {
            say STDERR "Command failed: @command";
            croak($stdout);
        }

        return ( $stdout, $stderr );
    }

    sub _run_ttree ($self) {
        say STDERR "Rebuilding pages...";
        my ($stdout) = $self->_execute_ttree(
            '-a',
            '--copy' => '\.(gif|png|jpg|jpeg|pdf)$',
        );
        say $stdout;
    }

    sub _get_git_lastmod ( $self, $file ) {    # for sitemap

        # Try to get the last commit date for the file
        my $git_date;
        eval {
            $git_date = IPC::System::Simple::capture( 'git', 'log', '-1', '--format=%ai', $file );
            chomp($git_date);
        };

        if ( $@ || !$git_date ) {

            # If git command fails or returns empty (file not in git),
            # fall back to file mtime
            return strftime( "%Y-%m-%d", localtime( path($file)->stat->mtime ) );
        }

        # Git date format is like "2024-01-06 12:34:56 -0500"
        # Extract just the date part
        if ( $git_date =~ /^(\d{4}-\d{2}-\d{2})/ ) {
            return $1;
        }

        # Fallback to file mtime if git date parsing fails
        return strftime( "%Y-%m-%d", localtime( path($file)->stat->mtime ) );
    }

    # Function to determine priority based on filename and path
    sub _get_sitemap_priority ( $self, $path ) {
        my $file   = $path->basename;
        my $parent = $path->parent->stringify;

        # Homepage gets highest priority
        return 1.0 if $file eq 'index.html';

        # Main section pages (no number suffix)
        return 0.8 if $file =~ /^(articles|blog|videos)\.html$/;

        # Second pages in pagination
        return 0.6 if $file =~ /^(articles|blog)_2\.html$/;

        # Third pages in pagination
        return 0.5 if $file =~ /^(articles|blog)_3\.html$/;

        # Further pagination
        return 0.4 if $file =~ /^(articles|blog)_\d+\.html$/;

        # Articles and blog posts in subdirectories
        return 0.6 if $file =~ /\.html$/ && ( $parent eq 'articles' || $parent eq 'blog' );

        # Other main pages
        return 0.7 if $file =~ /\.html$/;

        # Default priority for everything else
        return 0.5;
    }

    sub _get_change_frequency ( $self, $path ) {    # for sitemap
        my $file = $path->basename;

        # always  = For pages that change with every access
        # hourly  = For pages that change multiple times per day
        # daily   = News homepages, daily blogs, etc.
        # weekly  = Weekly columns, regular blog posts
        # monthly = Regular but infrequent updates
        # yearly  = Archive pages, static content that rarely changes
        # never   = Historical archives, permalink pages

        my %frequency_for = (
            'index.html'    => 'monthly',
            'articles.html' => 'weekly',
            'blog.html'     => 'weekly',
            'videos.html'   => 'yearly',
        );

        if ( my $freq = $frequency_for{$file} ) {
            return $freq;
        }
        return 'monthly' if $file =~ /^(articles|blog)_\d+\.html$/;

        # These are articles and blog posts. Typically they only receive updates
        # for typos or other minor changes, so we'll default to yearly
        return 'yearly';    # default for other pages
    }

    sub _write_sitemap ($self) {

        # Find all HTML files
        my @files = File::Find::Rule->file()    # only files
          ->name('*.html')                      # with a .html extension
          ->relative                            # with relative paths
          ->in('.');                            # starting in the current directory

        # Start XML output
        my $xml = <<~"XML";
        <?xml version="1.0" encoding="UTF-8"?>
        <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        XML

        my $base_url = $self->_base_url;
        $base_url =~ s/\/$//;                   # Remove trailing slash if present

        # Process files
        for my $file (@files) {
            my $path = path($file);

            # Skip subdirectories unless articles or blog
            next if $path->parent ne '.' && $path->parent !~ /^(articles|blog)$/;

            my $priority   = $self->_get_sitemap_priority($path);
            my $changefreq = $self->_get_change_frequency($path);
            my $lastmod    = $self->_get_git_lastmod($file);

            $xml .= <<~"XML";
                <url>
                    <loc>$base_url/$file</loc>
                    <lastmod>$lastmod</lastmod>
                    <changefreq>$changefreq</changefreq>
                    <priority>$priority</priority>
                </url>
            XML
        }

        # End XML output
        $xml .= '</urlset>';
        my $sitemap = path('sitemap.xml');
        $sitemap->spew_utf8($xml);
    }

    sub _build_tinysearch($self) {

        # see https://github.com/tinysearch/tinysearch
        # needed to run `cargo install --features="bin" tinysearch` for installation
        # and rerun `cargo install wasm-pack` for wasm-pack
        my @files = qw(
          hireme.html
          index.html
          publicspeaking.html
          starmap.html
          tau-station.html
          wildagile.html
        );
        push @files => File::Find::Rule->file()->name('*.html')->in(qw/blog articles/);

        my @index;
        foreach my $file (@files) {
            my ( $title, $text ) = $self->_html_to_text($file);

            # I can't get tinysearch to handle the UTF-8 correctly
            $title =~ s/[”“]/"/g;
            $title =~ s/[‘’]/'/g;
            my $url = $file =~ /^\// ? $file : "/$file";
            push @index => { url => $url, title => $title, body => $text };
        }
        my $json = encode_json( \@index );
        splat( 'fixtures/index.json', $json );

        # building search engine
        system("tinysearch fixtures/index.json");

        # copying neccessary files to static/js/search
        system("cp wasm_output/* static/js/search");
    }

    sub _html_to_text ( $self, $file ) {
        my $html   = slurp($file);                                       # This handles UTF8 correctly
        my $parser = HTML::TokeParser::Simple->new( string => $html );

        my $title;
        my $text = '';
        my $in_article;
        while ( my $token = $parser->get_token ) {
            if ( $token->is_start_tag('article') ) {
                $in_article = 1;
            }
            elsif ( $token->is_end_tag('article') ) {
                $in_article = 0;
            }
            if ( $token->is_start_tag('title') ) {
                $title = $parser->get_trimmed_text;
            }
            elsif ( $in_article && $token->is_text ) {
                $text .= $self->_clean_text( $token->as_is ) . ' ';
            }
        }
        return ( $title, $text );
    }

    sub _clean_text ( $self, $text ) {
        $text =~ s/^\s+//;
        $text =~ s/\s+$//;
        $text =~ s/\s+/ /g;
        return $text;
    }

    __PACKAGE__->meta->make_immutable;
}
