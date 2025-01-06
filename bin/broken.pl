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

# Configuration
my $base_url  = Mojo::URL->new('http://127.0.0.1:7007');
my @scan_dirs = qw(. articles blog static);

# /Users/ovid/perl5/perlbrew/perls/perl-5.40.0/bin/http_this

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
        $path =~ s{^\./}{};  # Remove leading ./ if present
        normalize_path($path) 
    } @actual_files
);
# Find unused files
my $unused_files = $actual_file_set - $referenced_files;

# Print results
print "\nUnused files:\n";
print "-------------\n";
for my $file ( sort $unused_files->members ) {
	next if $file =~ /wasm/; # search engine
    next if $file =~ /^root\//;
    print "$file\n";
}

print "\nBroken local links:\n";
print "------------------\n";
for my $link ( sort $broken_links->members ) {
    my $path = url_to_path($link);
    print "$path\n" if $path;
}
