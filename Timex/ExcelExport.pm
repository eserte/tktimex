# -*- perl -*-

#
# $Id: ExcelExport.pm,v 1.1 2000/03/28 20:06:05 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 2000 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

package Timex::ExcelExport;
use Tk 800.012;
use Tk::Date;
use Time::Local;
use FindBin;
use Date::Calc qw(Week_Number);
use strict;

sub save_dialog {
    my($top, $root_project) = @_;
    my $t = $top->Toplevel;
    my $file;
    $t->title("Excel export");

    my $f = $t->Frame->pack(-fill => "x");
    $f->Label(-text => "Export file:")->pack(-side => "left");
    $f->Entry(-textvariable => \$file)->pack(-side => "left");
    $f->Button(-text => "Browse",
	       -command => sub {
		   $file = $f->getSaveFile
		       (-defaultextension => 'csv',
			-title => 'Excel export',
			-filetypes => [['CSV files', '.csv'],
				       ['All files',  '*']],
			);
	       })->pack(-side => "left");

    my %date;
    foreach my $p (qw(From To)) {
	$f = $t->Frame->pack(-fill => "x");
	$f->Label(-text => "$p:")->pack(-side => "left");
	$f->Date(-variable => \$date{$p},
		 -value => 'now',
		 -fields => 'date',
		 -datefmt => "%12A, %2d.%2m.%4y",
		 -choices => [qw(today yesterday),
			      ['one week before' => sub {time()-86400*7}],
			      ['four weeks before' => sub { time()-86400*7*4}],
			      ],
		 )->pack(-side => "left");
    }

    $f = $t->Frame->pack(-fill => "x");
    $f->Button(-text => "Export",
	       -command => sub {
		   if (!defined $file) {
		       $t->messageBox(-icon => "error",
				      -message => "No export file specified",
				      -title => "Can't export",
				      -type => 'OK');
		   } else {
		       my(@from_l) = localtime $date{From};
		       my(@to_l)   = localtime $date{To};
		       @from_l[0..2] = (0, 0, 0);
		       @to_l  [0..2] = (59, 59, 23);
		       my $from = timelocal @from_l;
		       my $to   = timelocal @to_l;

		       save($root_project, $file, $from, $to);

		       $t->destroy;
		   }
	       })->pack(-side => "left");
    $f->Button(-text => "Close",
	       -command => sub {
		   $t->destroy;
	       })->pack(-side => "left");
}

# XXX don't hardcode template file
sub save {
    my($root_project, $file, $from, $to) = @_;
    my(@sub_projects) = $root_project->projects_by_interval($from, $to);
    my $name = ((getpwuid($<))[6]);
    my $rate = 50; # XXX
    my(@l) = localtime $from;
    my $weeknumber = Week_Number($l[5]+1900, $l[4]+1, $l[3]);
    @l = localtime $to;
    my $to_week = Week_Number($l[5]+1900, $l[4]+1, $l[3]);
    if ($to_week != $weeknumber) {
	$weeknumber .= " - $to_week";
    }
    my $sum = 0;
    open(S, ">$file") or die $!;
    open(T, "$FindBin::RealBin/Timex/de_template.csv") or die $!; # XXX don't hardcode
    while(<T>) {
	if (/%%PROJECTNAME%%/) {
	    my $template_line = $_;
	    foreach my $p (@sub_projects) {
		my $this_line = $template_line;
		my $label = join("/", $p->path);
		$label =~ s|^/||; # strip root part
		my $hours = $p->sum_time($from, $to)/(60*60);
		my $rate  = $rate; # XXX
		my $projectsum = $hours * $rate;

		# round rates and hours
		$hours      = sprintf("%.1f", $hours);
		$projectsum = sprintf("%.2f", $projectsum);

		# fix for german excel XXX
		$hours       =~ s/\./,/;
		$rate        =~ s/\./,/;
		$projectsum  =~ s/\./,/;

		$sum += $projectsum;
		$this_line =~ s/%%PROJECTNAME%%/$label/g;
		$this_line =~ s/%%HOURS%%/$hours/g;
		$this_line =~ s/%%RATE%%/$rate/g;
		$this_line =~ s/%%PROJECTSUM%%/$projectsum/g;
		print S $this_line;
	    }
	} else {
	    s/%%NAME%%/$name/g;
	    s/%%WEEK%%/$weeknumber/g;
	    s/%%SUM%%/$sum/g;
	    print S $_;
	}
    }
    close T;
    close S;
}

1;

__END__
