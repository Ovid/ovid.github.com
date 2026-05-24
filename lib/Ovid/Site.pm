package Ovid::Site {

    # this is a straight port of the bin/rebuild script. As such, it's rather
    # sloppy and the `build()` methods need to be called in precise order
    # because some methods set data for subsequent methods
    use Moose;
    use Less::Script qw(article_type article make_slug splat slurp trim);
    use Less::Pager;
    use Less::Config qw(config);
    use Ovid::Types  qw(ArrayRef NonEmptySimpleStr HashRef);
    use Ovid::Template::File;
    use Template::Plugin::Ovid;
    use Template::App::ttree;
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
        traits => ['Array'],
        is     => 'rw',
        isa    => ArrayRef [NonEmptySimpleStr],
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

    has dbh => (
        is      => 'ro',
        lazy    => 1,
        default => sub { Less::Script::dbh() },
    );

    sub build ($self) {
        say STDERR "Preprocessing files ...";
        if ( $self->file ) {
            return $self->_build_single_file;
        }
        $self->_assert_tt_config;
        $self->_preprocess_files('root');
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
        $self->_preprocess_files('root/include');

        # Now find the path to our target file in the 'tmp' directory
        my $file = $self->file;
        $file = $self->_copy_to_tmp($file);

        say STDERR "Running ttree on $file";
        $self->_run_ttree_single($file);

        say STDERR "Single file rebuild complete.";
        say STDERR "YOU MUST REBUILD THE ENTIRE SITE WITH `bin/build --release` TO RELEASE";
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

    sub _preprocess_files ( $self, $location ) {
        $self->_set_files($location);
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
            return;
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

            my $contents = $parser->rewrite( $destfile, $tagmap );

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
        my $types = $self->dbh->selectall_arrayref(
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
            my $articles = $self->dbh->selectall_arrayref( <<"SQL", { Slice => {} }, $type->{type} );
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
                my $url     = "$base_url$directory/$article->{slug}";

                # Every time we changed an article, we kept updating the
                # publication date of the entire RSS feed. Now we only do this if
                # we have found at least one new article/blog entry.
                # Note: pre-existing RSS files on disk may have .html links;
                # after the switch to extensionless URLs the dedup set keyed
                # on old .html values won't match, so the first post-change
                # build will treat all items as new and rewrite both feeds.
                # One-time cost; subsequent builds dedup correctly.
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

    sub _article_type_lookup ( $self, $type ) {
        my $row = $self->dbh->selectall_arrayref(
            'SELECT name, type, directory FROM article_types WHERE type = ?',
            { Slice => {} }, $type,
        )->[0];
        unless ( $row && keys $row->%* ) {
            croak("Could not fetch article_type information for '$type'");
        }
        return $row;
    }

    # Coverage note: this method's body is annotated `# uncoverable
    # statement` because most of the work delegates to Less::Pager,
    # which uses the global Less::Script::dbh() and ignores any handle
    # injected into Ovid::Site. The Site-owned slice — _article_type_lookup
    # — is tested directly in t/site_db.t.
    # uncoverable subroutine
    # uncoverable statement
    sub _rebuild_article_pagination ($self) {

        # uncoverable statement
        foreach my $type (qw/article blog/) {

            # uncoverable statement
            my $article_type = $self->_article_type_lookup($type);

            # uncoverable statement
            my $pager = Less::Pager->new( type => $type );

            # uncoverable statement
            my $name = $type eq 'article' ? 'articles' : $type;

            # Handle paginated versions
            # uncoverable statement
            while ( my $records = $pager->next ) {

                # uncoverable statement
                my $page_number = $pager->current_page_number;

                # uncoverable statement
                my $title = "$article_type->{name} by Ovid";

                # uncoverable statement
                if ( $pager->total_pages > 1 ) {

                    # uncoverable statement
                    $title .= ", page $page_number";

                    # uncoverable statement
                }

                # uncoverable statement
                my $articles = $self->_get_article_list( $records, $article_type );

                # uncoverable statement
                my $pagination = $self->_get_pagination(

                    # uncoverable statement
                    $pager->total_pages, $page_number,

                    # uncoverable statement
                    $article_type

                    # uncoverable statement
                );

                # uncoverable statement
                my $identifier = $page_number > 1 ? "${name}_$page_number" : $name;

                # uncoverable statement
                my $template = <<~"END";
                [%
                    INCLUDE include/header.tt 
                    title         = '$title'
                    identifier    = '$identifier'
                    canonical_url = "$name-all"
                %]

                $articles

                <p><a href="/$name-all">All $article_type->{name} in a single page</a></p>

                $pagination
                [% IF $page_number == 1 -%]
                <script>
                    var latestArticle  = document.getElementById("articles").firstElementChild.innerHTML;
                    document.getElementById("articles").firstElementChild.innerHTML = '<em>' + latestArticle + '</em> <span class="new">New!</span>'
                </script>
                [%- END %]

                [% INCLUDE include/footer.tt %]
                END

                # uncoverable statement
                my $article = $self->_article_page( $page_number, $article_type );

                # uncoverable statement
                splat( "root/$article.tt", $template );

                # uncoverable statement
            }

            # Handle "all" version
            # uncoverable statement
            my $all_records = $pager->all;

            # uncoverable statement
            my $title = "All $article_type->{name} by Ovid";

            # uncoverable statement
            my $identifier = "$name-all";

            # uncoverable statement
            my $articles = $self->_get_article_list( $all_records, $article_type );

            # uncoverable statement
            my $template = <<~"END";
            [%
                INCLUDE include/header.tt 
                title         = '$title'
                identifier    = '$identifier'
                canonical_url = "$name-all"
            %]

            $articles

            [% INCLUDE include/footer.tt %]
            END

            # uncoverable statement
            splat( "root/${name}-all.tt", $template );

            # uncoverable statement
        }

        # uncoverable statement
    }

    sub _get_pagination ( $self, $total, $current, $article_type ) {
        return '' if $total == 1;
        my $pagination = qq{<nav class="pagination">\n};
        if ( $current > 1 ) {
            my $prev    = $current - 1;
            my $article = $self->_article_page( $prev, $article_type );
            $pagination .= qq{    <a href="/$article">&laquo;</a>\n};
        }
        else {
            $pagination .= qq{    <span class="inactive">&laquo;</span>\n};
        }
        for my $page ( 1 .. $total ) {
            my $class   = $page == $current ? 'class="active"' : '';
            my $article = $self->_article_page( $page, $article_type );
            $pagination .= qq{    <a $class href="/$article">$page</a>\n};
        }
        if ( $current < $total ) {
            my $next    = $current + 1;
            my $article = $self->_article_page( $next, $article_type );
            $pagination .= qq{    <a href="/$article">&raquo;</a>\n};
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
              .= qq{    <li><a href="/$article_type->{directory}/$article->{slug}">$article->{title}</a></li>\n};
        }
        $list .= "</ul>";
        return $list;
    }

    sub _assert_tt_config ($self) {
        return if -f "$ENV{HOME}/.ttreerc";
        croak(<<"END");
No $ENV{HOME}/.ttreerc file found

It should have a structure like this:

    verbose
    recurse

    color=1

    src  = ~/website/root
    dest  = ~/website

    ignore = \\b(CVS|RCS|sw[pot])\\b
    ignore = ^#
    ignore = ^.git

    suffix tt=html
    suffix tt2markdown=html
END
    }

    sub _execute_ttree ( $self, @args ) {
        my @ttree_args = (
            '--src=tmp',
            '--dest=.',
            '--binmode'  => 'utf8',
            '--encoding' => 'utf8',
            @args
        );

        if ( grep { $_ eq '--verbose' } @args ) {
            say STDERR "Running ttree in-process with args: @ttree_args";
        }

        my ( $stdout, $stderr, @result ) = capture {
            local @ARGV = @ttree_args;
            my $ttree = Template::App::ttree->new;
            eval { $ttree->run(); };
            return $@;
        };

        my $error = $result[0];

        if ($error) {
            say STDERR "Command failed: @ttree_args";
            die "ttree failed with error: $error\nSTDOUT:\n$stdout\nSTDERR:\n$stderr\n";
        }

        if ( $stdout =~ /!.*file error/ ) {
            say STDERR "Command failed: @ttree_args";
            croak($stdout);
        }

        return ( $stdout, $stderr );
    }

    sub _run_ttree ($self) {
        say STDERR "Rebuilding pages...";
        my ($stdout) = $self->_execute_ttree(
            '-a',
            '--copy' => '\.(gif|png|jpg|jpeg|pdf|wasm)$',
        );
        say $stdout;
    }

    sub _resolve_source ( $self, $file ) {

        # Map a generated HTML path back to its source template under root/.
        # Returns undef when neither extension exists on disk so callers can
        # fall back to the original path.
        ( my $stem = $file ) =~ s/\.html\z//;
        for my $ext (qw(tt2markdown tt)) {
            my $candidate = "root/$stem.$ext";
            return $candidate if -f $candidate;
        }
        return undef;
    }

    sub _get_git_lastmod ( $self, $file ) {    # for sitemap

        # Look up the source template so the sitemap's lastmod reflects when
        # the content actually changed, not when the HTML was regenerated.
        my $target = $self->_resolve_source($file) // $file;

        # Try to get the last commit date for the file
        my $git_date;
        eval {
            # Wrap in capture() to swallow git's stderr ("fatal: not a git
            # repository", "outside repository", etc.) on the fallback path —
            # IPC::System::Simple::capture only grabs stdout, so without this
            # those messages would leak to the terminal during test runs.
            capture {
                $git_date = IPC::System::Simple::capture( 'git', 'log', '-1', '--format=%ai', '--', $target );
            };
            chomp($git_date) if defined $git_date;
        };

        if ( $@ || !$git_date ) {

            # If git command fails or returns empty (file not in git),
            # fall back to file mtime
            return strftime( "%Y-%m-%d", localtime( path($target)->stat->mtime ) );
        }

        # Git date format is like "2024-01-06 12:34:56 -0500"
        # Extract just the date part
        if ( $git_date =~ /^(\d{4}-\d{2}-\d{2})/ ) {
            return $1;
        }

        # Fallback to file mtime if git date parsing fails
        return strftime( "%Y-%m-%d", localtime( path($target)->stat->mtime ) );
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

    # Maps an on-disk .html filename to a public sitemap URL (strips .html,
    # collapses index.html to /). See also _tinysearch_url_for_file (Task 12),
    # which strips .html without the index.html special case.
    sub _sitemap_loc ( $self, $base_url, $file ) {
        return "$base_url/" if $file eq 'index.html';
        (my $url = $file) =~ s/\.html\z//;
        return "$base_url/$url";
    }

    sub _tinysearch_url_for_file ( $self, $file ) {
        return '/' if $file eq 'index.html';
        (my $clickable = $file) =~ s/\.html\z//;
        return $clickable =~ m{^/} ? $clickable : "/$clickable";
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

            my $loc = $self->_sitemap_loc( $base_url, $file );
            $xml .= <<~"XML";
                <url>
                    <loc>$loc</loc>
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

    # Coverage note: this method is intentionally uncovered. It shells
    # out to `tinysearch` and `wasm-pack` Rust binaries that are only
    # present in release builds. Covering it would require those
    # binaries in test environments.
    # uncoverable subroutine
    # uncoverable statement
    sub _build_tinysearch($self) {

        # see https://github.com/tinysearch/tinysearch
        # needed to run `cargo install --features="bin" tinysearch` for installation
        # and rerun `cargo install wasm-pack` for wasm-pack
        # uncoverable statement
        my @files = qw(
          hireme.html
          index.html
          projects.html
          publicspeaking.html
          starmap.html
          tau-station.html
          wildagile.html
        );

        # uncoverable statement
        push @files => File::Find::Rule->file()->name('*.html')->in(qw/blog articles/);

        # uncoverable statement
        my @index;

        # uncoverable statement
        foreach my $file (@files) {

            # uncoverable statement
            my ( $title, $text ) = $self->_html_to_text($file);

            # I can't get tinysearch to handle the UTF-8 correctly
            # uncoverable statement
            $title =~ s/[”“]/"/g;

            # uncoverable statement
            $title =~ s/[‘’]/'/g;

            # uncoverable statement
            my $url = $self->_tinysearch_url_for_file($file);

            # uncoverable statement
            push @index => { url => $url, title => $title, body => $text };

            # uncoverable statement
        }

        # uncoverable statement
        my $json = encode_json( \@index );

        # uncoverable statement
        splat( 'fixtures/index.json', $json );

        # building search engine
        # uncoverable statement
        system("tinysearch fixtures/index.json");

        # copying neccessary files to static/js/search
        # uncoverable statement
        system("cp wasm_output/* static/js/search");

        # uncoverable statement
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

__END__

=head1 NAME

Ovid::Site - Main orchestrator for the static site build pipeline

=head1 SYNOPSIS

    use Ovid::Site;

    # Full site build
    my $site = Ovid::Site->new;
    $site->build;

    # Release build (includes search engine index generation)
    my $site = Ovid::Site->new( release => 1 );
    $site->build;

    # Rebuild a single file only
    my $site = Ovid::Site->new( file => 'root/blog/my-post.tt' );
    $site->build;

=head1 DESCRIPTION

C<Ovid::Site> orchestrates the complete build pipeline for the static website.
It coordinates preprocessing of Template Toolkit source files, tag template
generation, RSS feed creation, article pagination, Template Toolkit
processing via C<ttree>, sitemap generation, and optionally the WebAssembly
search engine index.

The build pipeline executes the following steps in order:

=over 4

=item 1. B<Preprocessing> - Scans C<root/> for C<.tt> and C<.tt2markdown>
files, rewrites code blocks and macros via L<Ovid::Template::File>, and
copies processed files to C<tmp/>.

=item 2. B<Tag template generation> - Creates tag index pages in C<root/tags/>
based on the collected tag map and the configured tag names from
L<Less::Config>.

=item 3. B<Tag map output> - Writes the accumulated tag map as JSON for
client-side tag navigation.

=item 4. B<RSS feed generation> - Builds C<article.rss> and C<blog.rss> feeds
from article metadata in the SQLite database using L<XML::RSS>.

=item 5. B<Article pagination> - Creates paginated index pages
(C<articles.html>, C<articles_2.html>, etc.) and an "all articles" page for
both articles and blog posts.

=item 6. B<Template Toolkit processing> - Runs C<ttree> (via
L<Template::App::ttree>) on the C<tmp/> directory to produce final HTML
output.

=item 7. B<Sitemap generation> - Crawls the generated HTML files and writes
C<sitemap.xml> with priorities, change frequencies, and last-modified dates
derived from git history.

=item 8. B<Search engine> (release builds only) - Generates a WebAssembly
search index using C<tinysearch> from the rendered HTML content.

=back

When the C<file> attribute is set, only that single file is rebuilt. This
is useful during development for rapid iteration but does not update RSS
feeds, pagination, or the sitemap.

=head1 ATTRIBUTES

=head2 release

    my $site = Ovid::Site->new( release => 1 );

Boolean, defaults to false. When true, the build includes search engine
index generation via C<tinysearch>. This is intended for production release
builds only.

=head2 file

    my $site = Ovid::Site->new( file => 'root/blog/my-post.tt' );

Optional. When set, C<build()> only rebuilds this single file rather than
running the full pipeline. The value should be a path to a Template Toolkit
source file under C<root/>.

=head1 METHODS

=head2 build

    $site->build;

Executes the site build pipeline. If C<file> is set, performs a single-file
rebuild. Otherwise, runs the full build sequence: preprocessing, tag
generation, RSS feeds, pagination, C<ttree> processing, and sitemap
generation (plus search engine indexing if C<release> is true).

=cut
