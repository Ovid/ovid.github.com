#!/usr/bin/perl

use strict;
use warnings;
use Mojo::UserAgent;
use Mojo::URL;
use Path::Tiny;
use File::Find::Rule;
use URI;
use Set::Object;
use Scalar::Util 'blessed';
use File::Spec;

# Configuration
my $base_url = Mojo::URL->new('http://127.0.0.1:7007');

# Check if server is running
{
    my $ua = Mojo::UserAgent->new;
    my $tx = $ua->get($base_url);
    if ( $tx->error ) {
        die "Error: No server running at $base_url. Please run `http_this` in the root directory.\n";
    }
}
my @scan_dirs = qw(. articles blog static);

# Read .gitignore patterns
my @gitignore_patterns;
if ( open my $fh, '<', '.gitignore' ) {
    while ( my $line = <$fh> ) {
        chomp $line;

        # Skip comments and empty lines
        next if $line =~ /^\s*#/ || $line =~ /^\s*$/;

        # Convert .gitignore glob patterns to regex
        $line =~ s/\./\\./g;    # Escape dots
        $line =~ s/\*/.*/g;     # Convert * to .*
        $line =~ s/\?/./g;      # Convert ? to .
                                # Handle directory patterns
        if ( $line =~ m{/$} ) {    # If pattern ends with /
            $line =~ s{/$}{};                           # Remove trailing slash
            push @gitignore_patterns, qr/^$line.*$/;    # Match anything under this directory
        }
        else {
            push @gitignore_patterns, qr/^$line$/;
        }
    }
    close $fh;
}

# Initialize crawl state
my $ua               = Mojo::UserAgent->new;
my $seen_urls        = Set::Object->new;
my $referenced_files = Set::Object->new;
my $broken_links     = Set::Object->new;

# Helper to convert URL to local path
sub url_to_path {
    my $url = shift;
    return unless $url;
    my $uri = URI->new($url);
    return $uri->path;
}

# Helper to normalize paths
sub normalize_path {
    my $path = shift;
    $path =~ s{^/}{};    # Remove leading slash
    return $path;
}

# Helper to check if a file matches gitignore patterns
sub is_ignored {
    my $file = shift;
    for my $pattern (@gitignore_patterns) {

        # For directory patterns, check if the file starts with the directory path
        return 1 if $file =~ $pattern;
    }
    return 0;
}

# Crawler function
sub crawl_page {
    my $url = shift;
    $url = $url->fragment(undef);    # Remove fragment

    # Stringify URL to avoid object comparison
    return if $seen_urls->contains("$url");
    $seen_urls->insert("$url");

    print "Crawling: $url\n";
    my $tx = $ua->get($url);
    if ( $tx->error ) {
        $broken_links->insert($url);
        return;
    }

    my $dom = $tx->result->dom;

    # Collect all relevant local links
    my @links = (

        # HTML links
        $dom->find('a[href]')->map( attr => 'href' )->each,

        # CSS links
        $dom->find('link[rel="stylesheet"]')->map( attr => 'href' )->each,

        # JavaScript links
        $dom->find('script[src]')->map( attr => 'src' )->each
    );

    for my $link (@links) {
        my $full_url = Mojo::URL->new($link)->to_abs( Mojo::URL->new($url) );

        # Skip if not from our domain
        next if $full_url->scheme ne 'http';
        next unless $full_url->host eq '127.0.0.1';

        my $path = normalize_path( url_to_path($full_url) );

        # Skip if not html/css/js
        next unless $path =~ /\.(html|css|js)$/;

        # Add to referenced files
        $referenced_files->insert($path);

        # Crawl HTML files we haven't seen
        if ( $path =~ /\.html$/ ) {
            no warnings 'recursion';
            crawl_page($full_url);
        }
    }
}

# Start crawling from homepage
crawl_page($base_url);

# Find all actual files
my @actual_files = File::Find::Rule->file()->name( '*.html', '*.css', '*.js' )->in(@scan_dirs);

# Convert to Set for comparison
my $actual_file_set = Set::Object->new(
    map {
        my $path = $_;
        $path =~ s{^\./}{};    # Remove leading ./ if present
        normalize_path($path)
    } @actual_files
);

# Find unused files
my $unused_files = $actual_file_set - $referenced_files;

# Get filtered list of unused files
my @unused_files = grep {
    my $file = $_;
    !(  $file =~ /wasm/                 ||                     # search engine
        $file =~ /tinysearch_engine.js/ ||                     # search engine
        $file =~ /^root\//              || is_ignored($file)
    )                                                          # Skip files that match .gitignore patterns
} sort $unused_files->members;

# Print results
if (@unused_files) {
    print "\nUnused files:\n";
    print "-------------\n";
    print "$_\n" for @unused_files;
}
else {
    print "\nNo unused files found.\n";
}

if ( my @broken_links = $broken_links->members ) {
    print "\nBroken local links:\n";
    print "------------------\n";
    for my $link ( sort @broken_links ) {
        my $path = url_to_path($link);
        print "$path\n" if $path;
    }
}
else {
    print "\nNo broken links found.\n";
}

__END__

=head1 NAME

broken.pl - Identify unused files and broken links in a web project by crawling links

=head1 SYNOPSIS

    ./find_unused_files.pl

=head1 DESCRIPTION

This script crawls a local web server to identify HTML, CSS, and JavaScript
files that exist in the project but are not referenced by any links. It helps
identify orphaned files that might be candidates for cleanup.

The script respects C<.gitignore> patterns and will exclude any matching files
from the "unused files" report.

=head2 How it Works

=over 4

=item 1. Crawls the website starting from http://127.0.0.1:7007

=item 2. Collects all links to HTML, CSS, and JavaScript files

=item 3. Scans local directories for actual files

=item 4. Compares referenced files against actual files

=item 5. Reports files that exist but are not referenced

=back

=head1 CONFIGURATION

The script has several configurable variables at the top:

    $base_url  = 'http://127.0.0.1:7007'    # Starting URL for crawl
    @scan_dirs = qw(. articles blog static)  # Directories to scan

=head1 OUTPUT

The script produces two reports:

=head2 Unused Files

Lists files that exist in the scanned directories but are not referenced by any
links in the crawled pages. Files matching patterns in C<.gitignore> are
excluded.

=head2 Broken Links

Lists any links encountered during crawling that returned errors.

=head1 LIMITATIONS

=over 4

=item * Only checks static links in HTML attributes (href, src)

=item * Does not evaluate JavaScript-generated links

=item * Assumes the web server is running on http://127.0.0.1:7007

=item * Only processes .html, .css, and .js files

=back

=head1 EXAMPLE OUTPUT

    Crawling: http://127.0.0.1:7007
    Crawling: http://127.0.0.1:7007/about.html
    
    Unused files:
    -------------
    old_about.html
    unused.css
    
    Broken local links:
    ------------------
    /missing.html

=head1 SEE ALSO

=over 4

=item * Git documentation on .gitignore patterns: https://git-scm.com/docs/gitignore

=item * Mojolicious documentation for web crawling: https://docs.mojolicious.org/

=back
