#!/usr/bin/env perl

use Test::Most;
use Path::Tiny;
use IPC::Run3;

# bin/rebuild reserves exit 1 for "tests failed". A build that dies must
# exit 255, but a bare die exits with $! when it is set: the missing
# ~/.ttreerc check leaves $! as ENOENT, which used to make bin/rebuild exit 2.
# An empty HOME triggers that die before the build touches anything.
my $home = Path::Tiny->tempdir;
local $ENV{HOME} = "$home";

run3 [ $^X, 'bin/rebuild', '--notest' ], \undef, \my $out, \my $err;
is $? >> 8, 255, 'bin/rebuild exits 255 when the build dies';
like $err, qr/\.ttreerc file found/, '... and reports why';

done_testing;
