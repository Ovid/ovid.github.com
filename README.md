# NAME

My Personal Web site

# DESCRIPTION

A simple Web site written using Template Toolkit's ttree utility, with
Skeleton for the CSS.

# USAGE

Run this from the current directory to install necessary modules:

    cpanm --installdeps . --with-configure --with-develop --with-all-features

You may need to install
[App-cpanminus](https://metacpan.org/pod/App::cpanminus) for the `cpanm`
command.

Use the `bin/article` program to start writing an article:

    perl bin/article Name of Article

After writing the article, run `bin/rebuild` from this directory to rebuild
the html docs.

Note: If you need a table of contents for a TT doc, include the string `TOC`
on a blank line by itself. We try to build the TOC automatically from the "H"
tags in the HTML (`<h1>`, `<h2>`, up to `<h6>`).

You may find installing
[App::HTTPThis](https://metacpan.org/pod/App::HTTPThis) to be useful for local
testing. After installation, simply run this from the root directory:

    $ http_this
    Exporting '.', available at:
       http://127.0.0.1:7007/

You can then navigate to `http://127.0.0.1:7007/` in your browser to see the
results. See `perldoc http_this` for more details.

# CONFIGURATION

This is in my `~/.ttreerc` file:

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

Copyright 2018-2019, Curtis "Ovid" Poe. Released under [The MIT
License](http://opensource.org/licenses/MIT).
