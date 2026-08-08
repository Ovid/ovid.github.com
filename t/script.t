#!/usr/bin/env perl

use Test::Most;
use lib 'lib';
use Less::Script;
use File::Temp qw(tempfile tempdir);
use IPC::Run   qw(run timeout);

# Test splat function (write file)
subtest 'splat writes contents to file' => sub {
    my $dir     = tempdir( CLEANUP => 1 );
    my $file    = "$dir/test.txt";
    my $content = "Hello, World!\nThis is a test.";

    splat( $file, $content );

    ok -e $file, 'File should exist after splat';
    my $read_content = slurp($file);
    is $read_content, $content, 'Content should match what was written';
};

# Test slurp function (already tested in other files, but explicit here)
subtest 'slurp reads file contents' => sub {
    my $dir     = tempdir( CLEANUP => 1 );
    my $file    = "$dir/test.txt";
    my $content = "Test content\nwith multiple lines\n";

    splat( $file, $content );
    my $read = slurp($file);

    is $read, $content, 'slurp should read exact file contents';
};

# Test make_slug (already tested but ensure full coverage)
subtest 'make_slug creates URI-friendly slugs' => sub {
    is make_slug('Hello World'),            'hello-world',           'Basic slug with spaces';
    is make_slug('Test-With_Underscores'),  'test-with-underscores', 'Handles dashes and underscores';
    is make_slug('  Multiple   Spaces  '),  'multiple-spaces',       'Handles multiple spaces';
    is make_slug('CamelCase'),              'camelcase',             'Converts to lowercase';
    is make_slug('Spëcîål Çhårß'),          'special-charss',        'Handles unicode/accents (unidecode)';
    is make_slug('Remove!@#$%Special&*()'), 'removespecial',         'Removes special characters';
};

# Test article_type success (already tested in t/slugs.t)
subtest 'article_type returns valid article type' => sub {
    my $type = article_type('blog');
    is ref($type),    'HASH', 'Should return a hashref';
    is $type->{type}, 'blog', 'Should have correct type';
    ok $type->{name},      'Should have a name';
    ok $type->{directory}, 'Should have a directory';
};

# Test article_type error condition (uncovered branch at line 43)
subtest 'article_type croaks on invalid type' => sub {
    throws_ok { article_type('nonexistent_type_xyz123') }
    qr/Could not fetch article_type information/,
      'Should croak when article type does not exist';
};

# Test dbh function (already tested in other files)
subtest 'prompt reads a line of input' => sub {

    # Run in a subprocess: Term::ReadLine reads a real filehandle, not a mock.
    my $ask = sub ($input) {
        my $code = 'print "[", prompt("Question:"), "]"';

        # timeout so a prompt that waits on input fails the suite instead of
        # blocking it forever
        run [ $^X, '-Ilib', '-MLess::Script', '-e', $code ], \$input, \my $out, \my $err,
          timeout(30);
        return $out;
    };

    like $ask->("blog\n"), qr/\[blog\]/, 'returns the line entered, chomped';
    like $ask->("\n"),     qr/\[\]/,     'returns empty string for an empty line';
    like $ask->(''),       qr/\[\]/,     'returns empty string at EOF';
};

subtest 'prompt does not read the terminal when stdin is a pipe' => sub {

    # The suite runs from a shell, so a controlling terminal exists even though
    # each test's stdin is a pipe. Term::ReadLine::Gnu reads /dev/tty directly
    # in that situation: it ignored the piped answer and sat waiting for the
    # developer to type one. `script` gives the child a controlling terminal
    # while its stdin stays a pipe, which is the only way to reproduce it.
    plan skip_all => 'needs BSD script(1) to allocate a controlling terminal'
      unless $^O eq 'darwin' && -x '/usr/bin/script';

    my $child = "$^X -Ilib -MLess::Script -e 'print q([), prompt(q(Question:)), q(])'";
    run [ '/usr/bin/script', '-q', '/dev/null', 'bash', '-c', "echo blog | $child" ],
      \undef, \my $out, \my $err, timeout(30);

    like $out, qr/\[blog\]/,
      'reads the piped answer instead of waiting on the terminal';
};

# Test dbh function (already tested in other files)
subtest 'dbh returns database handle' => sub {
    my $handle = dbh();
    ok $handle, 'Should return a database handle';
    isa_ok $handle, 'DBI::db', 'Should be a DBI database handle';

    # Call it again to test the state variable path
    my $handle2 = dbh();
    is $handle2, $handle, 'Should return the same cached handle';
};

done_testing;
