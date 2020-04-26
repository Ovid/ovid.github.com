package Template::Plugin::Blogdown;
use strict;
use base qw (Template::Plugin::Filter);
use Text::Markdown::Blog;

our $VERSION = 0.02;

sub init {
    my $self = shift;
    $self->{_DYNAMIC} = 1;
    $self->install_filter($self->{_ARGS}->[0] || 'blogdown');
    $self;
}

sub filter {
    my ($self, $text, $args, $config) = @_;
    my $m = Text::Markdown::Blog->new;
    return $m->blogdown($text);
}

1;

__END__

=head1 NAME

Template::Plugin::Blogdown - TT plugin for Text::Markdown::Blog

=head1 SYNOPSIS

  [% USE Blogdown -%]
  [% FILTER blogdown %]
  #Foo
  Bar
  ---
  *Italic* blah blah
  **Bold** foo bar baz
  [%- END %]

=head1 DESCRIPTION

Template::Plugin::Markdown is a plugin for TT, which format your text with Markdown Style.

=head1 SEE ALSO

L<Template>, L<Text::Markdown>, L<Text::Markdown::Blog>

=head1 AUTHOR

    Ovid. Based on Template::Plugin::Markdown by Naoya Ito E<lt>naoya@bloghackers.netE<gt>.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

