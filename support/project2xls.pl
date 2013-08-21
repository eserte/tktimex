#!/usr/local/bin/perl -w
# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 1999 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

use FindBin;
use lib "$FindBin::RealBin/..";

use Timex::Project;
use Timex::ExcelExport;
use Getopt::Long;
use strict;

my $begin = beginning_of_month(time);
my $end   = time();

my $user;

if (!GetOptions
    ("lastmonth" => sub { $begin = beginning_of_month(time);
			  $begin--;
			  $begin = beginning_of_month($begin);
			  $end = end_of_month($begin);
		      },
     "thisweek"  => sub { $begin = beginning_of_week(time);
		      },
     "lastweek"  => sub { $begin = beginning_of_week(time);
			  $begin--;
			  $begin = beginning_of_week($begin);
			  $end = end_of_week($begin);
		      },
     "user=s" => \$user,
    )) {
    die "usage";
}

my $infile = shift or die "Please specify in file";
my $outfile = shift or die "Please specify out file";

my $p = new Timex::Project;
$p->load($infile);

my %args;
if ($user) {
    $args{-user} = $user;
}

Timex::ExcelExport::can_xls;
Timex::ExcelExport::save($p, $outfile, $begin, $end, %args);

# REPO BEGIN
# REPO NAME beginning_of_month /home/e/eserte/src/repository 
# REPO MD5 7ced08c1d3d1370a819921c6e5ded930

=head2 beginning_of_month($time)

=for category Date

Return time of beginning of month, 0:00:00. $time is optional and set to
current time, if missing.

=cut

sub beginning_of_month {
    require Time::Local;
    my $t = shift;
    $t = time if !defined $t;
    my @l = localtime $t;
    $l[0] = $l[1] = $l[2] = 0;
    $l[3] = 1;
    Time::Local::timelocal(@l);
}
# REPO END

# REPO BEGIN
# REPO NAME end_of_month /home/e/eserte/src/repository 
# REPO MD5 39f9c79ab682af1f8a46f9df8729e8b5

=head2 end_of_month($time)

=for category Date

Return time of end of month, 23:59:59. $time is optional and set to
current time, if missing.

DEPENDENCY: leapyear

=cut

sub end_of_month {
    require Time::Local;
    my $t = shift;
    $t = time if !defined $t;
    my @l = localtime $t;
    $l[3] = [31,28,31,30,31,30,31,31,30,31,30,31]->[$l[4]];
    $l[3]++ if $l[4] == 1 && leapyear($l[5]+1900);
    $l[0] = $l[1] = 59;
    $l[2] = 23;
    Time::Local::timelocal(@l);
}
# REPO END

# REPO BEGIN
# REPO NAME beginning_of_week /home/e/eserte/src/repository 
# REPO MD5 7f22817ad1bc06070f44208b3292fbca

=head2 beginning_of_week($time)

=for category Date

Return time of beginning of week, 0:00:00. $time is optional and set to
current time, if missing.

=cut

sub beginning_of_week {
    require Time::Local;
    my $t = shift;
    $t = time if !defined $t;
    my @l = localtime $t;
    $l[6] = 7 if $l[6] == 0;
    $t -= 86400*($l[6]-1);
    @l = localtime $t;
    $l[0] = $l[1] = $l[2] = 0;
    Time::Local::timelocal(@l);
}
# REPO END

# REPO BEGIN
# REPO NAME end_of_week /home/e/eserte/src/repository 
# REPO MD5 af0272c7a050bed54f176e90016bd983

=head2 end_of_week($time)

=for category Date

Return time of end of week, 23:59:59. $time is optional and set to
current time, if missing.

=cut

sub end_of_week {
    require Time::Local;
    my $t = shift;
    $t = time if !defined $t;
    my @l = localtime $t;
    $l[6] = 7 if $l[6] == 0;
    $t += 86400*(7-$l[6]);
    @l = localtime $t;
    $l[0] = $l[1] = 59;
    $l[2] = 23;
    Time::Local::timelocal(@l);
}
# REPO END

__END__
