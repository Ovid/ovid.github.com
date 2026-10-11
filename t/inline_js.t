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

done_testing;
