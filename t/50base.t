#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: 50base.t,v 1.1 2003/03/28 17:09:36 eserte Exp $
# Author: Slaven Rezic
#

use strict;
use FindBin;
use File::Spec::Functions qw(catfile updir);

BEGIN {
    if (!eval q{
	use Test;
	1;
    }) {
	print "1..0 # skip: no Test module\n";
	exit;
    }
}

BEGIN { plan tests => 1 }

system("$^X", catfile($FindBin::RealBin, updir, "tktimex"),
       "-geometry", "500x300+10+10",
       catfile($FindBin::RealBin, "test.pj1"));
ok($? == 0);

__END__
