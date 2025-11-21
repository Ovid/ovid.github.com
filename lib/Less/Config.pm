package Less::Config;

use Less::Boilerplate;
use Config::Any;
use parent 'Exporter';
our @EXPORT_OK = qw(config);

sub config () {
    my $file   = 'config/ovid.yaml';
    my $config = Config::Any->load_files(
        {
            files       => [$file],
            use_ext     => 1,
            driver_args => {
                General => { -UTF8 => 1 },
            },
        }
    );
    my $conf = $config->[0]{$file};

    unless ( defined $conf->{max_image_size_bytes} && $conf->{max_image_size_bytes} =~ /^\d+$/ ) {
        die "max_image_size_bytes must be defined and be an integer in $file";
    }

    return $conf;
}

1;

__END__

=head1 NAME

Less::Config - get our config

=head1 SYNOPSIS

    use Less::Config qw(config);
    my $hashref = config();
    say $hashref->{url};

=head1 DESCRIPTION

Dead simple. The C<config()> function returns a hashref of key/value pairs.

=head1 ENTRIES

=head2 C<url>

    my $url = config()->{url};

Base URL of our site.

=head2 C<tagmap>

    my $tagname = config->{tagmap}{$tag}

Returns the public name of tags.
