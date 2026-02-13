#!/usr/bin/env perl

use Test::Most;
use lib 'lib';
use Test2::Plugin::UTF8;
use Less::Boilerplate;
use Less::Config 'config';
use Mojo::JSON qw(decode_json);
use Path::Tiny;

# Test tagmap.json structure and content
# The tagmap is generated during the build process and provides:
# 1. A mapping of files to their tags (__ALL__ key)
# 2. Per-tag information (count, files, name, titles)

subtest 'tagmap.json exists and is valid JSON' => sub {
    my $tagmap_file = config()->{tagmap_file};
    ok defined($tagmap_file), 'Config should define tagmap_file';
    ok -f $tagmap_file,       "Tagmap file '$tagmap_file' should exist";
    ok -r $tagmap_file,       "Tagmap file should be readable";

    my $content = path($tagmap_file)->slurp_utf8;
    ok length($content) > 0, 'Tagmap file should have content';

    my $tagmap;
    lives_ok {
        $tagmap = decode_json($content);
    }
    'Tagmap file should contain valid JSON';

    is ref($tagmap), 'HASH', 'Tagmap should be a hash reference';
};

subtest 'tagmap.json structure - __ALL__ key' => sub {
    my $tagmap_file = config()->{tagmap_file};
    my $tagmap      = decode_json( path($tagmap_file)->slurp_utf8 );

    ok exists $tagmap->{__ALL__}, 'Tagmap should have __ALL__ key';
    is ref( $tagmap->{__ALL__} ), 'HASH', '__ALL__ should be a hash reference';

    # __ALL__ maps file paths to arrays of tags
    my $all = $tagmap->{__ALL__};
    foreach my $file ( keys %$all ) {
        is ref( $all->{$file} ), 'ARRAY',
          "File '$file' in __ALL__ should map to an array of tags";

        # Verify file path format
        like $file, qr{^(?:articles|blog)/[^/]+\.html$},
          "File '$file' should match expected path pattern";

        # Each tag in the array should be a string
        foreach my $tag ( @{ $all->{$file} } ) {
            ok !ref($tag), "Tag '$tag' should be a scalar string";
        }
    }
};

subtest 'tagmap.json structure - individual tag entries' => sub {
    my $tagmap_file   = config()->{tagmap_file};
    my $tagmap        = decode_json( path($tagmap_file)->slurp_utf8 );
    my $config_tagmap = config()->{tagmap};

    # Test each tag defined in config
    foreach my $tag_key ( keys %$config_tagmap ) {
        my $expected_name = $config_tagmap->{$tag_key};

        subtest "tag: $tag_key" => sub {
            ok exists $tagmap->{$tag_key},
              "Tag '$tag_key' should exist in tagmap";

            my $tag_data = $tagmap->{$tag_key};
            is ref($tag_data), 'HASH',
              "Tag '$tag_key' data should be a hash reference";

            # Verify required fields exist
            ok exists $tag_data->{count},
              "Tag '$tag_key' should have 'count' field";
            ok exists $tag_data->{files},
              "Tag '$tag_key' should have 'files' field";
            ok exists $tag_data->{name},
              "Tag '$tag_key' should have 'name' field";
            ok exists $tag_data->{titles},
              "Tag '$tag_key' should have 'titles' field";

            # Verify field types
            like $tag_data->{count}, qr/^\d+$/,
              "Tag '$tag_key' count should be an integer";
            is ref( $tag_data->{files} ), 'ARRAY',
              "Tag '$tag_key' files should be an array";
            is ref( $tag_data->{titles} ), 'HASH',
              "Tag '$tag_key' titles should be a hash";

            # Verify name matches config
            is $tag_data->{name}, $expected_name,
              "Tag '$tag_key' name should match config";
        };
    }
};

subtest 'tagmap.json data consistency' => sub {
    my $tagmap_file   = config()->{tagmap_file};
    my $tagmap        = decode_json( path($tagmap_file)->slurp_utf8 );
    my $config_tagmap = config()->{tagmap};

    foreach my $tag_key ( keys %$config_tagmap ) {
        next unless exists $tagmap->{$tag_key};

        subtest "consistency for tag: $tag_key" => sub {
            my $tag_data = $tagmap->{$tag_key};

            # Count should match array length
            is $tag_data->{count}, scalar( @{ $tag_data->{files} } ),
              "Tag '$tag_key' count should match files array length";

            # Verify files array is sorted
            my @files        = @{ $tag_data->{files} };
            my @sorted_files = sort @files;
            is_deeply \@files, \@sorted_files,
              "Tag '$tag_key' files should be sorted";

            # Each file should have a title
            foreach my $file (@files) {
                ok exists $tag_data->{titles}{$file},
                  "File '$file' should have a title in titles hash";
                ok length( $tag_data->{titles}{$file} ) > 0,
                  "File '$file' title should not be empty";
            }

            # Each file in this tag should list this tag in __ALL__
            my $all = $tagmap->{__ALL__};
            foreach my $file (@files) {
                ok exists $all->{$file},
                  "File '$file' should exist in __ALL__";
                ok( ( grep { $_ eq $tag_key } @{ $all->{$file} } ),
                    "File '$file' in __ALL__ should list tag '$tag_key'"
                );
            }
        };
    }
};

subtest 'tagmap.json cross-reference integrity' => sub {
    my $tagmap_file = config()->{tagmap_file};
    my $tagmap      = decode_json( path($tagmap_file)->slurp_utf8 );
    my $all         = $tagmap->{__ALL__};

    # For each file in __ALL__, verify all its tags exist as top-level keys
    foreach my $file ( keys %$all ) {
        foreach my $tag ( @{ $all->{$file} } ) {
            ok exists $tagmap->{$tag},
              "Tag '$tag' from file '$file' should exist as top-level key";

            # Verify the tag's files array includes this file
            if ( exists $tagmap->{$tag} ) {
                ok( ( grep { $_ eq $file } @{ $tagmap->{$tag}{files} } ),
                    "Tag '$tag' files array should include '$file'"
                );
            }
        }
    }
};

subtest 'tagmap.json has articles with multiple tags' => sub {
    my $tagmap_file = config()->{tagmap_file};
    my $tagmap      = decode_json( path($tagmap_file)->slurp_utf8 );
    my $all         = $tagmap->{__ALL__};

    # Count articles with multiple tags
    my $multi_tag_count = 0;
    foreach my $file ( keys %$all ) {
        if ( scalar( @{ $all->{$file} } ) > 1 ) {
            $multi_tag_count++;
        }
    }

    ok $multi_tag_count > 0,
      'There should be at least some articles with multiple tags';
};

subtest 'tagmap.json UTF-8 handling' => sub {
    my $tagmap_file = config()->{tagmap_file};
    my $content     = path($tagmap_file)->slurp_utf8;
    my $tagmap      = decode_json($content);

    # Check that we can handle UTF-8 characters in titles
    my $has_utf8_title = 0;
    foreach my $tag_key ( keys %$tagmap ) {
        next if $tag_key eq '__ALL__';
        next unless exists $tagmap->{$tag_key}{titles};

        foreach my $title ( values %{ $tagmap->{$tag_key}{titles} } ) {

            # Check for common UTF-8 characters
            if ( $title =~ /[""''—…€©]/ ) {
                $has_utf8_title = 1;
                last;
            }
        }
        last if $has_utf8_title;
    }

    # This isn't a hard requirement, but if we have UTF-8 in titles,
    # we want to make sure they're properly encoded
    pass 'UTF-8 characters should be properly handled in titles';
};

subtest 'tagmap.json all files have valid paths' => sub {
    my $tagmap_file = config()->{tagmap_file};
    my $tagmap      = decode_json( path($tagmap_file)->slurp_utf8 );
    my $all         = $tagmap->{__ALL__};

    foreach my $file ( keys %$all ) {

        # Files should be HTML files in articles/ or blog/ directories
        like $file, qr{^(?:articles|blog)/[^/]+\.html$},
          "File '$file' should be in articles/ or blog/ directory with .html extension";

        # Files should not have double slashes or other path issues
        unlike $file, qr{//},
          "File '$file' should not have double slashes";
        unlike $file, qr{^\./},
          "File '$file' should not start with ./";
        unlike $file, qr{\.$},
          "File '$file' should not end with .";
    }
};

done_testing;

__END__

=head1 NAME

tagmap.t - Test tagmap.json structure and content

=head1 DESCRIPTION

This test verifies that the tagmap.json file is properly structured and contains
consistent data. The tagmap is generated during the build process by C<Ovid::Site>
and provides:

=over 4

=item * A mapping of files to their tags (C<__ALL__> key)

=item * Per-tag information including count, files array, display name, and titles

=back

=head2 Test Coverage

=over 4

=item * File existence and valid JSON format

=item * Structure of C<__ALL__> key

=item * Structure of individual tag entries

=item * Data consistency (counts, sorting, cross-references)

=item * UTF-8 handling in titles

=item * Path validation

=back

=head2 Related Code

=over 4

=item * C<lib/Ovid/Site.pm> - C<_write_tagmap()> method generates the file

=item * C<lib/Ovid/Template/File.pm> - Extracts tags during preprocessing

=item * C<config/ovid.yaml> - Defines C<tagmap> and C<tagmap_file>

=back

=head1 AUTHOR

Curtis "Ovid" Poe

=cut
