#!/usr/bin/env perl

use Test::Most;
use HTML::TokeParser::Simple;
use File::Find::Rule;
use Less::Boilerplate;

my $MAX_IMAGE_SIZE = 300_000;

my @files = @ARGV ? @ARGV : File::Find::Rule->file->name('*.html')->in('.');

foreach my $file (@files) {
    next if $file =~ /^include/;    # XXX bug
    try {
        my @errors = html_is_bad($file);

        # diag() instead of explain() to ensure these errors show up when I
        # run bin/rebuild
        ok !@errors, "$file should have no linting errors"
          or diag join "\n" => @errors;
    }
    catch {
        fail "Parting $file failed: $_";
    };
}

done_testing;

sub html_is_bad ( $file ) {

    # HTML::Lint doesn't like HTML5 and HTML::Tidy5 doesn't build. Hence, a
    # custom linter
    my $parser = HTML::TokeParser::Simple->new( file => $file );

    state $no_end_tag =
      { map { ( $_ => 1, "$_/" => 1 ) } qw/link meta br input img hr/ };

    my ( @errors, @stack, $unbalanced, %id_seen );

    my %linter_for = (
        a   => \&_validate_anchor,
        img => \&_validate_image,
    );
  TOKEN: while ( my $token = $parser->get_tag ) {
        if ( $token->is_start_tag ) {
            if ( $token->as_is =~ / \/ \s* > $/x ) {

                # something like '<br />' (a self-closing tag)
                next TOKEN;
            }
            if ( my $linter = $linter_for{ $token->get_tag } ) {
                push @errors => $linter->($token);
            }

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

sub _validate_anchor ($anchor) {
    if ( my $href = $anchor->get_attr('href') ) {
        return "localhost found in a.href '$href'"
          if $href =~ m{^https?://localhost};
    }
    return;
}

sub _validate_image ($image) {
    my @errors;
    my $tag = $image->as_is;
    if ( !$image->get_attr('alt') ) {
        push @errors => "a11y alert! Missing 'alt' tag in image: $tag";
    }
    if ( my $src = $image->get_attr('src') ) {
        $src =~ s{^/}{};
        if ( !-e $src ) {
            push @errors => "Cannot find image for $tag";
        }
        elsif ( $src !~ /\.gif$/ ) {
            my $size = -s $src;
            if ( $size > $MAX_IMAGE_SIZE ) {
                push @errors =>
"Image $src does not appear to be optimized. It's $size bytes. We prefer $MAX_IMAGE_SIZE bytes or under.";
            }
        }
    }
    else {
        push @errors => "No src attribute for $tag";
    }
    return @errors;
}
