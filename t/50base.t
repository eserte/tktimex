#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: 50base.t,v 1.4 2006/01/09 21:42:17 eserte Exp $
# Author: Slaven Rezic
#

use strict;
use FindBin;

BEGIN {
    if (!eval q{
	use Test;
	use File::Spec::Functions qw(catfile updir);
	1;
    }) {
	print "1..0 # skip: no Test and/or File::Spec::Functions module\n";
	exit;
    }
}

BEGIN { plan tests => 1 }

if (!defined $ENV{BATCH}) { $ENV{BATCH} = 1 }

my $pid = fork;
if (!$pid) {
    my @cmd = ("$^X", catfile($FindBin::RealBin, updir, "tktimex"),
	       "-geometry", "500x300+10+10",
	       "-plugins", "Timex::Plugin::Null",
	       catfile($FindBin::RealBin, "test.pj1"));
    exec @cmd;
    die "Can't execute @cmd: $!";
}
if ($ENV{BATCH}) {
    sleep 1;
    kill 9 => $pid;
    ok(1);
} else {
    waitpid($pid, 0);
    ok($? == 0);
}

__END__
