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

subtest 'dirty-tree gate rejects unless --force' => sub {
    my $tmproot = Path::Tiny->tempdir;
    $tmproot->child('root')->mkpath;
    $tmproot->child('lib')->mkpath;
    $tmproot->child('bin')->mkpath;
    $tmproot->child('bin/rebuild')->spew('# stub');
    $tmproot->child('root/test.tt')->spew('initial content');

    chdir $tmproot;
    system( 'git', 'init', '-q' );
    system( 'git', 'config', 'user.email', 't@t' );
    system( 'git', 'config', 'user.name',  't' );
    system( 'git', 'add', '-A' );
    system( 'git', 'commit', '-q', '-m', 'init' );

    $tmproot->child('root/test.tt')->spew('dirty content');

    my ( $out, $err ) = run_in( $tmproot, '--dry-run' );
    ok $err, 'aborts when root/ has uncommitted changes';
    like "$err$out", qr/uncommitted|dirty|--force/i,
        'error message references --force escape hatch';

    ( $out, $err ) = run_in( $tmproot, '--dry-run', '--force' );
    ok !$err, '--force bypasses dirty-tree gate';

    chdir $cwd;
};

done_testing;
