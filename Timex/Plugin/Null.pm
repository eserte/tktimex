#
# Copyright 2004 Slaven Rezic.
#

# For a test, add Timex::Plugin::Null to the plugins list
# in the option editor of tktimex.

package Timex::Plugin::Null;

use strict;
our $VERSION = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);

use Hooks;

sub register {
    my $self = shift;

    my $export_menu = $main::mb_export;

    my $null_menu = $export_menu->Menu;
    $export_menu->cascade(-label => "Null Plugin",
			  -menu => $null_menu);

    $null_menu->command(-label => "Null Command",
			-command => sub { $self->null_command },
		      );

    $self->add_hooks;
}

sub add_hooks {
    my($self) = @_;
    Hooks::get_hooks("before_start_project")->add
	    (sub { $self->on_start_project_hook(@_) }, __PACKAGE__);
    # XXX on deregister: Hooks::get_hooks("before_start_project")->del(__PACKAGE__)
}

sub null_command {
    my $self = shift;
    my $top = $self->{top};
    $top->messageBox(-message => "This is the Null plugin");
}

sub on_start_project_hook {
    my($self, $p) = @_;
    my $top = $self->{top};
    $top->messageBox(-message => "About to start project " . $p->pathname);
    1; # true for check_start_project
}

1;
