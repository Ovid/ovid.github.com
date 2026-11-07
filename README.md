# NAME

My Personal Web site

# DESCRIPTION

A simple Web site written using Template Toolkit's ttree utility, with
Skeleton for the CSS. No user serviceable parts inside.

# USAGE

Run this from the current directory to install necessary modules:

    cpanm --installdeps . --with-configure --with-develop --with-all-features

You may need to install
[App-cpanminus](https://metacpan.org/pod/App::cpanminus) for the `cpanm`
command.

Use the `bin/article` program to start writing an article:

    perl bin/article --type article "Name of Article"

Pass `--type blog` instead for a blog post, and `--open` to launch the
new article in the live editor.

After writing the article, run `bin/rebuild` from this directory to rebuild
the html docs. Add `--release` to also regenerate the WebAssembly search
engine (needs `tinysearch` and `wasm-pack` installed via `cargo`).

Note: If you need a table of contents for a TT doc, include the string `{{TOC}}`
on a blank line by itself. We try to build the table of contents automatically
from the "H" tags in the HTML (`<h1>`, `<h2>`, up to `<h6>`).

For local testing, run the development server from the root directory:

    perl bin/review

It serves the generated site at <http://127.0.0.1:7007/> and injects an
Edit button (✏️ in the upper-left of every page) that launches the live
editor on the source `.tt` file for the page you are viewing. See
`perldoc bin/review` for details.

# Article Metadata

At the top of any new article or blog entry, you'll often see a preamble like
this:

    [%
        title            = 'Life on Venus?';
        type             = 'blog';
        slug             = 'life-on-venus';
        include_comments = 1;
        syntax_highlight = 1;
        date             = '2020-09-15';
        facebook         = 'venus.jpg';
        facebook_alt     = 'The planet Venus';
        USE Ovid;
    %]

`title` is the title of the entry. It will be used in the `<title>` tag
and also as the title displayed on the page.

`type` should be one of `blog` or `article`.

`slug` is the slug used to build the URL.

If set to a true value, `include_comments` will enable Disqus comments for
the page.

If `syntax_highlight` is true, you can wrap your code and have it syntax
highlighted:

    [% WRAPPER include/code.tt language='perl' -%]
    use strict;
    use warnings;
    use Test::More;

    use Catalyst::Test 'Client';

    ok( request('/some_path')->is_success, 'Request should succeed' );
    done_testing();
    [% END %]

`date` will be displayed on the web page.

If present, `facebook` will create an OpenGraph image used by Facebook and
other social media sites as a teaser image for the article. `facebook_alt`
sets the alt text for that image.

# Live Editor

You can edit articles and blog posts using the live editor. This provides a side-by-side preview of your content as you type.

    perl bin/launch path/to/article.tt

## Options

- `--port=N`: Bind the server to a specific port (default: 3000).

## Image Uploads

The editor includes an "Upload Image" feature in the header. You can upload PNG, GIF, or JPG images. They will be:
1. Resized to fit within the configured maximum size (default 300KB).
2. Saved to `root/static/images/`.
3. Inserted into your document at the cursor position using the standard image include snippet.

# CONFIGURATION

This is in my `~/.ttreerc` file (though the `src` and `dst` are now overridden
by the `bin/rebuild` script):

    verbose 
    recurse

    src  = ~/path/to/this/directory/root
    dest = ~/path/to/this/directory

    ignore = \b(CVS|RCS|sw[po])\b
    ignore = ^#

    suffix tt=html

You will also want to edit the following files:

    root/include/header.tt
    root/include/footer.tt

The header has Google tracking code and various bits about the author. The
footer has the author's Disqus code. If you'd like comments on your site and
wish to use Disqus, see [the Disqus website](https://disqus.com/) for more
information.

# STOCK PHOTOS

Many photos are from the free stock photo sites
[Unsplash](https://unsplash.com/) or [Pexels](https://www.pexels.com/).

# LICENSE

Copyright 2018-2026, Curtis "Ovid" Poe. Released under [The MIT
License](https://opensource.org/licenses/MIT).
