# -*- perl -*-

#
# $Id: ExcelExport.pm,v 1.4 2000/09/01 23:35:16 eserte Exp $
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

my $excel;

sub save_dialog {
    my($top, $root_project, %args) = @_;
    my $t = $top->Toplevel;
    my $file;
    $t->title("Excel export");

    my $f = $t->Frame->pack(-fill => "x");
    $f->Label(-text => "Export file:")->pack(-side => "left");
    my $fe = $f->Entry(-textvariable => \$file)->pack(-side => "left");
    $fe->focus;

    my $can_xls = can_xls();
    my $def_ext = ($can_xls ? ".xls" : ".csv");
    my @filetypes =  (['CSV files', '.csv'],
		      ['All files',  '*'],
		      );
    if ($can_xls) {
	unshift @filetypes, ['Excel files', '.xls'];
    }

    $f->Button(-text => "Browse",
	       -command => sub {
		   $file = $f->getSaveFile
		       (-defaultextension => $def_ext,
			-title => 'Excel export',
			-filetypes => \@filetypes,
		       );
	       })->pack(-side => "left");

    my %date;
    foreach my $p (qw(From To)) {
	$f = $t->Frame->pack(-fill => "x");
	$f->Label(-text => "$p:",
		  -anchor => "e",
		  -width => 4)->pack(-side => "left");
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

		       save($root_project, $file, $from, $to, %args);

		       $t->destroy;
		   }
	       })->pack(-side => "left");
    $f->Button(-text => "Close",
	       -command => sub {
		   $t->destroy;
	       })->pack(-side => "left");
}

sub can_xls {
    eval {
	require Win32::OLE;
	$excel = Win32::OLE->GetActiveObject('Excel.Application');
	unless (defined $excel) {
	    $excel = Win32::OLE->new('Excel.Application', sub { $_[0]->Quit });
	}
    };
    defined $excel;
}

sub _excel_print_row {
    my $sheet = shift;
    my $row = shift;
    my $s = shift;
    my @s = split(/;/, $s);
    return if !@s;
    my $range = "A$row:" . chr(ord("A")-1+scalar @s).$row;
    $sheet->Range($range)->{Value} = [\@s];
}

sub save {
    my($root_project, $file, $from, $to, %args) = @_;
    my(@sub_projects) = $root_project->projects_by_interval($from, $to);
    my $name;
    eval {
	$name = ((getpwuid($<))[6]);
    };
    if (!defined $name) {
	$name = $ENV{USERNAME} || $ENV{USER} || "";
    }
    my $rate = $args{-hourlyrate};
    my $template_file = $args{-templatefile} || "Timex/de_template.csv";
    my(@l) = localtime $from;
    my $weeknumber = Week_Number($l[5]+1900, $l[4]+1, $l[3]);
    @l = localtime $to;
    my $to_week = Week_Number($l[5]+1900, $l[4]+1, $l[3]);
    if ($to_week != $weeknumber) {
	$weeknumber .= " - $to_week";
    }

    my $do_excel = (defined $excel && $file =~ /\.xls$/i);
    my($book, $sheet);
    my $sum = 0;

    if ($do_excel) {

	# write .xls file
	if (-f $file) {
	    $book = $excel->Workbooks->Open($file);
	    if (!$book) {
		die "Can't open Workbook $file: " . Win32::OLE::LastError();
	    }
	} else {
	    $book = $excel->Workbooks->Add;
	    if (!$book) {
		die "Can't create Workbook: " . Win32::OLE::LastError();
	    }
	    $book->SaveAs($file);
	}
	$sheet = $book->Worksheets(1);
	
    } else {

	# write .csv file
	open(S, ">$file") or die $!;
    }

    $template_file = _find_template_file($template_file);
    if (!$template_file) {
	die "Can't find template_file in @INC";
    }

    my $row = 0;
    open(T, $template_file) or die "Can't open $template_file: $!";
    while(<T>) {
	$row++;
	if (/%%PROJECTNAME%%/) {
	    my $template_line = $_;
	    foreach my $p (@sub_projects) {
		my $this_line = $template_line;
		my $label = $p->pathname("/"); #join("/", $p->path);
		$label =~ s|^/||; # strip root part
		my $hours = $p->sum_time($from, $to)/(60*60);
		my $rate  = $rate;
		my $projectsum = $hours * $rate;

		# round rates and hours
		$hours      = sprintf("%.1f", $hours);
		$projectsum = sprintf("%.2f", $projectsum);

		$sum += $projectsum;

		# fix for german excel XXX
		if (1||!$do_excel) {
		    $hours       =~ s/\./,/;
		    $rate        =~ s/\./,/;
		    $projectsum  =~ s/\./,/;
		}

		$this_line =~ s/%%PROJECTNAME%%/$label/g;
		$this_line =~ s/%%HOURS%%/$hours/g;
		$this_line =~ s/%%RATE%%/$rate/g;
		$this_line =~ s/%%PROJECTSUM%%/$projectsum/g;
		if ($do_excel) {
		    chomp $this_line;
		    _excel_print_row($sheet, $row, $this_line);
		} else {
		    print S $this_line;
		}
	    }
	} else {
	    s/%%NAME%%/$name/g;
	    s/%%WEEK%%/$weeknumber/g;
	    s/%%SUM%%/$sum/g;

	    if ($do_excel) {
		chomp;
		_excel_print_row($sheet, $row, $_);
	    } else {
		print S $_;
	    }
	}
    }
    close T;

    if ($do_excel) {
	$book->Save;
	$book->Close;
	undef $sheet;
	undef $book;
	undef $excel;
    } else {
	close S;
    }
}

sub _find_template_file {
    my $basename = shift;
    if (file_name_is_absolute($basename)) {
	return $basename;
    } else {
	foreach my $dir (@INC) {
	    my $f = "$dir/$basename"; # XXX use File::Spec
	    return $f if (-f $f and -r $f);
	}
    }
    undef;
}

# REPO BEGIN
# REPO NAME file_name_is_absolute /home/e/eserte/src/repository 
# REPO MD5 47355e35bcf03edac9ea12c6f8fff9a3
=head2 file_name_is_absolute($file)

Return true, if supplied file name is absolute. This is only necessary
for older perls where File::Spec is not part of the system.

=cut

sub file_name_is_absolute {
    my $file = shift;
    my $r;
    eval {
        require File::Spec;
        $r = File::Spec->file_name_is_absolute($file);
    };
    if ($@) {
	if ($^O eq 'MSWin32') {
	    $r = ($file =~ m;^([a-z]:(/|\\)|\\\\|//);i);
	} else {
	    $r = ($file =~ m|^/|);
	}
    }
    $r;
}
# REPO END

1;

__END__
