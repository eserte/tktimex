#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: rcs.t,v 1.1 2007/12/08 16:44:46 eserte Exp $
# Author: Slaven Rezic
#

use strict;

BEGIN {
    if (!eval q{
	use Test::More;
	1;
    }) {
	print "1..0 # skip: no Test::More module\n";
	exit;
    }
}

plan tests => 3;

use_ok("Timex::Rcs");

{
    my $t = Timex::Rcs::Revision::rcsdate2unixtime("2004-07-21 19:55:07 +0200");
    is($t, 1090432507, "new-styled RCS date");
}

{
    my $t = Timex::Rcs::Revision::rcsdate2unixtime("2004/07/21 19:55:07");
    is($t, 1090432507, "old-styled RCS date");
}


__END__
