#!/usr/bin/env perl

use Test::Most;
use Mojo::Dom;
use HTML::SimpleLinkExtor;
use File::Find::Rule;
use Less::Boilerplate;

my @files = @ARGV ? @ARGV : File::Find::Rule->file->name('*.html')->in('.');

foreach my $file (@files) {
    next if $file =~ /^include/;    # XXX bug
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

sub links_are_good ( $file ) {
    my $extor = HTML::SimpleLinkExtor->new();
    $extor->parse_file($file);

    my @links = grep {
        !/#/                                    # skip in-page anchors
          && !/^mailto:/                        # and mail links
          && !m{https?://(?!ovid.github.io)}    # and external links
    } $extor->links;
    my @errors;
  LINK: foreach my $link (@links) {
        if ( !$link =~ /^\// ) {
            diag "Relative link ($link) found in $file";
            next LINK;
        }
        else {
            my $possible_file = $link;
            $possible_file =~ s/^\///;
            unless ( -e $possible_file ) {
                push @errors => "Bad link ($link) in $file";
            }
        }
    }
    return @errors;
}
