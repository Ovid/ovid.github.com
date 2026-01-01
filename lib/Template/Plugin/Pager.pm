package Template::Plugin::Pager;

use v5.40;
use base 'Template::Plugin';
use Less::Pager;
use Carp qw(croak);

sub new ( $class, $context, $params = {} ) {
    # Map directory names to article types and provide default
    my $type = $params->{type} // 'article';

    # Map 'articles' (directory) to 'article' (type)
    $type = 'article' if $type eq 'articles';

    # Default empty string to 'article'
    $type = 'article' if $type eq '';

    my $pager = eval {
        return Less::Pager->new( type => $type );
    };
    if ($@) {
        croak("Template::Plugin::Pager error: $@\n"
          . "Usage: [% USE pager = Pager(type => 'article') %] or [% USE pager = Pager(type => 'blog') %]");
    }
    return $pager;
}

1;

__END__

=head1 NAME

Template::Plugin::Pager - Thin wrapper for Less::Pager in Template Toolkit

=head1 SYNOPSIS

    # Using article type (singular form)
    [% USE pager = Pager(type => 'article') %]
    [% prev = pager.prev_post(directory, slug) %]
    [% next = pager.next_post(directory, slug) %]

    # Using directory name (automatically mapped)
    [% USE pager = Pager(type => type) %]  # where type='articles' or 'blog'
    [% prev = pager.prev_post(type, slug) %]
    [% next = pager.next_post(type, slug) %]

=head1 DESCRIPTION

This is a thin wrapper that allows Template Toolkit templates to use
C<Less::Pager> directly. All methods are delegated to C<Less::Pager>.

The plugin automatically maps directory names to article types:
C<'articles'> (directory) maps to C<'article'> (type), while C<'blog'>
remains unchanged. If no type is provided or an empty string is given,
it defaults to C<'article'>.

=head1 METHODS

See L<Less::Pager> for method documentation.

=cut
