#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: multiproject.t,v 1.1 2001/04/04 21:42:13 eserte Exp $
# Author: Slaven Rezic
#

use strict;
use vars qw($first_project_text $second_project_text);

use lib qw(.. ../..);
use Timex::MultiProject;

do "testprojects.pl";

BEGIN {
    if (!eval q{
	use Test;
	1;
    }) {
	print "# tests only work with installed Test module\n";
	print "1..1\n";
	print "ok 1\n";
	exit;
    }
}

BEGIN { plan tests => 0 }

open(W1, ">/tmp/t1.pj1") or die $!;
print W1 $first_project_text;
close W1;

open(W2, ">/tmp/t2.pj1") or die $!;
print W2 $second_project_text;
close W2;

my $mpj = new Timex::MultiProject;
ok(!!$mpj->isa("Timex::MultiProject"), 1);
$mpj->master("/tmp/t1.pj1");
ok($mpj->master, "/tmp/t1.pj1");
$mpj->backups("/nonexistent/t3.pj1", "/tmp/t2.pj1", "/nonexistent/t4.pj1");
ok(join(",",$mpj->backups),
   join(",","/nonexistent/t3.pj1", "/tmp/t2.pj1", "/nonexistent/t4.pj1"));

#ok(test, rightvalue, errormsg);
#skip(boolean expression, ?);

__END__
