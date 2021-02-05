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

    perl bin/article -type=article Name of Article

After writing the article, run `bin/rebuild` from this directory to rebuild
the html docs.

Note: If you need a table of contents for a TT doc, include the string `{{TOC}}`
on a blank line by itself. We try to build the table of contents automatically
from the "H" tags in the HTML (`<h1>`, `<h2>`, up to `<h6>`).

You may find installing
[App::HTTPThis](https://metacpan.org/pod/App::HTTPThis) to be useful for local
testing. After installation, simply run this from the root directory:

    $ http_this
    Exporting '.', available at:
       http://127.0.0.1:7007/

You can then navigate to `http://127.0.0.1:7007/` in your browser to see the
results. See `perldoc http_this` for more details.

# Article Metadata

At the top of any new article or blog entry, you'll often see a premable like
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

      title            = 'Life on Venus?';

The `title` is the title of the entry. It will be used in the `<title>` tag
and also as the title in the page.

      type             = 'blog';

The `type` should be one of `blog` or `article`.

      slug             = 'life-on-venus';

This is the slug that will be used to build the URL.

      include_comments = 1;

If set to a true value, `include_comments` will enable Disqus comments for the
page.

      syntax_highlight = 1;

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

      date             = '2020-09-15';

This date will be displayed on the web page.

      facebook         = 'venus.jpg';

If present, this will create an opengraph image that will be used by Facebook
and other social media sites for displaying as a teaser image for the article.
This must be an image in the `root/static/images/facebook` directory. For the
size, 200 x 200 is the absolute minimum, [Facebook advises using an image
that's at least 600 x 314
pixels](https://developers.facebook.com/docs/sharing/best-practices#images).
For the best display on high-resolution devices, the company suggests choosing
an image that's at least 1200 x 630 pixels.

      facebook_alt     = 'The planet Venus';

This is the alt text that will be provided for the Facebook image.

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
information..

# STOCK PHOTOS

Many photos from are from the free stock photo sites
[Unsplash](https://unsplash.com/) or [Pexels](https://www.pexels.com/).

# LICENSE

Copyright 2018-2020, Curtis "Ovid" Poe. Released under [The MIT
License](http://opensource.org/licenses/MIT).
