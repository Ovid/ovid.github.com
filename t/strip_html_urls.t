#!/usr/bin/env perl

use Test::Most;
use lib 'lib';
use Less::Boilerplate;
use Path::Tiny qw(path);
use Cwd        qw(getcwd);
use IPC::Run3  qw(run3);

my $cwd    = getcwd();
my $script = path('bin/strip-html-urls')->absolute;

END { chdir $cwd }

# Runs $script from $dir with @args. Returns (combined_output, exit_err).
# combined_output is stdout+stderr merged so error messages are always visible.
# exit_err is non-empty string when process exits non-zero, empty otherwise.
sub run_in ( $dir, @args ) {
    chdir $dir;
    my $combined = '';
    run3( [ $^X, "$script", @args ], \undef, \$combined, \$combined );
    my $exit_err = $? ? sprintf( "exited %d", $? >> 8 ) : '';
    chdir $cwd;
    return ( $combined, $exit_err );
}

subtest 'CWD pre-flight gate rejects non-project directories' => sub {
    my $tmpdir = Path::Tiny->tempdir;
    my ( $out, $err ) = run_in( $tmpdir, '--dry-run' );
    ok $err, 'script aborts with non-zero exit outside a project root';
    like "$err$out", qr/project root|root\/, lib\/, bin\/rebuild/i,
        'error message mentions the missing project markers';
};

done_testing;
