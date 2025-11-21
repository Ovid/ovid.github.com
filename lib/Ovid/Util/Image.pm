package Ovid::Util::Image;

use v5.40;
use Imager;
use Path::Tiny;
use Less::Config    qw(config);
use Type::Params    qw(compile);
use Types::Standard qw(Object Str Bool Optional);

sub process ( $class, %args ) {
    state $check = compile(
        Object,            # upload (Dancer2::Core::Request::Upload)
        Str,               # filename
        Optional [Bool]    # overwrite
    );
    my ( $upload, $filename, $overwrite ) = $check->( @args{qw(upload filename overwrite)} );

    my $max_bytes  = config()->{max_image_size_bytes} // 300_000;
    my $root       = path('root')->absolute;
    my $target_dir = $root->child('static/images');
    $target_dir->mkpath unless $target_dir->exists;

    my $target_file = $target_dir->child($filename);

    # Security check: Ensure filename doesn't traverse directories
    if ( $filename =~ m{/|\\} || $filename eq '.' || $filename eq '..' ) {
        return { success => 0, code => 'invalid_filename', error => 'Invalid filename' };
    }

    if ( $target_file->exists && !$overwrite ) {
        return { success => 0, code => 'exists', error => 'File exists' };
    }

    # Validate extension
    unless ( $filename =~ /\.(png|jpg|jpeg|gif)$/i ) {
        return { success => 0, code => 'invalid_type', error => 'Invalid file type. Only PNG, JPG, GIF allowed.' };
    }

    my $temp_path = $upload->tempname;
    my $size      = -s $temp_path;

    # If size is already OK, just copy it (but maybe strip metadata via Imager?)
    # Spec says "downscale or recompress ... skipping upscaling for smaller images".
    # It implies we should process it.
    # Also "capture metadata" is done in the UI, not here.
    # But "recompress" implies we should load and save it to ensure it's clean.

    my $img = Imager->new( file => $temp_path );
    unless ($img) {
        return { success => 0, code => 'invalid_image', error => 'Could not parse image: ' . Imager->errstr };
    }

    # If size is OK, we might still want to save via Imager to sanitize?
    # But if it's a GIF, we might lose animation if we are not careful.
    # Imager handles animated GIFs if configured.
    # For MVP, let's assume if it's small enough, we just copy it to preserve quality/animation.
    # UNLESS the user wants us to "recompress".
    # The spec says "skipping upscaling for smaller images".
    # I'll assume: if size <= max_bytes, copy.
    # If size > max_bytes, process.

    if ( $size <= $max_bytes ) {
        $upload->copy_to( $target_file->stringify );
        return { success => 1, path => "/static/images/$filename" };
    }

    # Too big, try to compress/resize
    my $quality      = 80;    # Start with 80% quality for JPEG
    my $scale        = 1.0;
    my $attempts     = 0;
    my $max_attempts = 20;

    my $out_data;
    my $format = $filename =~ /\.png$/i ? 'png' : ( $filename =~ /\.gif$/i ? 'gif' : 'jpeg' );

    while ( $attempts < $max_attempts ) {
        $attempts++;

        # Scale if needed (after first attempt, or if we decide to scale)
        if ( $scale < 1.0 ) {
            my $new_width = int( $img->getwidth * $scale );

            # scale() returns a new image
            my $scaled_img = $img->scale( xpixels => $new_width );

            # Use the scaled image for saving
            $img = $scaled_img;

            # Reset scale for next iteration (we scaled the object, so next time we scale THAT)
            # Wait, if we loop, we are scaling the ALREADY scaled image.
            # That's fine, we are reducing it further.
            $scale = 0.9;    # Reduce by 10% each time
        }
        else {
            $scale = 0.9;    # Prepare for next time
        }

        # Try to write to memory to check size
        $out_data = undef;
        my %write_args = ( data => \$out_data, type => $format );
        if ( $format eq 'jpeg' ) {
            $write_args{jpegquality} = $quality;
        }
        elsif ( $format eq 'png' ) {
            $write_args{pngcompressionlevel} = 9;
        }

        $img->write(%write_args) or do {
            return { success => 0, code => 'write_error', error => 'Failed to process image: ' . $img->errstr };
        };

        if ( length($out_data) <= $max_bytes ) {
            $target_file->spew_raw($out_data);
            return { success => 1, path => "/static/images/$filename" };
        }

        # If still too big:
        if ( $format eq 'jpeg' && $quality > 60 ) {
            $quality -= 10;    # Reduce quality first for JPEG
            $scale = 1.0;      # Don't scale yet if we just reduced quality
        }

        # Else, we will scale in next iteration (scale is set to 0.9)
    }

    return {
        success => 0, code => 'too_large',
        error   => "Unable to compress image below "
          . ( $max_bytes / 1000 )
          . "KB. Final size: "
          . ( length($out_data) / 1000 )
          . "KB after $attempts attempts."
    };
}

1;
