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
    is      => 'ro',
    default => 'You are an accessibility expert, able to describe images for the visually impaired'
);

# gpt-4o-mini is smaller and cheaper than gpt4o, but it's still very good.
# Also, it's multi-modal, so it can handle images and some of the older
# vision models have now been deprecated.
has model       => ( is => 'ro', default => 'gpt-4o-mini' );
has temperature => ( is => 'ro', default => .1 );
has prompt => (
    is      => 'ro',
    default => 'Describe the image in one or two sentences.',
);
has _client => ( is => 'ro', default => sub { OpenAPI::Client::OpenAI->new } );

sub describe_image ( $self, $filename ) {
    my $filetype = $filename =~ /\.png$/ ? 'png' : 'jpeg';
    my $image    = $self->_read_image_as_base64($filename);
    my $message  = {
        body => {
            model    => $self->model,
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
                            image_url => { url => "data:image/$filetype;base64, $image" }
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

    my $chat = Ovid::Site::AI::Images->new;
    unless ( $image->exists ) {
        croak "File does not exist or is not readable: $image\n";
    }
    my $response = $chat->describe_image($image);

=head1 DESCRIPTION

Uses the OpenAI API (via L<OpenAPI::Client::OpenAI>) to generate accessibility
descriptions for images. The image is base64-encoded and sent to a
multi-modal model which returns a short textual description suitable for use
as alt text.

=head1 METHODS

=head2 new

    my $ai = Ovid::Site::AI::Images->new(
        model       => 'gpt-4o-mini',   # optional, default 'gpt-4o-mini'
        temperature => 0.1,              # optional, default 0.1
        prompt      => 'Describe ...',   # optional
    );

Constructor. All attributes are optional and have sensible defaults.

=head2 describe_image

    my $description = $ai->describe_image($filename);

Reads the image at C<$filename>, sends it to the OpenAI API, and returns a
one- or two-sentence text description. Croaks on API errors or JSON decoding
failures.

=head2 system_message

    my $msg = $ai->system_message;

Returns the system prompt sent to the model. Read-only.

=head2 model

    my $model = $ai->model;

Returns the OpenAI model name. Read-only.

=head2 temperature

    my $temp = $ai->temperature;

Returns the sampling temperature. Read-only.

=head2 prompt

    my $prompt = $ai->prompt;

Returns the user prompt sent alongside the image. Read-only.
