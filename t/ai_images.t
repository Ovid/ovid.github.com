#!/usr/bin/env perl

use Test::Most;
use lib 'lib';
use Test::MockModule;
use Path::Tiny qw(path);
use File::Temp qw(tempdir tempfile);
use MIME::Base64;
use Ovid::Site::AI::Images;

# Test object creation with default attributes
my $ai = Ovid::Site::AI::Images->new;
isa_ok $ai, 'Ovid::Site::AI::Images', 'Created AI::Images object';
is $ai->model, 'gpt-4o-mini', 'Default model should be gpt-4o-mini';
is $ai->temperature, .1, 'Default temperature should be 0.1';
is $ai->system_message, 'You are an accessibility expert, able to describe images for the visually impaired',
  'Default system message should be set';
is $ai->prompt, 'Describe the image in one or two sentences.',
  'Default prompt should be set';

# Test object creation with custom attributes
my $custom_ai = Ovid::Site::AI::Images->new(
    model       => 'gpt-4o',
    temperature => 0.5,
    prompt      => 'Custom prompt',
);
is $custom_ai->model, 'gpt-4o', 'Custom model should be set';
is $custom_ai->temperature, 0.5, 'Custom temperature should be set';
is $custom_ai->prompt, 'Custom prompt', 'Custom prompt should be set';

# Test _read_image_as_base64 with a temporary test image
SKIP: {
    my $test_image = 'root/static/images/rss.png';
    skip "Test image $test_image not found", 2 unless -f $test_image;
    
    my $base64 = $ai->_read_image_as_base64($test_image);
    ok $base64, '_read_image_as_base64() should return base64 encoded data';
    like $base64, qr/^[A-Za-z0-9+\/]+=*$/, 'Base64 data should match expected pattern';
    unlike $base64, qr/\n/, 'Base64 data should not contain newlines';
}

# Test describe_image with mocked OpenAPI client - PNG file
{
    # Create a mock client object that doesn't make real API calls
    package MockOpenAIClient {
        sub new { bless {}, shift }
        sub createChatCompletion {
            my $mock_result = bless {
                _res => bless {
                    _success => 1,
                    _json => {
                        choices => [{
                            message => {
                                content => 'A beautiful test image showing a sample scene.'
                            }
                        }]
                    }
                }, 'MockHTTPResponse'
            }, 'MockOpenAIResult';
            return $mock_result;
        }
    }
    
    package MockOpenAIResult {
        sub res { shift->{_res} }
    }
    
    package MockHTTPResponse {
        sub is_success { shift->{_success} }
        sub json { shift->{_json} }
        sub to_string { "Mock error" }
    }
    
    # Create AI object with mocked client
    my $ai_with_mock = Ovid::Site::AI::Images->new(_client => MockOpenAIClient->new);
    
    # Create a temporary PNG file for testing
    my ($fh, $filename) = tempfile(SUFFIX => '.png', UNLINK => 1);
    print $fh "fake PNG data";
    close $fh;
    
    my $description = $ai_with_mock->describe_image($filename);
    is $description, 'A beautiful test image showing a sample scene.',
      'describe_image() should return description from API for PNG';
}

# Test describe_image with JPEG file
{
    package MockOpenAIClient2 {
        sub new { bless {}, shift }
        sub createChatCompletion {
            return bless {
                _res => bless {
                    _success => 1,
                    _json => {
                        choices => [{
                            message => {
                                content => 'A JPEG image description.'
                            }
                        }]
                    }
                }, 'MockHTTPResponse2'
            }, 'MockOpenAIResult2';
        }
    }
    
    package MockOpenAIResult2 {
        sub res { shift->{_res} }
    }
    
    package MockHTTPResponse2 {
        sub is_success { shift->{_success} }
        sub json { shift->{_json} }
    }
    
    my $ai_with_mock = Ovid::Site::AI::Images->new(_client => MockOpenAIClient2->new);
    
    my ($fh, $filename) = tempfile(SUFFIX => '.jpg', UNLINK => 1);
    print $fh "fake JPEG data";
    close $fh;
    
    my $description = $ai_with_mock->describe_image($filename);
    is $description, 'A JPEG image description.',
      'describe_image() should return description from API for JPEG';
}

# Test _extract_description with successful response
{
    my $mock_res = bless {
        _success => 1,
        _json => {
            choices => [{
                message => {
                    content => 'Extracted description text'
                }
            }]
        }
    }, 'MockHTTPResponse';
    
    my $mock_result = bless { _res => $mock_res }, 'MockOpenAIResult';
    
    my $description = $ai->_extract_description($mock_result);
    is $description, 'Extracted description text',
      '_extract_description() should extract content from successful response';
}

# Test _extract_description with API error
{
    my $mock_res = bless {
        _success => 0,
        _error => 'API Error: Rate limit exceeded'
    }, 'MockHTTPResponseError';
    
    package MockHTTPResponseError {
        sub is_success { 0 }
        sub to_string { shift->{_error} }
    }
    
    my $mock_result = bless { _res => $mock_res }, 'MockOpenAIResultError';
    
    package MockOpenAIResultError {
        sub res { shift->{_res} }
    }
    
    throws_ok { $ai->_extract_description($mock_result) }
      qr/API Error: Rate limit exceeded/,
      '_extract_description() should croak on API error';
}

# Test _extract_description with JSON decode error
{
    my $mock_res = bless {
        _success => 1,
    }, 'MockHTTPResponseBadJSON';
    
    package MockHTTPResponseBadJSON {
        sub is_success { 1 }
        sub json { die "JSON parse error" }
    }
    
    my $mock_result = bless { _res => $mock_res }, 'MockOpenAIResultBadJSON';
    
    package MockOpenAIResultBadJSON {
        sub res { shift->{_res} }
    }
    
    throws_ok { $ai->_extract_description($mock_result) }
      qr/Error decoding JSON/,
      '_extract_description() should croak on JSON decode error';
}

done_testing;
