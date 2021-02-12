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

subtest 'tables' => sub {
	# see https://fletcher.github.io/MultiMarkdown-6/syntax/tables.html
    my $html = $blog->blogdown(<<~'END');
    |             |          Grouping           ||
    First Header  | Second Header | Third Header |
     ------------ | :-----------: | -----------: |
    Content       |          *Long Cell*        ||
    Content       |   **Cell**    |         Cell |
    
    New section   |     More      |         Data |
    And more      | With an escaped '\|'         ||
    [Prototype table]
    END
    my $expected = <<~'END';
    <table>
    <caption>Prototype table</caption>
    <col />
    <col align="center" />
    <col align="right" />
    <thead>
    <tr>
    	<th> </th>
    	<th colspan="2">Grouping</th>
    </tr>
    <tr>
    	<th>First Header</th>
    	<th>Second Header</th>
    	<th>Third Header</th>
    </tr>
    </thead>
    <tbody>
    <tr>
    	<td>Content</td>
    	<td colspan="2" align="center"><em>Long Cell</em></td>
    </tr>
    <tr>
    	<td>Content</td>
    	<td align="center"><strong>Cell</strong></td>
    	<td align="right">Cell</td>
    </tr>
    </tbody>
    
    <tbody>
    <tr>
    	<td>New section</td>
    	<td align="center">More</td>
    	<td align="right">Data</td>
    </tr>
    <tr>
    	<td>And more</td>
    	<td align="center">With an escaped '\</td>
    	<td colspan="2" align="right">'</td>
    </tr>
    </tbody>
    </table>
    END
    is_html $html, $expected, 'We should be able to build rich tables';
};

done_testing;

sub is_html ( $have, $want, $message ) {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my @have = map { trim($_) } split /\n/ => trim($have);
    my @want = map { trim($_) } split /\n/ => trim($want);
    eq_or_diff \@have, \@want, $message;
}

sub trim ($text) {
    $text =~ s/^\s+|\s+$//gr;
}
