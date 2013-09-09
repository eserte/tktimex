#
# Copyright 2013 Slaven Rezic.
#

package Timex::Plugin::ScreenSaver;

use strict;
our $VERSION = '0.02';

use POSIX 'strftime';

our $X;
our @screensaver_states;
our $last_screensaver_state;
our $tl;

use constant MAX_SCREENSAVER_STATES => 100;

sub register {
    my $self = shift;
    my $top = $self->{top};

    if (!eval {
	require X11::Protocol;
	$X = X11::Protocol->new;
	$X->init_extension('MIT-SCREEN-SAVER')
	    or die "MIT-SCREEN-SAVER extension not available or CPAN module X11::Protocol::Ext::MIT_SCREEN_SAVER not installed";
	1;
    }) {
	$top->messageBox("Cannot install " . __PACKAGE__ . " plugin.\nDetailed error: $@");
	return;
    }

    my $project_menu = $main::mb_project_menu;
    $project_menu->command(
			   -label => 'Screensaver times',
			   -command => sub { $self->show_screensaver_times },
			  );

    $self->check_screensaver;
    $top->repeat(10*1000, sub { $self->check_screensaver });
}

sub check_screensaver {
    my $self = shift;
    my $now_screensaver_state = $self->is_screensaver_on;
    if (defined $last_screensaver_state && $now_screensaver_state != $last_screensaver_state) {
	push @screensaver_states, { epoch => time, state => $now_screensaver_state };
	if (@screensaver_states > MAX_SCREENSAVER_STATES) {
	    splice @screensaver_states, 0, @screensaver_states - MAX_SCREENSAVER_STATES;
	}
	$self->update_screensaver_times;
    }
    $last_screensaver_state = $now_screensaver_state;
}

sub show_screensaver_times {
    my $self = shift;
    my $tl_created;
    if (Tk::Exists($tl)) {
	$tl->raise;
    } else {
	$tl = $self->{top}->Toplevel(-title => 'Screensaver times');
	$tl_created = 1;
    }
    my $lb = $tl->Subwidget('lb');
    if (!$lb) {
	$lb = $tl->Scrolled('Listbox', -scrollbars => 'osoe')->pack(qw(-fill both -expand 1));
	$tl->Advertise(lb => $lb);
    }
    if ($tl_created) {
	$tl->Button(-text => 'Close',
		    -command => sub { $tl->destroy }
		   )->pack(-fill => 'x');
    }

    $self->update_screensaver_times;
}

sub update_screensaver_times {
    my($self) = @_;
    return if !$tl;
    my $lb = $tl->Subwidget('lb');
    return if !$lb;
    $lb->delete(0, 'end');
    $lb->insert('end', map {
	strftime("%F %T", localtime $_->{epoch}) . ": " . ($_->{state} ? 'on' : 'off')
    } @screensaver_states);
    $lb->see('end');
}

sub is_screensaver_on {
    my($on_or_off) = $X->MitScreenSaverQueryInfo($X->root);
    $on_or_off eq 'On' ? 1 : 0;
}

1;
