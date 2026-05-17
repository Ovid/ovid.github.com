#!/usr/bin/env perl

use Test::Most;
use lib 'lib';
use Less::Boilerplate;
use Test2::Plugin::UTF8;
use Path::Tiny qw(path);
use File::Temp qw(tempdir);
use Cwd        qw(getcwd);
use Test::MockModule;
use Ovid::Util::Image;

# Mock config() in the Ovid::Util::Image namespace (that's where the imported
# function lives after "use Less::Config qw(config)").
# Each subtest updates $current_max before calling process().
my $current_max = 300_000;
my $image_mock  = Test::MockModule->new('Ovid::Util::Image');
$image_mock->mock( 'config', sub { return { max_image_size_bytes => $current_max } } );

# Resolve fixture paths to absolutes BEFORE chdir-ing into tempdirs.
my %fixture = (
    under_limit    => path('t/fixtures/images/under_limit.png')->absolute,
    over_limit     => path('t/fixtures/images/over_limit.jpg')->absolute,
    incompressible => path('t/fixtures/images/incompressible.jpg')->absolute,
    corrupt        => path('t/fixtures/images/corrupt.jpg')->absolute,
);

# Minimal stand-in for Dancer2::Core::Request::Upload exposing only the
# tempname() and copy_to() methods that Ovid::Util::Image actually calls.
package TestUpload {
    sub new ( $class, $src_path ) {
        return bless { tempname => "$src_path" }, $class;
    }
    sub tempname ($self) { $self->{tempname} }
    sub copy_to ( $self, $dest ) {
        Path::Tiny::path( $self->{tempname} )->copy($dest);
    }
}

sub _in_tempdir ($code) {
    my $cwd     = getcwd();
    my $tempdir = Path::Tiny->tempdir;
    chdir $tempdir;
    $tempdir->child('root/static/images')->mkpath;
    $tempdir->child('static/images')->mkpath;
    my $result = eval { $code->($tempdir); 1 };
    my $err    = $@;
    chdir $cwd;
    die $err unless $result;
}

subtest 'invalid_filename rejects path-traversal patterns' => sub {
    $current_max = 300_000;
    _in_tempdir sub {
        my $upload = TestUpload->new( $fixture{under_limit} );
        for my $bad ( '..', '.', 'foo/bar.png', 'foo\\bar.png' ) {
            my $result = Ovid::Util::Image->process(
                upload   => $upload,
                filename => $bad,
            );
            ok !$result->{success},                 "$bad rejected";
            is $result->{code}, 'invalid_filename', "$bad returns invalid_filename code";
            like $result->{error}, qr/Invalid filename/, "$bad error message";
        }
    };
};

subtest 'invalid_type rejects unsupported extensions' => sub {
    $current_max = 300_000;
    _in_tempdir sub {
        my $upload = TestUpload->new( $fixture{under_limit} );
        my $result = Ovid::Util::Image->process(
            upload   => $upload,
            filename => 'foo.bmp',
        );
        ok !$result->{success},             'bmp rejected';
        is $result->{code}, 'invalid_type', 'invalid_type code';
        like $result->{error}, qr/Only PNG, JPG, GIF allowed/, 'error mentions allowed types';
    };
};

subtest 'exists returns code when file already present and overwrite is false' => sub {
    $current_max = 300_000;
    _in_tempdir sub {
        my $tempdir = shift;
        $tempdir->child('root/static/images/under_limit.png')->touch;
        my $upload = TestUpload->new( $fixture{under_limit} );
        my $result = Ovid::Util::Image->process(
            upload   => $upload,
            filename => 'under_limit.png',
        );
        ok !$result->{success},      'rejected on collision';
        is $result->{code}, 'exists', 'exists code';
    };
};

subtest 'overwrite=1 permits replacing an existing file' => sub {
    $current_max = 300_000;
    _in_tempdir sub {
        my $tempdir = shift;
        $tempdir->child('root/static/images/under_limit.png')->touch;
        my $upload = TestUpload->new( $fixture{under_limit} );
        my $result = Ovid::Util::Image->process(
            upload    => $upload,
            filename  => 'under_limit.png',
            overwrite => 1,
        );
        ok $result->{success}, 'overwrite allowed';
        is $result->{path}, '/static/images/under_limit.png', 'path returned';
    };
};

subtest 'invalid_image rejects corrupt bytes' => sub {
    $current_max = 300_000;
    _in_tempdir sub {
        my $upload = TestUpload->new( $fixture{corrupt} );
        my $result = Ovid::Util::Image->process(
            upload   => $upload,
            filename => 'corrupt.jpg',
        );
        ok !$result->{success},              'corrupt bytes rejected';
        is $result->{code}, 'invalid_image', 'invalid_image code';
        like $result->{error}, qr/Could not parse image/, 'error mentions parse failure';
    };
};

subtest 'small image copies as-is' => sub {
    $current_max = 300_000;
    _in_tempdir sub {
        my $tempdir = shift;
        my $upload  = TestUpload->new( $fixture{under_limit} );
        my $result  = Ovid::Util::Image->process(
            upload   => $upload,
            filename => 'small.png',
        );
        ok $result->{success},                                  'success';
        is $result->{path}, '/static/images/small.png',         'path returned';
        ok -e $tempdir->child('root/static/images/small.png'),  'file in root/static/images/';
        ok -e $tempdir->child('static/images/small.png'),       'file mirrored to static/images/';
    };
};

subtest 'over-limit JPEG compresses via quality drop' => sub {
    $current_max = 300_000;
    _in_tempdir sub {
        my $tempdir = shift;
        my $upload  = TestUpload->new( $fixture{over_limit} );
        my $result  = Ovid::Util::Image->process(
            upload   => $upload,
            filename => 'big.jpg',
        );
        ok $result->{success}, 'success after compression';
        is $result->{path}, '/static/images/big.jpg', 'path returned';
        my $bytes = -s $tempdir->child('root/static/images/big.jpg');
        ok $bytes <= 300_000, "saved file is under limit ($bytes bytes)";
    };
};

subtest 'write_error: Imager::write returning false surfaces a write_error' => sub {
    $current_max = 300_000;
    _in_tempdir sub {
        my $tempdir = shift;
        my $upload  = TestUpload->new( $fixture{over_limit} );

        no warnings 'redefine';
        local *Imager::write = sub { return 0 };

        my $result = Ovid::Util::Image->process(
            upload   => $upload,
            filename => 'big.jpg',
        );
        ok !$result->{success},           'write_error returns failure';
        is $result->{code}, 'write_error', 'write_error code';
        like $result->{error}, qr/Failed to process image/, 'error message';
        ok !-e $tempdir->child('root/static/images/big.jpg'),
            'no file created on write_error';
    };
};

subtest 'too_large: image that defeats the compression loop' => sub {
    # incompressible.jpg is ~167KB on disk. To force the early-return
    # branch (line 68) to fall through into the loop, we lower the
    # limit far below 167KB. We pick 500 bytes — small enough that
    # even after 20 iterations of quality-drop + 0.9x scale-down the
    # surviving noisy JPEG cannot reach that floor.
    $current_max = 500;
    _in_tempdir sub {
        my $upload = TestUpload->new( $fixture{incompressible} );
        my $result = Ovid::Util::Image->process(
            upload   => $upload,
            filename => 'huge.jpg',
        );
        ok !$result->{success},           'too-large image rejected';
        is $result->{code}, 'too_large',  'too_large code';
        like $result->{error}, qr/Unable to compress image below/, 'error message';
        like $result->{error}, qr/after 20 attempts/, 'mentions attempt count';
    };
};

done_testing;
