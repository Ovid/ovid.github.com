#!/usr/bin/env perl

# Source checks for JavaScript embedded in templates. There is no DOM
# available to the test suite, so these pin the specific constructs whose
# absence caused a regression.

use Test::Most;
use Path::Tiny;
use File::Find::Rule;

subtest 'shadow DOM roots style their own visually-hidden text' => sub {

    # Document stylesheets do not cross a shadow boundary, so a shadow root
    # that uses class="visually-hidden" without defining it shows the
    # "hidden" text on screen.
    my @files = File::Find::Rule->file->name( '*.tt', '*.tt2markdown' )->in('root');
    my $checked = 0;
    foreach my $file ( sort @files ) {
        my $code = path($file)->slurp_utf8;
        next unless $code =~ /attachShadow/ && $code =~ /class="visually-hidden"/;
        $checked++;
        like $code, qr#<style>(?:(?!</style>).)*\.visually-hidden\s*\{[^}]*clip#s,
          "$file defines .visually-hidden inside its shadow <style>";
    }
    ok $checked, 'at least one shadow-DOM template was checked';
};

subtest 'search results survive a mouse click in Safari' => sub {

    # Safari does not focus a link on mousedown, so the search input blurs
    # with relatedTarget === null and the focusout handler empties the list
    # before the click lands. Cancelling mousedown on the list keeps focus
    # in the input until the click navigates.
    my $code = path('root/include/search.tt')->slurp_utf8;
    like $code, qr/focusout/, 'search panel closes when focus leaves it';
    like $code,
      qr/getElementById\("results"\)\s*\.addEventListener\(\s*"mousedown",\s*\(?e\)?\s*=>\s*e\.preventDefault\(\)/,
      '... and the results list cancels mousedown so clicks still navigate';
};

done_testing;
