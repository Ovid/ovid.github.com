package Ovid::Site {
    use Moose;
    use Less::Boilerplate;
    use Ovid::Types;

    sub build ($self) {
        $self->_assert_tt_config;
    }

    sub _assert_tt_config ($self) {
        unless ( -f "$ENV{HOME}/.ttreerc" ) {
            warn <<"END";
No $ENV{HOME}/.ttreerc file found

It should have a structure like this:

	verbose
	recurse

	color=1

	src  = ~/Dropbox/Mine/projects/perl/ovid.github.com/root
	dest  = ~/Dropbox/Mine/projects/perl/ovid.github.com/

	ignore = \b(CVS|RCS|sw[pot])\b
	ignore = ^#
	ignore = ^.git

	suffix tt=html
	suffix tt2markdown=html
END
            exit 1;
        }
    }
    __PACKAGE__->meta->make_immutable;
}
