# -*- perl -*-

#
# $Id: Export.pm,v 1.1 1999/11/07 02:35:43 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 1999 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

package Timex::Project::Export;
use base qw(Timex::Project);

my $default_gtt_file = <<EOF;
[Placement]
Dock=Toolbar\\0,1,0,0\\Menubar\\0,0,0,0

[Misc]
TimerRunning=0
NumProjects=0

[Display]
ShowSecs=true
ShowTableHeader=true
ShowStatusbar=true

[Toolbar]
ShowIcons=true
ShowTexts=true
ShowTips=true
ShowNew=true
ShowFile=false
ShowCCP=false
ShowProp=true
ShowTimer=true
ShowPref=true
ShowHelp=true
ShowExit=true

[LogFile]
Use=false
Entry=
EntryStop=
MinSecs=0

[CList]
ColumnWidth0=62
ColumnWidth1=62
ColumnWidth2=120
ColumnWidth3=0
EOF

sub as_gtt {
    my $self = shift;

    my $gnomedir = "$ENV{HOME}/.gnome";
    my $gttfile  = "$gnomedir/gtt";
    if (!-d $gnomedir) {
	mkdir $gnomedir, 0700;
    }
    if (!-d $gnomedir) {
	die "Can't create $gnomedir ... maybe $ENV{HOME} is missing?";
    }
    my $lastproject = -1;
    if (-f $gttfile) {
	open(F, "+<$gttfile") or die "Can't open $gttfile";
	while(<F>) {
	    if (/^\[Project(\d+)\]/ and $1 > $lastproject) {
		$lastproject = $1;
	    }
	}
	# XXX weitermachen...
	print F "\n";
	close F;
    } # XXX else Standarddatei abspeichern, und weiter wie oben
}

# XXX Abspeichern für karm

1;

__END__
