#!/usr/bin/env perl

use Test::Most;
use lib 'lib';

# Test class that consumes the Debug role
{
    package Test::Package::WithDebug;
    use v5.40;
    use Moose;
    with qw(Ovid::Template::Role::Debug);
}

# Test class that consumes both Debug and File roles
{
    package Test::Package::WithDebugAndFile;
    use v5.40;
    use Moose;
    with qw(
      Ovid::Template::Role::Debug
      Ovid::Template::Role::File
    );
}

subtest 'debug attribute' => sub {
    my $obj = Test::Package::WithDebug->new;
    
    is $obj->debug, 0, 'debug should default to false';
    ok $obj->can('debug'), 'debug attribute should be accessible';
    
    # Test setting debug to true
    $obj->debug(1);
    is $obj->debug, 1, 'debug should be settable to true';
    
    # Test setting debug to false
    $obj->debug(0);
    is $obj->debug, 0, 'debug should be settable to false';
};

subtest '_debug method without File role' => sub {
    my $obj = Test::Package::WithDebug->new;
    
    # Test with debug disabled
    my $stderr = '';
    {
        local *STDERR;
        open STDERR, '>', \$stderr or die "Cannot open STDERR: $!";
        $obj->_debug('Test message 1');
        close STDERR;
    }
    is $stderr, '', '_debug should not print when debug is false';
    
    # Test with debug enabled
    $obj->debug(1);
    $stderr = '';
    {
        local *STDERR;
        open STDERR, '>', \$stderr or die "Cannot open STDERR: $!";
        $obj->_debug('Test message 2');
        close STDERR;
    }
    is $stderr, "Test message 2\n", 
       '_debug should print message to STDERR when debug is true';
    
    # Test with multiple messages
    $stderr = '';
    {
        local *STDERR;
        open STDERR, '>', \$stderr or die "Cannot open STDERR: $!";
        $obj->_debug('First message');
        $obj->_debug('Second message');
        close STDERR;
    }
    is $stderr, "First message\nSecond message\n",
       '_debug should print multiple messages correctly';
};

subtest '_debug method with File role (filename only)' => sub {
    my $obj = Test::Package::WithDebugAndFile->new(
        filename => 'test_file.txt',
    );
    
    $obj->debug(1);
    
    my $stderr = '';
    {
        local *STDERR;
        open STDERR, '>', \$stderr or die "Cannot open STDERR: $!";
        $obj->_debug('File message');
        close STDERR;
    }
    is $stderr, "test_file.txt: File message\n",
       '_debug should include filename when File role is present';
};

subtest '_debug method with File role (filename and line number)' => sub {
    my $obj = Test::Package::WithDebugAndFile->new(
        filename => 'test_file.txt',
    );
    
    # Manually set line_number (simulating a file being read)
    $obj->_set_line_number(42);
    $obj->debug(1);
    
    my $stderr = '';
    {
        local *STDERR;
        open STDERR, '>', \$stderr or die "Cannot open STDERR: $!";
        $obj->_debug('Line message');
        close STDERR;
    }
    is $stderr, "test_file.txt/42: Line message\n",
       '_debug should include filename and line number when both are available';
};

subtest 'edge cases and error conditions' => sub {
    my $obj = Test::Package::WithDebug->new(debug => 1);
    
    # Test with empty message
    my $stderr = '';
    {
        local *STDERR;
        open STDERR, '>', \$stderr or die "Cannot open STDERR: $!";
        $obj->_debug('');
        close STDERR;
    }
    is $stderr, "\n", '_debug should handle empty messages';
    
    # Test with special characters
    $stderr = '';
    {
        local *STDERR;
        open STDERR, '>', \$stderr or die "Cannot open STDERR: $!";
        $obj->_debug('Message with \n newline \t tab');
        close STDERR;
    }
    like $stderr, qr/Message with/, 
         '_debug should handle special characters';
    
    # Test with unicode
    $stderr = '';
    {
        local *STDERR;
        open STDERR, '>', \$stderr or die "Cannot open STDERR: $!";
        $obj->_debug('Unicode: é à ñ 中文');
        close STDERR;
    }
    like $stderr, qr/Unicode/, '_debug should handle unicode characters';
};

subtest 'debug in constructor' => sub {
    my $obj = Test::Package::WithDebug->new(debug => 1);
    is $obj->debug, 1, 'debug can be set via constructor';
    
    my $stderr = '';
    {
        local *STDERR;
        open STDERR, '>', \$stderr or die "Cannot open STDERR: $!";
        $obj->_debug('Constructor test');
        close STDERR;
    }
    is $stderr, "Constructor test\n",
       'debug set in constructor should work immediately';
};

subtest 'conditional logic paths' => sub {
    # Test all code paths in _debug method
    
    # Path 1: debug is false, File role not present
    my $obj1 = Test::Package::WithDebug->new(debug => 0);
    my $stderr = '';
    {
        local *STDERR;
        open STDERR, '>', \$stderr or die "Cannot open STDERR: $!";
        $obj1->_debug('Should not print');
        close STDERR;
    }
    is $stderr, '', 'Path 1: debug=false, no File role';
    
    # Path 2: debug is true, File role not present
    my $obj2 = Test::Package::WithDebug->new(debug => 1);
    $stderr = '';
    {
        local *STDERR;
        open STDERR, '>', \$stderr or die "Cannot open STDERR: $!";
        $obj2->_debug('Simple message');
        close STDERR;
    }
    is $stderr, "Simple message\n", 'Path 2: debug=true, no File role';
    
    # Path 3: debug is true, File role present, no line number
    my $obj3 = Test::Package::WithDebugAndFile->new(
        debug => 1,
        filename => 'file.txt',
    );
    $stderr = '';
    {
        local *STDERR;
        open STDERR, '>', \$stderr or die "Cannot open STDERR: $!";
        $obj3->_debug('File without line');
        close STDERR;
    }
    is $stderr, "file.txt: File without line\n",
       'Path 3: debug=true, File role, no line number';
    
    # Path 4: debug is true, File role present, with line number
    my $obj4 = Test::Package::WithDebugAndFile->new(
        debug => 1,
        filename => 'file.txt',
    );
    $obj4->_set_line_number(100);
    $stderr = '';
    {
        local *STDERR;
        open STDERR, '>', \$stderr or die "Cannot open STDERR: $!";
        $obj4->_debug('File with line');
        close STDERR;
    }
    is $stderr, "file.txt/100: File with line\n",
       'Path 4: debug=true, File role, with line number';
};

done_testing;
