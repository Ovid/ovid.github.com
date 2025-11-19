#!/usr/bin/env perl

use Test::Most;
use Mojo::DOM;
use HTML::SimpleLinkExtor;
use File::Find::Rule;
use Less::Script;
use Less::Config 'config';
use IPC::Run qw(run);

my $domain = config()->{domain};

my @files = @ARGV ? @ARGV : File::Find::Rule->file->name('*.html')->in('.');
@files = filter_ignored_files(@files);

foreach my $file (@files) {
    try {
        my @errors = links_are_good($file);

        # diag() instead of explain() to ensure these errors show up when I
        # run bin/rebuild
        ok !@errors, "$file should have no bad links"
          or diag join "\n" => @errors;
    }
    catch {
        fail "Checking $file link failed: $_";
    };
}

done_testing;

sub filter_ignored_files {
    my @files = @_;
    return @files unless @files;

    my $in = join( "\n", @files ) . "\n";
    my $out;
    my $err;

    run [ 'git', 'check-ignore', '--stdin' ], \$in, \$out, \$err;

    my %ignored = map { $_ => 1 } split( /\n/, $out );
    return grep { !$ignored{$_} } @files;
}

sub links_are_good ($file) {
    return if $file =~ /\bdemo.html$/;
    my @errors;
    my $extor = HTML::SimpleLinkExtor->new();
    $extor->parse_file($file);

    my @links = grep {
        !/#/                             # skip in-page anchors
          && !/^mailto:/                 # and mail links
          && !m{https?://(?!$domain)}    # and external links
          && $_ ne ""                    # some are deliberately empty
    } $extor->links;
    LINK: foreach my $link (@links) {
        if ( !$link =~ /^\// ) {
            diag "Relative link ($link) found in $file";
            next LINK;
        }
        else {
            my $possible_file = $link;
            $possible_file =~ s/^\///;
            if ( '/' ne $link && !-e $possible_file ) {
                push @errors => "Bad link ($link) in $file";
            }
        }
    }

    state $is_wanted = {
        map { $_ => 1 }
          qw/
          og:image
          og:url
          /
    };
    my $dom      = Mojo::DOM->new( slurp($file) );
    my @og_links = map { $_->attr }
      grep { $is_wanted->{ $_->attr->{property} // '' } } $dom->find('meta')->each;
    foreach my $link (@og_links) {
        my $property = $link->{property};
        my $pristine = $link->{content};
        my $url      = $pristine;
        if ( $url =~ s{^https?://$domain/}{} ) {
            unless ( -e $url ) {
                push @errors => "Missing link for $property: $pristine";
            }
        }
        else {
            push @errors => "Bad format for $property: $pristine";
        }
    }

    # Check for canonical URL
    my $canonical = $dom->find('link[rel="canonical"]')->first;
    unless ($canonical) {
        push @errors => "Missing canonical URL in $file";
    }
    else {
        my $href = $canonical->attr('href');
        unless ($href) {
            push @errors => "Canonical link has no href in $file";
        }
        elsif ( $href !~ m{^https?://$domain/} ) {
            push @errors => "Canonical URL wrong format: $href in $file";
        }
        else {
            my $url = $href;
            $url =~ s{^https?://$domain/}{};
            unless ( -e $url ) {
                push @errors => "Missing canonical file: $href in $file";
            }
        }
    }

    return @errors;
}
