# -*- perl -*-

#
# $Id: Utmp.pm,v 1.4 2001/02/07 23:25:22 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 2000 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

# XXX change User::Utmp to support BSD ...

package Timex::Utmp;

use strict;
use vars qw($username_length $date_column $has_s);

BEGIN {
    if ($^O =~ /bsd/) {
	$username_length = 16; # XXX check this!
	$date_column = 43;
	$has_s = 1;
    } else { # e.g. linux
	# XXX better to use User::Utmp if available
	$username_length = 8;
	$date_column = 39;
	$has_s = 0;
    }
}

sub new {
    my $pkg = shift;
    my $self = {};
    bless $self, $pkg;
}

sub init {
    my $self = shift;
    local %ENV = %ENV;
    $ENV{LC_ALL} = $ENV{LANG} = $ENV{LC_TIME} = "C";
    my @lines;
    my $this_year = (localtime)[5]+1900;
    my $cmd = "last " . ($has_s ? "-s " : "");

    my $last_mon;
    my $mon;

    open(LAST, "$cmd|");

    while(<LAST>) {
	next if (/^(reboot|shutdown)\b/);
	next if (/^(\s*$|wtmp begins)/);
	chomp;
	my $user = substr($_, 0, $username_length);
	$user =~ s/\s+$//;
	my $date = substr($_, $date_column, 16);
	my $begin;
	if ($date =~ /^(?:...)\s+(...)\s+(\d+)\s+(\d+):(\d+)/) {
	    my $mon_abbrev = $1;
	    my $day = $2;
	    my $h = $3;
	    my $m = $4;
	    $mon = _monthabbrev_number($mon_abbrev);

	    if (defined $last_mon && $last_mon < $mon) {
		# wrap year
		$this_year--;
	    }

	    require Time::Local;
	    $begin = Time::Local::timelocal(0, $m, $h,
					    $day, $mon-1, $this_year-1900);
	}
	my $duration = 0;
	my $end;
	if (/still logged in\s*$/) {
	    $end = time;
	    $duration = $end - $begin;
	} else {
	    if ($has_s && /\(\s*(\d+)\)\s*$/) {
		$duration = $1;
	    } elsif (!$has_s && /\(\s*(\d+):(\d+)\)\s*$/) {
		$duration = $1*3600+$2*60;
	    }
	    $end = $begin + $duration;
	}
	push @lines, {User => $user, Begin => $begin, End => $end};

    } continue {

	$last_mon = $mon if defined $mon;

    }

    close LAST;

    $self->{Timestamp} = time;
    $self->{All} = \@lines;
}

sub update_if_necessary {
    my($self, $timeout) = @_;
    if (!defined $self->{Timestamp} ||
	time >= $self->{Timestamp}+$timeout) {
	$self->init;
    }
    $self;
}

sub restrict {
    my($self, %args) = @_;

    my @old_res = @{ $self->{All} };

    if (defined $args{User}) {
	my @res;
	foreach (@old_res) {
	    push @res, $_ if $_->{User} eq $args{User};
	}
	@old_res = @res;
    }

    if (defined $args{From} and defined $args{To}) {
	my @res;
	foreach (@old_res) {
	    my($begin, $end) = ($_->{Begin}, $_->{End});
	    if ($args{From} > $begin && $args{From} < $end) {
		$begin = $args{From};
	    }
	    if ($args{To} > $begin && $args{To} < $end) {
		$end   = $args{To};
	    }
	    if ($args{From} <= $begin && $args{To} >= $end) {
		push @res, {User => $_->{User},
			    Begin => $begin,
			    End => $end};
	    }
	}
	@old_res = @res;
    }

    @old_res;
}

# REPO BEGIN
# REPO NAME monthabbrev_number /home/e/eserte/src/repository 
# REPO MD5 5dc25284d4ffb9a61c486e35e84f0662

=head2 _monthabbrev_number($mon)

=for category Date

Return the number for the (English) abbreviated month name (e.g. "Sep"
=> 9).

=cut

sub _monthabbrev_number {
    my $mon = shift;
    +{'Jan' => 1,
      'Feb' => 2,
      'Mar' => 3,
      'Apr' => 4,
      'May' => 5,
      'Jun' => 6,
      'Jul' => 7,
      'Aug' => 8,
      'Sep' => 9,
      'Oct' => 10,
      'Nov' => 11,
      'Dec' => 12,
     }->{$mon};
}
# REPO END

1;

__END__
