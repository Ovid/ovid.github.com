#!/usr/bin/env perl

# Every build wipes and refills the shared tmp/ directory. Two overlapping
# builds (say, bin/rebuild and a live-editor preview) delete each other's
# files mid-build, so build() takes an exclusive lock first.

use Test::Most;
use lib 'lib';
use Less::Boilerplate;
use Capture::Tiny qw(capture_stderr);
use Fcntl         qw(:flock);
use POSIX         qw(WNOHANG);
use Ovid::Site;

my $lockfile = Ovid::Site::BUILD_LOCK;

sub lock_is_free () {
    open my $fh, '>>', $lockfile or die "Cannot open $lockfile: $!";
    return flock $fh, LOCK_EX | LOCK_NB;    # released when $fh goes out of scope
}

subtest 'build() holds the lock while it runs' => sub {
    ok lock_is_free(), 'No build holds the lock beforehand';

    my $held;
    {
        no warnings 'redefine';
        local *Ovid::Site::_build_single_file = sub ($) { $held = !lock_is_free() };
        Ovid::Site->new( file => 'root/whatever.tt' )->build;
    }
    ok $held,          'The lock is held during the build';
    ok lock_is_free(), '... and released afterwards';
};

subtest 'A second build waits for the first' => sub {
    my $lock = Ovid::Site::_lock_build();

    my $pid = fork // die "Cannot fork: $!";
    if ( !$pid ) {

        # The child inherits the parent's handle, which shares its lock; keep
        # it and the parent's release never frees the lock. Never hang the
        # suite if locking breaks.
        undef $lock;
        alarm 10;
        my $stderr = capture_stderr { Ovid::Site::_lock_build() };
        exit( $stderr =~ /Waiting for another build/ ? 0 : 1 );
    }

    sleep 1;    # let the child reach the lock and block on it
    ok waitpid( $pid, WNOHANG ) == 0, 'The second build blocks while the first holds the lock';
    undef $lock;
    waitpid $pid, 0;
    is $? >> 8, 0, '... says it is waiting, then proceeds once the lock is released';
};

subtest 'A build that must not wait fails fast' => sub {
    my $lock = Ovid::Site::_lock_build();
    my $ran;
    {
        no warnings 'redefine';
        local *Ovid::Site::_build_single_file = sub ($) { $ran = 1 };
        local $SIG{ALRM} = sub { die "build() waited for the lock\n" };
        alarm 5;
        my $stderr = capture_stderr {
            throws_ok { Ovid::Site->new( file => 'root/whatever.tt', wait_for_lock => 0 )->build }
            qr/Another build is running/,
              'build() dies at once while another build holds the lock';
        };
        alarm 0;
        unlike $stderr, qr/Waiting/, '... without waiting';
    }
    ok !$ran, '... and builds nothing';
};

done_testing;
