# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2003,2005,2013 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://ptktools.sourceforge.net/
#

package Timex::Plugin;
use strict;
use vars qw($VERSION %plugins);
$VERSION = 0.03;

use File::Basename qw(fileparse);
use File::Spec::Functions qw(file_name_is_absolute);

BEGIN {
    if (!eval '
use Msg qw(frommain);
1;
') {
        warn $@ if $@;
        eval 'sub M ($) { $_[0] }';
        eval 'sub Mfmt { sprintf(shift, @_) }';
    }
}

sub new { bless {}, shift }

# from bbbike
sub load_plugin {
    my($self, $file) = @_;
    my @plugin_args;
    if ($file =~ /^(.*)=(.*)$/) {
	$file = $1;
	@plugin_args = split / /, $2;
    }
    my $mod = $self->load_file($file);
    return if $self->is_plugin_registered($mod);
    my $plugin_obj = bless { top => $main::top }, $mod;
    eval {
	$plugin_obj->register(@plugin_args);
    };
    if ($@) {
	my $err = $@;
	main::status_message(Mfmt("Couldn't register plugin %s. Reason: %s. A possible cause is case sensitivity.", $mod, $err), "warn");
	return;
    }

    $self->add_plugin(modname => $mod);
}

sub load_file {
    my($self, $file) = @_;

    my $mod;

    if ($file =~ /::/) {
	if (eval qq{ require $file; 1 }) {
	    $mod = $file;
	} else {
	    if ($@) {
		main::status_message(Mfmt("Couldn't load module %s. Reason: %s", $file, $@), "warn");
		return;
	    }
	}
    } else {
	$file .= ".pm" if ($file !~ /\.pm$/);
	($mod) = fileparse($file, '\..*');
	my $loading_error = 0;
	if (-r $file) {
	    do $file or do {
		main::status_message(Mfmt("Couldn't load file %s", $file), "warn");
		return;
	    };
	    $INC{"$mod.pm"} = $file;
	} elsif (-r "$FindBin::RealBin/$file") {
	    do "$FindBin::RealBin/$file" or do {
		main::status_message(Mfmt("Couldn't load file %s", "$FindBin::RealBin/$file"), "warn");
		return;
	    };
	    $INC{"$mod.pm"} = "$FindBin::RealBin/$file";
	} else {
	    my $ok = 0;
	    if (!file_name_is_absolute($file)) {
		foreach my $d (@INC) {
		    if (-r "$d/$file") {
			do $file;
			$INC{"$mod.pm"} = "$d/$file";
			$ok = 1;
			last;
		    }
		}
	    }

	    if (!$ok) {
		eval 'require $file';
		if ($@) {
		    main::status_message(Mfmt("Couldn't load file %s. Reason: %s", $file, $@), "warn");
		    return;
		}
	    }
	}
    }

    $mod;
}

sub add_plugin {
    my($self, %args) = @_;
    my $modname = $args{modname} || die "modname is missing";
    $self->{plugins}->{$modname} = { modname => $modname };
}

sub is_plugin_registered {
    my($self, $modname) = @_;
    exists $self->{plugins}->{$modname};
}

1;
