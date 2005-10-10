#!/usr/local/bin/perl -w
# -*- perl -*-

#
# $Id: base.t,v 1.11 2005/10/10 19:14:21 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 1998,2005 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

use FindBin;
use lib ("$FindBin::RealBin/..");
use Timex::Project;
use Getopt::Long;

use strict;
use vars qw($first_project_text $second_project_text);

do "$FindBin::RealBin/testprojects.pl";

my $d;
GetOptions("d|debug!" => \$d) or die "usage!";

if ($d) {
    require Data::Dumper;
}

my $p1 = new Timex::Project;
my $p2 = new Timex::Project;

my @data1 = split(/\n/, $first_project_text);
my @data2 = split(/\n/, $second_project_text);

$p1->interpret_data(\@data1);
$p2->interpret_data(\@data2);

print STDERR "Merge yields: " . Data::Dumper::Dumper($p1->merge($p2)) . "\n"
    if $d;

print STDERR Data::Dumper::Dumper($p1->merge($p2, -allowduplicates => 1)) . "\n"
    if $d;

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


my $sp = $p2->find_by_pathname(join($p2->separator,
				 "main project", "sub of main project"
				));
warn $sp->parent->dump_data if $d;
$sp->delete_times(1,3);
warn $sp->parent->dump_data if $d;
$sp->move_times_after(1, -1);
warn $sp->parent->dump_data if $d;
$sp->sort_times;
warn $sp->parent->dump_data if $d;

warn "Before delete of " . $sp->pathname . ":\n" . $p2->dump_data if $d;
$sp->delete;
warn "After delete:\n" . $p2->dump_data if $d;

warn
    "All subprojects of " . $p2->label . ":\n",
    join("\n", map { $_->label } $p2->all_subprojects), "\n"
    if $d;

print STDERR
    "Last four projects: " if $d;
my @last = $p2->last_projects(4);
foreach (@last) {
    print STDERR $_->label, " " if $d;
}
print STDERR "\n" if $d;

print STDERR "Restimes1:\n" if $d;
my @res_times = $p2->restricted_times(0);
foreach (@res_times) {
    printf STDERR "%-40s %10d %10d\n", $_->[0]->pathname, $_->[1], $_->[2] if $d;
}

print STDERR "Restimes1:\n" if $d;
@res_times = $p2->restricted_times(123456780, 887113908);
foreach (@res_times) {
    printf STDERR "%-40s %10d %10d\n", $_->[0]->pathname, $_->[1], $_->[2] if $d;
}

use Timex::Project::XML;
use File::Compare;
my $xml_p = new Timex::Project::XML;
$xml_p->load("$FindBin::RealBin/testdata.xml");
$xml_p->save("/tmp/test.xml");
$xml_p->load("/tmp/test.xml");
if (compare("$FindBin::RealBin/testdata.xml", "/tmp/test.xml") != 0) {
    warn "Hmmm while comparing xml data (?)";
}

#use Data::Dumper; print STDERR "Line " . __LINE__ . ", File: " . __FILE__ . "\n" . Data::Dumper->Dumpxs([$xml_p],[]); # XXX

