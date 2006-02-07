#
# Copyright 2006 Slaven Rezic.
#

package Timex::Plugin::OvertimeAlarm;

use strict;
our $VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);

use Data::Dumper   qw();
use File::Basename qw(dirname);
use Safe	   qw();
use Storable	   qw(dclone);
use Time::Local	   qw(timelocal);

our $alarm_task;
our $alarm_timer;

our $interval = 60;

our %alarm_shown;

our $DEBUG = 1;

sub register {
    my $self = shift;
    $self->{config} = {};

    my $options_menu = $main::mb_options;

    my $overtime_menu = $options_menu->Menu;
    $options_menu->cascade(-label => "Overtime Alarm",
			   -menu => $overtime_menu);

    $overtime_menu->command(-label => "Configure ...",
			    -command => sub { $self->configure_alarm },
			   );
    
    $overtime_menu->checkbutton(-label => "Alarm task running",
				-variable => \$alarm_task,
				-onvalue => 1,
				-offvalue => 0,
				-command => sub { $self->alarm_task_change },
			       );

    if ($DEBUG) {
	$overtime_menu->command(-label => "Check times",
				-command => sub { $self->check_times },
			       );
	$overtime_menu->command(-label => "Reset alarm_shown",

				-command => sub { %alarm_shown = () },
			       );
    }

    $self->load_config;

    $alarm_task = 1 if !defined $alarm_task;
    $self->alarm_task_change;
}

sub alarm_task_change {
    my($self) = @_;
    if ($alarm_task) {
	return if ($alarm_timer);
	$alarm_timer = $self->{top}->repeat($interval*1000, sub { $self->check_times });
    } else {
	if ($alarm_timer) {
	    $alarm_timer->cancel;
	}
	undef $alarm_timer;
    }
}

sub restart_alarm_task {
    my $self = shift;
    $alarm_timer = 0;
    $self->alarm_task_change;
    $alarm_timer = 1;
    $self->alarm_task_change;
}

sub check_times {
    my($self) = @_;
    my $cfg = $self->{config};
    my %max_time;
    while(my($period, $time) = each %{ $cfg->{period} }) {
	$max_time{$period} = $time * 3600;
    }

    my $now = time;
    my @l = localtime $now;
    @l[0,1,2] = (0,0,0);
    my $today_token = sprintf "%04d-%02d-%02d", $l[5]+1900, $l[4]+1, $l[3];

    my %begin_of;
    $begin_of{day}   = timelocal(@l);
    {
	my @l = @l;
	@l[3] = 1;
	$begin_of{month} = timelocal(@l);
    }
    {
	my @l = @l;
	@l[3] -= ($l[6] == 0 ? 6 : $l[6]-1);
	$begin_of{week} = timelocal(@l);
    }

    my %time;
    for my $period (qw(day week month)) {
	$time{$period} = 0;
    }

    for my $p ($main::root->subproject) {
	for my $period (keys %time) {
	    $time{$period} += $p->sum_time($begin_of{$period}, $now, -recursive => 1);
	}
    }

    my %need_alarm;
    for my $period (keys %time) {
	next if !$max_time{$period}; # probably not configured yet...
	if ($time{$period} > $max_time{$period} &&
	    (!exists $alarm_shown{$period} || $alarm_shown{$period} ne $today_token)) {
	    $need_alarm{$period}++;
	}
    }

    if (keys %need_alarm) {
	my $text = "";
	for my $period (keys %need_alarm) {
	    $text .= ucfirst($period) . ": worked " . s2hm($time{$period}) . ", expected " . s2hm($max_time{$period}) . "\n";
	    $alarm_shown{$period} = $today_token;
	}
	$self->{top}->messageBox(-title => "OvertimeAlarm",
				 -icon => "info",
				 -message => $text,
				);
    }
}

sub configure_alarm {
    my $self = shift;
    my $top = $self->{top};
    my $cfg = dclone $self->{config};

    my $t = $top->Toplevel(-title => "Configure OvertimeAlarm");
    Tk::grid($t->Label(-text => "Enter times in hours"),
	     -columnspan => 2);

    for my $def (["Daily", "day", 8],
		 ["Weekly", "week", 40],
		 ["Monthly", "month", 173],
		) {
	my($label, $cfgname, $default) = @$def;
	$cfg->{period}->{$cfgname} ||= $default;

	Tk::grid($t->Label(-text => $label),
		 $t->Entry(-textvariable => \$cfg->{period}->{$cfgname},
			   -width => 5,
			  ),
		);
    }
    {
	my $f = $t->Frame->grid(-sticky => "ew");
	$f->Button(-text => "Ok",
		   -command => sub {
		       while(my($k,$v) = each %$cfg) {
			   $self->{config}->{$k} = $v;
		       }
		       $self->restart_alarm_task;
		       $self->save_config;
		       $t->destroy;
		   },
		  )->pack(-side => "left");
	$f->Button(-text => "Cancel",
		   -command => sub {
		       $t->destroy;
		   },
		  )->pack(-side => "left");
    }
}

sub load_config {
    my $self = shift;
    my $cpt = Safe->new;
    my $res = $cpt->rdo($self->get_config_filename);
    if (ref $res eq 'HASH') {
	$self->{config} = $res;
    } else {
	main::status_message("Cannot load configuration from " . $self->get_config_filename . ", maybe not existing (call configure first!) or wrong data in it (if this is the case, delete the file)", "err");
    }
}

sub save_config {
    my $self = shift;
    open my $fh, ">" . $self->get_config_filename
	or do {
	    main::status_message("Cannot write to " . $self->get_config_filename . ": $!", "err");
	    return;
	};
    my $dump = Data::Dumper->new([$self->{config}],[qw(config)])->Indent(1)->Useqq(1)->Dump;
    print $fh $dump;
}

sub get_config_filename {
    my $rcdir = dirname(main::get_tktimexrc_file());
    $rcdir . "/.tktimex_overtime_rc";
}

# from BBBikeUtil
sub s2hm {
    my $s = shift;
    sprintf "%d:%02d", $s/3600, ($s%3600)/60;
}

1;
