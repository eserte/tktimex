#
# Copyright 2004 Slaven Rezic.
#

# For a test, add Timex::Plugin::Null to the plugins list
# in the option editor of tktimex.

package Timex::Plugin::Null;

use strict;
our $VERSION = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);

sub register {
    my $export_menu = $main::mb_export;

    my $null_menu = $export_menu->Menu;
    $export_menu->cascade(-label => "Null Plugin",
			  -menu => $null_menu);

    $null_menu->command(-label => "Null Command",
			-command => \&null_command,
		      );
}

sub null_command {
    my $top = $main::top;
    $top->messageBox(-message => "This is the Null plugin");
}

1;
