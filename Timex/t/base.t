#!/usr/local/bin/perl -w
# -*- perl -*-

#
# $Id: base.t,v 1.10 2001/04/04 22:39:34 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 1998 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

use lib qw(..);
use Timex::Project;

do "testprojects.pl";

my $p1 = new Timex::Project;
my $p2 = new Timex::Project;

my @data1 = split(/\n/, $first_project_text);
my @data2 = split(/\n/, $second_project_text);

$p1->interpret_data(\@data1);
$p2->interpret_data(\@data2);

warn "Merge yields: " . $p1->merge($p2);

warn $p1->merge($p2, -allowduplicates => 1);

#print $p1->dump_data;

# print map { $_->pathname } $p2->find_by_pathname("main project")->subproject;
# print  "\n";

# print join($p2->separator,
# 	   "main project", "sub of main project"
# 	  ), "\n";
# print map {join("-", @$_)} @{$p2->find_by_pathname(join($p2->separator,
# 				 "main project", "sub of main project"
# 				)
# 			   )->{'times'}}, "\n";;
# print $p2->find_by_pathname("main project");


$sp = $p2->find_by_pathname(join($p2->separator,
				 "main project", "sub of main project"
				));
print $sp->parent->dump_data;
$sp->delete_times(1,3);
print $sp->parent->dump_data;
$sp->move_times_after(1, -1);
print $sp->parent->dump_data;
$sp->sort_times;
print $sp->parent->dump_data;

print "Before delete of " . $sp->pathname . ":\n" . $p2->dump_data;
$sp->delete;
print "After delete:\n" . $p2->dump_data;

print
    "All subprojects of " . $p2->label . ":\n",
    join("\n", map { $_->label } $p2->all_subprojects), "\n";

print
    "Last four projects: ";
@last = $p2->last_projects(4);
foreach (@last) {
    print $_->label, " ";
}
print "\n";

print "Restimes1:\n";
@res_times = $p2->restricted_times(0);
foreach (@res_times) {
    printf "%-40s %10d %10d\n", $_->[0]->pathname, $_->[1], $_->[2];
}

print "Restimes1:\n";
@res_times = $p2->restricted_times(123456780, 887113908);
foreach (@res_times) {
    printf "%-40s %10d %10d\n", $_->[0]->pathname, $_->[1], $_->[2];
}

use Timex::Project::XML;
use File::Compare;
my $xml_p = new Timex::Project::XML;
$xml_p->load("testdata.xml");
$xml_p->save("/tmp/test.xml");
$xml_p->load("/tmp/test.xml");
if (compare("testdata.xml", "/tmp/test.xml") != 0) {
    warn "Hmmm while comparing xml data (?)";
}

#use Data::Dumper; print STDERR "Line " . __LINE__ . ", File: " . __FILE__ . "\n" . Data::Dumper->Dumpxs([$xml_p],[]); # XXX

