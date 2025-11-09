package Ovid::Template::File::Collection {
    use Moose;
    use Ovid::Template::File;
    use Ovid::Types qw(
      ArrayRef
      Bool
      InstanceOf
      NonEmptySimpleStr
      PositiveOrZeroInt
    );
    use Less::Script;
    with qw(Ovid::Template::Role::Debug);

    has files => (
        traits   => ['Array'],
        is       => 'rw',
        isa      => ArrayRef [NonEmptySimpleStr|InstanceOf['Ovid::Template::File']],
        writer => '_files',
        required => 1,
        handles  => {
            count => 'count',
            all   => 'elements',
        },
    );

    has raw => (
        is      => 'ro',
        isa     => 'Bool',
        default => 0,
    );

    has _index => (
        is       => 'rw',
        isa      => PositiveOrZeroInt,
        default  => 0,
        init_arg => undef,
    );

    sub BUILD ($self, @) {
        return if $self->raw;
        my @files = sort { $b->date cmp $a->date } map { $self->_get_file($_) } $self->files->@*;
        $self->_files(\@files);
    }

    # TODO (Coverage Improvement 001): Verify template usage before removal
    # Iterator method - may be called from templates via FOREACH loops or TT NEXT directive
    # Static analysis cannot detect Template Toolkit iterator usage patterns
    # See: specs/001-test-coverage-improvement/unused-code-decisions.md
    sub next ($self) {
        my $i = $self->_index;
        return if $i - 1 > $self->count;
        $self->_index( $i + 1 );
        my $file = $self->files->[$i];
        return $self->files->[$i];
    }

    # TODO (Coverage Improvement 001): Verify template usage before removal
    # Iterator reset method - typically paired with next() for template iterations
    # Static analysis cannot detect Template Toolkit iterator usage patterns
    # See: specs/001-test-coverage-improvement/unused-code-decisions.md
    sub reset ($self) {
        $self->_index(0);
    }

    sub _get_file ( $self, $file ) {
        my $orig = $file;
        if ( $file =~ s/\.html$// ) {
            $file = "root/$file.tt";
            if ( !-e $file ) {
                $file .= "2markdown";
                if ( !-e $file ) {
                    croak("Cannot find template file for $orig");
                }
            }
        }
        elsif ( !-e $file ) {
            croak("Cannot find file: '$file'");
        }
        return Ovid::Template::File->new( filename => $file, references => $orig );
    }

    __PACKAGE__->meta->make_immutable;
}

__END__

=head1 NAME

Ovid::Template::File::Collection - Manage and iterate over collections of template files

=head1 SYNOPSIS

    use Ovid::Template::File::Collection;

    # Create with array of filenames
    my $collection = Ovid::Template::File::Collection->new(
        files => ['template1.html', 'template2.html'],
    );

    # Or with existing Template::File objects
    $collection = Ovid::Template::File::Collection->new(
        files => [$template1, $template2],
        raw   => 1,  # Skip processing/sorting
    );

    # Iterate through files
    while (my $file = $collection->next) {
        process_template($file);
    }

    # Reset iterator
    $collection->reset;

    # Get total count
    my $total = $collection->count;

=head1 DESCRIPTION

C<Ovid::Template::File::Collection> provides an interface for managing
collections of template files. It supports both raw filenames and
L<Ovid::Template::File> objects, handles file resolution, and provides
iteration capabilities.

By default, files are sorted by date in descending order when the collection is
created. This behavior can be disabled by setting C<raw> to true.

=head1 ATTRIBUTES

=head2 files

    has files => (
        traits   => ['Array'],
        is       => 'rw',
        isa      => ArrayRef[NonEmptySimpleStr|InstanceOf['Ovid::Template::File']],
        required => 1,
    );

An arrayref of template files. Can contain either filenames (as strings) or
L<Ovid::Template::File> objects. Required at construction time.

=head2 raw

    has raw => (
        is      => 'ro',
        isa     => 'Bool',
        default => 0,
    );

If true, skips processing and sorting of files during construction. Defaults to false.

=head1 METHODS

=head2 new

    my $collection = Ovid::Template::File::Collection->new(
        files => \@files,
        raw   => 0,
    );

Constructor. Creates a new collection instance. If C<raw> is false (default), processes
all files in the collection, converting them to L<Ovid::Template::File> objects and
sorting them by date.

=head2 next

    my $file = $collection->next;

Returns the next file in the collection. Returns C<undef> when there are no more files.
Files are returned in sorted order (by date, descending) unless C<raw> was set to true
during construction.

=head2 reset

    $collection->reset;

Resets the internal iterator to the beginning of the collection.

=head2 count

    my $total = $collection->count;

Returns the total number of files in the collection.

=head2 all

    my @files = $collection->all;

Returns all files in the collection as a list.

=head1 PRIVATE METHODS

=head2 _get_file

Internal method that handles file resolution and creation of L<Ovid::Template::File>
objects. Supports both direct template files and HTML files that need to be converted
to template format.

For HTML files:
    1. Tries root/$name.tt
    2. Falls back to root/$name.tt2markdown
    3. Croaks if neither exists

=head1 DEPENDENCIES

=over 4

=item * L<Moose>

=item * L<Ovid::Template::File>

=item * L<Ovid::Types>

=item * L<Less::Script>

=back

=head1 ROLES

Implements L<Ovid::Template::Role::Debug>

=head1 SEE ALSO

=over 4

=item * L<Ovid::Template::File>

=item * L<Ovid::Template::Role::Debug>

=back

=head1 AUTHOR

[Author Name] E<lt>author@example.comE<gt>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under the same terms as Perl itself.

=cut
