#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: stattimex.pl,v 1.1 2002/03/15 19:09:07 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 2002 Online Office Berlin. All rights reserved.
#
# Mail: info@onlineoffice.de
# WWW:  http://www.onlineoffice.de
#

use FindBin;
use lib "$FindBin::RealBin";
use Timex::Project;
use Timex::Rcs;
use Getopt::Long;
use strict;

my $timexfile = "$ENV{HOME}/private/log/mytimex.pj1";
my $project;
my $verbose = 1;
my $filelist;

if (!GetOptions("timexfile|tf=s" => \$timexfile,
		"v!" => \$verbose,
		"filelist=s" => \$filelist,
	       )) {
    die "usage";
}

my $project_path = shift or die "Project pathname?";
my @files = @ARGV;

if ($filelist) {
    open(F, $filelist) or die "Can't open $filelist: $!";
    chomp(@files = <F>);
    close F;
}

if (!@files) {
    die "No files for project <$project_path> specified";
}

my $t = Timex::Project->new;
$t->load($timexfile) or die;
my $p = $t->find_by_pathname($project_path) or die "Can't find project in timex file";

my $totallines = 0;
foreach my $f (@files) {
    my @mods;

    if ($verbose) {
	warn "$f...\n";
    }

    open(RLOG, "rlog '$f' | grep '^date:.*' |");
    while(<RLOG>) {
	if (/date:\s+(\S+\s+\S+\d)/) {
	    my $rcsdate = $1;
	    my $epoch = Timex::Rcs::Revision::rcsdate2unixtime($rcsdate);
	    my $pluslines = 0;
	    if (/lines:\s+\+(\d+)\s+-\d+/) {
		$pluslines = $1;
	    }
	    $totallines += $pluslines;
	    unshift @mods, [$epoch, $pluslines, $rcsdate];
	} else {
	    warn "Can't parse rlog line $_";
	}
    }
    close RLOG;

#      for my $i (0 .. $#mods-1) {
#  	my $time = $p->sum_time($mods[$i]->[0], $mods[$i+1]->[0]);
#  	if ($time) {
#  	    warn int(86400*$mods[$i+1]->[1]/$time) . " $mods[$i+1]->[2]\n";
#  	} else {
#  	    warn "??? $mods[$i+1]->[1] lines in no time $mods[$i+1]->[2] ???\n";
#  	}
#      }
}

my $time = $p->sum_time(0);
print "Project $project_path: " . int(86400*$totallines/$time) . " lines/day\n";

__END__
