#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: split.t,v 1.2 2006/03/28 21:48:05 eserte Exp $
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

plan tests => 9;

my $p = Timex::Project->new;
$p->{times} = [[1000,2000,"Foobar","Blafoo"],
	       [3000,4000,"Blabla","xyz"],
	      ];

eval { $p->split_time(0, [3000]) };
ok(defined $@, "split time in invalid range");
eval { $p->split_time(0, [2000]) };
ok(defined $@, "split time in slightly invalid range");
eval { $p->split_time(2, [2000]) };
ok(defined $@, "split time for invalid index");

my $old_sum = $p->sum_time;
$p->split_time(0, [1100,1500,1900]);
is(scalar @{$p->{times}}, 5, "Expected number of intervals");
my $new_sum = $p->sum_time;
is($old_sum, $new_sum, "Summary of times did not change");

is($p->{times}[0][$p->TIMES_FROM], 1000);
is($p->{times}[0][$p->TIMES_TO], 1100);
is($p->{times}[1][$p->TIMES_FROM], 1100);
is($p->{times}[1][$p->TIMES_TO], 1500);

__END__
