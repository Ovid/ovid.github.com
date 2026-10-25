package Ovid::Util::URLPath;

use v5.40;
use Exporter 'import';

our @EXPORT_OK = qw(url_to_file);

sub url_to_file ( $root, @segments ) {

    # Reject any segment starting with '.' (covers '..', '.git', '.env',
    # editor swapfiles, etc.) before any filesystem touch.
    return ( undef, 403 ) if grep {/^\./} @segments;

    my $path_str = join( '/', @segments );

    # URL → filesystem resolution. Three shapes:
    #   - Empty or trailing slash, e.g. /projects/extraction/  → serve
    #     <path>/index.html
    #   - Extensionless final segment, e.g. /blog/foo → serve
    #     <path>.html if it exists, else <path>/index.html (so /blog →
    #     blog.html even though blog/ is also a directory, and
    #     /projects/extraction → projects/extraction/index.html).
    #   - Anything with an extension is passed through unchanged.
    my $final_segment = $segments[-1] // '';
    if ( $final_segment eq '' ) {
        $path_str .= 'index.html';
    }
    elsif ( $final_segment !~ /\./ ) {
        if ( -f $root->child("$path_str.html") ) {
            $path_str .= '.html';
        }
        elsif ( -f $root->child("$path_str/index.html") ) {
            $path_str .= '/index.html';
        }
        else {
            # Neither exists; keep the .html shape for the 404 message.
            $path_str .= '.html';
        }
    }

    my $file = $root->child($path_str);
    return ( $file, 404 ) unless -f $file;

    # Defense in depth: confirm the realpath still lies inside the project
    # root (catches symlink trickery).
    my $resolved = eval { $file->realpath };
    return ( undef, 403 ) if !defined $resolved || index( "$resolved", "$root/" ) != 0;

    return ( $file, 200 );
}

1;

__END__

=head1 NAME

Ovid::Util::URLPath - Map a site URL path to the generated file that serves it

=head1 SYNOPSIS

    use Ovid::Util::URLPath qw(url_to_file);

    my ( $file, $status ) = url_to_file( path('.')->realpath, qw(tags trench) );
    # $file is tags/trench.html, $status is 200

=head1 DESCRIPTION

Both local development servers, F<bin/review> and L<Ovid::App::LiveEditor>,
serve the generated site. This module holds the one shared rule for turning a
URL path into a file, matching how GitHub Pages serves the site in production.

=head1 FUNCTIONS

=head2 url_to_file

    my ( $file, $status ) = url_to_file( $root, @segments );

C<$root> is the project root as an absolute, real L<Path::Tiny> path.
C<@segments> are the URL path segments, split on C</>; an empty final segment
means the URL had a trailing slash.

Returns the L<Path::Tiny> file and an HTTP status:

=over 4

=item * C<200> - the file exists inside C<$root>.

=item * C<404> - no such file. C<$file> is the path that was looked for.

=item * C<403> - a segment starts with C<.>, or the file is a symlink resolving
outside C<$root>. C<$file> is C<undef>.

=back

Resolution:

=over 4

=item * No segments serves F<index.html>.

=item * A trailing slash serves F<< <path>/index.html >>.

=item * A final segment with no dot prefers F<< <path>.html >>, falling back
to F<< <path>/index.html >>. So C</tags/trench> serves F<tags/trench.html> and
C</projects/extraction> serves F<projects/extraction/index.html>.

=item * Anything else is served as is.

=back

=cut
