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

    sub next ($self) {
        my $i = $self->_index;
        return if $i - 1 > $self->count;
        $self->_index( $i + 1 );
        my $file = $self->files->[$i];
        return $self->files->[$i];
    }

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
