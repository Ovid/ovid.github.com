#!/usr/bin/env perl

use Test::Most;
use Less::Boilerplate;
use lib 'lib';
use Text::Markdown::Blog;

sub is_html : prototype($$$);

my $blog = Text::Markdown::Blog->new;
subtest 'basic' => sub {
    my $html = $blog->blogdown(<<~'END');
    This is my _text_.
    
        Indented.
    
    More text.
    END
    my $expected = <<~'END';
    <p>This is my <em>text</em>.</p>
    
    <pre><code>Indented.
    </code></pre>
    
    <p>More text.</p>
    END
    is_html $html, $expected, 'Basic Markdown parsing should succeed';

    $html = $blog->blogdown(<<~'END');
    This is [link one](/to/some/path).

    This is [link two](http://www.example.com/to/some/path).
    END
    explain $html;

    $expected = <<~'END';
    <p>This is <a href="/to/some/path">link one</a>.</p>

    <p>This is <a href="http://www.example.com/to/some/path" target="_blank">link two</a> <span class="fa fa-external-link fa_custom"></span>.</p>
    END
    is_html $html, $expected, 'URLs with domains should open a new tab';
};

done_testing;

sub is_html ( $have, $want, $message ) {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my @have = map { rtrim($_) } split /\n/ => trim($have);
    my @want = map { rtrim($_) } split /\n/ => trim($want);
    eq_or_diff \@have, \@want, $message;
}

sub trim ($text) {
    $text =~ s/^\s+|\s+$//gr;
}

sub rtrim ($text) {
    $text =~ s/\s+$//r;
}
