package Template::Plugin::Pager;

use v5.40;
use base 'Template::Plugin';
use Less::Pager;

sub new ( $class, $context, $params = {} ) {
    return Less::Pager->new( $params->%* );
}

1;

__END__

=head1 NAME

Template::Plugin::Pager - Thin wrapper for Less::Pager in Template Toolkit

=head1 SYNOPSIS

    [% USE pager = Pager(type => 'article') %]
    [% prev = pager.prev_post(type, slug) %]
    [% next = pager.next_post(type, slug) %]

=head1 DESCRIPTION

This is a thin wrapper that allows Template Toolkit templates to use
C<Less::Pager> directly. All methods are delegated to C<Less::Pager>.

=head1 METHODS

See L<Less::Pager> for method documentation.

=cut
