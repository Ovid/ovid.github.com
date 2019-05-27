#!/usr/bin/env perl

use Test::Most;
use HTML::TokeParser::Simple;
use File::Find::Rule;
use Less::Boilerplate;

my @files = File::Find::Rule->file->name('*.html')->in('.');

foreach my $file (@files) {
    next if $file =~ /^include/;    # XXX bug
    try {
        my @errors = html_is_bad($file);
        ok !@errors, "$file should have no linting errors" or explain \@errors;
    }
    catch {
        fail "Parting $file failed: $_";
    };
}

done_testing;

sub html_is_bad ( $file ) {

    # HTML::Lint doesn't like HTML5 and HTML::Tidy5 doesn't build.
    my $parser = HTML::TokeParser::Simple->new( file => $file );

    state $no_end_tag =
      { map { ( $_ => 1, "$_/" => 1 ) } qw/link meta br input img hr/ };

    my ( @errors, @stack, $unbalanced, %id_seen );

  TOKEN: while ( my $token = $parser->get_tag ) {
        if ( $token->is_start_tag ) {
            if ( my $id = $token->get_attr('id') ) {
                if ( $id_seen{$id}++ ) {
                    push @errors => "ID '$id' was already seen on this page";
                }
            }
        }

        unless ($unbalanced)
        {    # if we've found one, don't waste time searching for more
            my $previous     = $stack[-1];
            my $this_tag     = $token->as_is;
            my $previous_tag = $previous ? $previous->as_is : '';
            if ( $token->is_end_tag ) {
                if ( $no_end_tag->{ $token->get_tag } ) {
                    return "Bad end tag found for '$this_tag'";
                }
                if ( $previous->is_start_tag ) {
                    if ( $token->get_tag eq $previous->get_tag ) {
                        pop @stack;    # good state
                        next TOKEN;
                    }
                    else {
                        push @errors =>
"'$this_tag' end tag does not match previous start tag: $previous_tag";
                        $unbalanced = 1;
                    }
                }
                if ( !$previous ) {
                    push @errors => "End tag found but empty stack: $this_tag";
                    $unbalanced = 1;
                }
            }
            if ( $token->is_start_tag ) {
                if ( $no_end_tag->{ $token->get_tag } ) {
                    next TOKEN;    # ignore it
                }
                push @stack => $token;
            }
        }
    }
    return @errors;
}
