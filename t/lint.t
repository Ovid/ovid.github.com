#!/usr/bin/env perl

use Test::Most;
use HTML::TokeParser::Simple;
use File::Find::Rule;
use Less::Boilerplate;
use Less::Config qw(config);

my $MAX_IMAGE_SIZE = config()->{max_image_size_bytes};
die "max_image_size_bytes not found in config" unless defined $MAX_IMAGE_SIZE;

my @files = @ARGV ? @ARGV : File::Find::Rule->file->name('*.html')->in('.');

foreach my $file (@files) {
    next if $file =~ /^(?:include|cover|nytprof|editor|\.worktrees|t\/fixtures|scratch)/;
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
    try {
        my @ext_errors = extensionless_violations($file);
        ok !@ext_errors, "$file should have no extensionless-URL violations"
          or diag join "\n" => @ext_errors;
    }
    catch {
        fail "Extensionless lint of $file failed: $_";
    };
}

subtest 'extensionless URL check flags root-relative + curtispoe.org absolute .html' => sub {
    my $fixture = 't/fixtures/lint/extensionless_violations.html';
    my @errors  = extensionless_violations($fixture);

    is scalar(@errors), 3,
        '3 violations found (1 root-relative <a>, 1 canonical, 1 og:url)';
    ok( ( grep { /\/blog\/y\.html/    } @errors ), 'root-relative <a> flagged' );
    ok( ( grep { /canonical.*x\.html/ } @errors ), 'canonical absolute flagged' );
    ok( ( grep { /og:url.*x\.html/    } @errors ), 'og:url absolute flagged' );
    ok( ( !grep { /example\.com/      } @errors ), 'external URL not flagged' );
    ok( ( !grep { /\/blog\/z[^.]/     } @errors ), 'clean extensionless link not flagged' );
};

done_testing;

sub html_is_bad ($file) {

    # HTML::Lint doesn't like HTML5 and HTML::Tidy5 doesn't build. Hence, a
    # custom linter
    my $parser = HTML::TokeParser::Simple->new( file => $file );

    state $no_end_tag = { map { ( $_ => 1, "$_/" => 1 ) } qw/link meta br input img hr/ };

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

        unless ($unbalanced) {    # if we've found one, don't waste time searching for more
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
                        push @errors => "'$this_tag' end tag does not match previous start tag: $previous_tag";
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

sub extensionless_violations ($file) {
    my @errors;
    my $parser = HTML::TokeParser::Simple->new( file => $file );

    my $root_re     = qr{^/[^#?]*\.html(?:[#?].*)?$};
    my $absolute_re = qr{^https?://curtispoe\.org/[^#?]*\.html(?:[#?].*)?$};

    while ( my $token = $parser->get_tag ) {
        next unless $token->is_start_tag;
        my $tag = $token->get_tag;

        if ( $tag eq 'a' || $tag eq 'link' ) {
            my $href = $token->get_attr('href') // next;
            if ( $href =~ $root_re || $href =~ $absolute_re ) {
                my $rel  = $tag eq 'link' ? ( $token->get_attr('rel') // '' ) : '';
                my $kind = $tag eq 'link' && $rel eq 'canonical' ? 'canonical' : $tag;
                push @errors, "$kind href '$href' should be extensionless";
            }
        }
        elsif ( $tag eq 'meta' ) {
            my $prop = $token->get_attr('property') // '';
            next unless $prop eq 'og:url';
            my $content = $token->get_attr('content') // next;
            if ( $content =~ $root_re || $content =~ $absolute_re ) {
                push @errors, "og:url content '$content' should be extensionless";
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
            if (   $size > $MAX_IMAGE_SIZE
                && $src !~ /ukraine-war/    # make an exception because this is important. Later, we can clean this up
              )
            {
                push @errors =>
                  "Image $src does not appear to be optimized. It's $size bytes. We prefer $MAX_IMAGE_SIZE bytes or under.";
            }
        }
    }
    else {
        push @errors => "No src attribute for $tag" unless $image->get_attr('id') eq "overlayImage";
    }
    return @errors;
}
