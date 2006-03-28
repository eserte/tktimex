#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: overlapping.t,v 1.2 2006/03/28 22:11:03 eserte Exp $
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

use FindBin;
use lib ("$FindBin::RealBin",
	 "$FindBin::RealBin/..",
	);
use Timex::Project;

my @tests = (
	     [500,1000,  0],
	     [500,1001,  1],
	     [500,999,   0],
	     [1000,2000, 1],
	     [500,3000,  1],
	     [2000,3000, 0],
	     [1000,4000, 1],
	    );
	     
plan tests => 2*scalar(@tests);

my $p = Timex::Project->new;
$p->{times} = [[1000,2000,"Foobar","Blafoo"],
	       [3000,4000,"Blabla","xyz"],
	      ];

for my $test (@tests) {
    my($from, $to, $yesno) = @$test;
    my($op,$ot) = $p->is_overlapping($from,$to);
    if ($yesno) {
	is($op, $p, "Test $from - $to -> yes");
	is(ref $ot, "ARRAY", "times interval is an interval");
    } else {
	is($op, undef, "Test $from - $to -> undef");
	is($ot, undef, "No times interval");
    }
}

__END__
