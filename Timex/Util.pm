# -*- perl -*-

#
# $Id: Util.pm,v 1.2 2006/03/28 22:49:17 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 2006 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

package Timex::Util;

use strict;
use vars qw($VERSION);
$VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);

use Math::Complex qw(log10);

# von gnuplot3.5 (graphics.c) geklaut
sub make_tics {
    my($tmin, $tmax, $logscale, $base_log) = @_;

#    print STDERR "make_tics: $tmin, $tmax ... begin\n" if $debug;

    my $xr = abs($tmin - $tmax);    
    my $l10 = log10($xr);

    my($tic, $tics);
    if ($logscale) {
	$tic = dbl_raise($base_log, ($l10 >= 0 ? int($l10) : int($l10)-1));
	if ($tic < 1.0) {
	    $tic = 1.0;
	}
    } else {
	my $xnorm = 10 ** ($l10 - ($l10 >= 0 ? int($l10) : int($l10)-1));
	if ($xnorm <= 2) {
	    $tics = 0.2;
	} elsif ($xnorm <= 5) {
	    $tics = 0.5;
	} else {
	    $tics = 1.0; 
	}
	$tic = $tics * dbl_raise(10.0, ($l10 >= 0 ? int($l10) : int($l10)-1));
    }
    
#    print STDERR "make_tics: ... end\n" if $debug;

    $tic;
}

sub dbl_raise {
    my($x, $y) = @_;

    my $val = 1;
    my $i;
    for($i = 0; $i < abs($y); $i++) {
	$val *= $x;
    }

    if ($y < 0) {
	1/$val;
    } else {
	$val;
    }
}

1;

__END__
