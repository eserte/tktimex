package Timex::Plugin::Iconmobile;
use strict;
use Time::Local;

sub register {
    my $export_menu = $main::mb_export;
    $export_menu->command(-label => "Iconmobile Timesheet",
			  -command => \&export_timesheet,
			 );
}

sub export_timesheet {
    my $root_project = $main::root;
    my @l = localtime;
    my $from = timelocal(0,0,0,@l[3,4,5]);
    my $to   = timelocal(59,59,23,@l[3,4,5]);
    my @sub_projects = $root_project->projects_by_interval($from, $to);
    my $out = "";
    $out .= "Timesheet Slaven Rezic " .
	sprintf("%04d-%02d-%02d", $l[5]+1900, $l[4]+1, $l[3]) . "\n";
    $out .= sprintf "%-50s %s\n", "Projekt", "Dauer";
    $out .= sprintf "%-50s %s\n", "",        "[Stunden]";
    for my $p (@sub_projects) {
	my $label = $p->pathname(", ");
	$label =~ s|^iconmobile(, )?||; # strip root part
	if ($label eq '') {
	    $label = "iconmobile admin";
	}
	my $hours = $p->sum_time($from, $to)/(60*60);
	$out .= sprintf "%-50s %.1f\n", $label, $hours;
    }

    print $out;

    $out;
}

1;
