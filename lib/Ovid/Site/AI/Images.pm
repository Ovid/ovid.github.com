package Ovid::Site::AI::Images;

use Less::Boilerplate;
use Carp;
use OpenAPI::Client::OpenAI;
use Path::Tiny qw(path);
use MIME::Base64;
use Moo;
use experimental 'try';
use namespace::autoclean;

has system_message => (
    is => 'ro',
    default =>
      'You are an accessibility expert, able to describe images for the visually impaired'
);

# gpt-4o-mini is smaller and cheaper than gpt4o, but it's still very good.
# Also, it's multi-modal, so it can handle images and some of the older
# vision models have now been deprecated.
has model       => ( is => 'ro', default => 'gpt-4o-mini' );
has temperature => ( is => 'ro', default => .1 );
has prompt      => (
    is      => 'ro',
    default => 'Describe the image in one or two sentences.',
);
has _client =>
  ( is => 'ro', default => sub { OpenAPI::Client::OpenAI->new } );

sub describe_image ( $self, $filename ) {
    my $filetype = $filename =~ /\.png$/ ? 'png' : 'jpeg';
    my $image    = $self->_read_image_as_base64($filename);
    my $message  = {
        body => {
            model    => 'gpt-4o-mini',    # $self->model,
            messages => [
                {
                    role    => 'system',
                    content => $self->system_message,
                },
                {
                    role    => 'user',
                    content => [
                        {
                            text => $self->prompt,
                            type => 'text'
                        },

                        {
                            type      => "image_url",
                            image_url => {
                                url => "data:image/$filetype;base64, $image"
                            }
                        }
                    ],
                }
            ],
            temperature => $self->temperature,
        },
    };
    my $response = $self->_client->createChatCompletion($message);
    return $self->_extract_description($response);
}

sub _extract_description ( $self, $response ) {
    if ( $response->res->is_success ) {
        my $result;
        try {
            my $json = $response->res->json;
            $result = $json->{choices}[0]{message}{content};
        }
        catch ($e) {
            croak("Error decoding JSON: $e");
        }
        return $result;
    }
    else {
        my $error = $response->res;
        croak( $error->to_string );
    }
}

sub _read_image_as_base64 ( $self, $file ) {
    my $content = Path::Tiny->new($file)->slurp_raw;

    # second argument is the line ending, which we don't
    # want as a newline because OpenAI doesn't like it
    return encode_base64( $content, '' );
}

1;

__END__

=head1 NAME

Ovid::Site::AI::Images - AI image tools

=head1 SYNOPSIS

    my $chat = Image::Describe::OpenAI->new;
    unless ( $image->exists ) {
        croak "File does not exist or is not readable: $image\n";
    }
    my $response = $chat->describe_image($image);
