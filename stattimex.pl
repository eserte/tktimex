#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: stattimex.pl,v 1.2 2003/03/28 16:52:29 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 2002 Online Office Berlin. All rights reserved.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

use FindBin;
use lib "$FindBin::RealBin";
use Timex::Project;
use Timex::Rcs;
use Getopt::Long;
use strict;

my $timexfile = "$ENV{HOME}/private/log/mytimex.pj1";
my $project;
my $recursive_project;
my $verbose = 1;
my $filelist;
my $changed_lines;

if (!GetOptions("timexfile|tf=s" => \$timexfile,
		"v!" => \$verbose,
		"filelist=s" => \$filelist,
		"r!" => \$recursive_project,
		"changed!" => \$changed_lines,
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

    if ($changed_lines) {
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

    } else {
	if ($f =~ /,v$/) {
	    chomp(my $lines = `co -p $f | wc -l`);
	    $totallines += $lines;
	} else {
	    chomp(my $lines = `cat $f | wc -l`);
	    $totallines += $lines;
	}
    }
}

my @sum_time_args = (0);
if ($recursive_project) {
    push @sum_time_args, undef, -recursive => 1;
}
my $time = $p->sum_time(@sum_time_args);
print <<EOF
Statistics for project $project_path (working day = 8h):
lines/day:  @{[ int((3600*8)*$totallines/$time) ]}
lines/hour: @{[ int(3600*$totallines/$time) ]}
lines:      $totallines
days:       @{[ int($time/(3600*8)) ]}
hours:      @{[ int($time/3600) ]}
EOF


__END__
