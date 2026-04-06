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

    # Also copy to static/images in project root
    my $project_root = path('.')->absolute;
    my $static_dir   = $project_root->child('static/images');
    $static_dir->mkpath unless $static_dir->exists;

    my $target_file = $target_dir->child($filename);
    my $static_file = $static_dir->child($filename);

    # Security check: Ensure filename doesn't traverse directories
    if ( $filename =~ m{/|\\} || $filename eq '.' || $filename eq '..' ) {
        return { success => 0, code => 'invalid_filename', error => 'Invalid filename' };
    }

    if ( ( $target_file->exists || $static_file->exists ) && !$overwrite ) {
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
        $target_file->copy( $static_file->stringify );
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
            $static_file->spew_raw($out_data);
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

__END__

=head1 NAME

Ovid::Util::Image - Process and optimize uploaded images for the website

=head1 SYNOPSIS

    use Ovid::Util::Image;

    my $result = Ovid::Util::Image->process(
        upload    => $dancer_upload,    # Dancer2::Core::Request::Upload
        filename  => 'my-photo.jpg',
        overwrite => 0,
    );

    if ( $result->{success} ) {
        say "Image saved to $result->{path}";
        # e.g. "/static/images/my-photo.jpg"
    }
    else {
        warn "Error ($result->{code}): $result->{error}";
    }

=head1 DESCRIPTION

Ovid::Util::Image handles image uploads for the live editor. It validates
the uploaded file, checks for supported formats (PNG, JPG, GIF), and ensures
the final file size is within the configured maximum (default 300KB from
L<Less::Config>).

Images that are already under the size limit are copied as-is to preserve
quality and animation (for GIFs). Oversized images are iteratively
compressed and downscaled using L<Imager> until they fit within the limit.
For JPEG images, quality is reduced first (from 80% down to 60%) before
spatial downscaling is applied.

Processed images are saved to both C<root/static/images/> (for the build
pipeline) and C<static/images/> (for immediate serving).

=head1 METHODS

=head2 process

    my $result = Ovid::Util::Image->process(
        upload    => $upload_object,
        filename  => 'image.jpg',
        overwrite => 1,             # optional, default 0
    );

Class method that processes an uploaded image. Parameters are validated
using L<Type::Params>.

B<Parameters:>

=over 4

=item C<upload> (required)

A L<Dancer2::Core::Request::Upload> object representing the uploaded file.

=item C<filename> (required)

The target filename. Must not contain path separators. Only C<.png>,
C<.jpg>, C<.jpeg>, and C<.gif> extensions are accepted.

=item C<overwrite> (optional)

Boolean. If false (the default), the method returns an error when a file
with the same name already exists.

=back

B<Returns> a hashref with the following structure:

On success:

    { success => 1, path => "/static/images/filename.jpg" }

On failure:

    { success => 0, code => $error_code, error => $message }

Possible error codes: C<invalid_filename>, C<exists>, C<invalid_type>,
C<invalid_image>, C<write_error>, C<too_large>.

=cut
