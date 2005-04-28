# -*- perl -*-

#
# $Id: Plugin.pm,v 1.3 2005/04/28 22:09:53 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 2003 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://ptktools.sourceforge.net/
#

package Timex::Plugin;
use strict;
use vars qw($VERSION %plugins);
$VERSION = 0.02;

use File::Basename qw(fileparse);
use File::Spec::Functions qw(file_name_is_absolute);

# from bbbike
sub load_plugin {
    my $file = shift;
    my @plugin_args;
    if ($file =~ /^(.*)=(.*)$/) {
	$file = $1;
	@plugin_args = split / /, $2;
    }
    my $mod;
    if ($file =~ /::/) {
	if (eval qq{ require $file; 1 }) {
	    $mod = $file;
	} else {
	    if ($@) {
		warn sprintf("Das Modul %s konnte nicht geladen werden. Grund: %s", $file, $@);
		return;
	    }
	}
    } else {
	$file .= ".pm" if ($file !~ /\.pm$/);
	($mod) = fileparse($file, '\..*');
	my $loading_error = 0;
	if (-r $file) {
	    do $file or do {
		# XXX use status_message etc.
		warn "Die Datei $file konnte nicht geladen werden";
		return;
	    };
	    $INC{"$mod.pm"} = $file;
	} elsif (-r "$FindBin::RealBin/$file") {
	    do "$FindBin::RealBin/$file" or do {
		# XXX use status_message etc.
		warn "Die Datei $FindBin::RealBin/$file konnte nicht geladen werden";
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
		    warn sprintf("Die Datei %s konnte nicht geladen werden. Grund: %s", $file, $@);
		    return;
		}
	    }
	}
    }
    my $plugin_obj = bless { top => $main::top }, $mod;
    $plugin_obj->register(@plugin_args);
    if ($@) {
	my $err = $@;
	warn sprintf("Das Plugin %s konnte nicht registriert werden. Grund: %s", $mod, $err);
	return;
    }
}

1;
