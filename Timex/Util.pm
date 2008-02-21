# -*- perl -*-

#
# $Id: Util.pm,v 1.3 2008/02/21 22:51:55 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 2006,2008 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

package Timex::Util;

use strict;
use vars qw($VERSION @EXPORT_OK);
$VERSION = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);

use base qw(Exporter);
@EXPORT_OK = qw(is_in_path save_pwd);

use Math::Complex qw(log10);

# von gnuplot3.5 (graphics.c) geklaut
sub make_tics {
    my($tmin, $tmax, $logscale, $base_log) = @_;

#    print STDERR "make_tics: $tmin, $tmax ... begin\n" if $debug;

    my $xr = abs($tmin - $tmax);    
    my $l10 = log10($xr);

    my($tic, $tics);
    if ($logscale) {
	$tic = dbl_raise($base_log, ($l10 >= 0 ? int($l10) : int($l10)-1));
	if ($tic < 1.0) {
	    $tic = 1.0;
	}
    } else {
	my $xnorm = 10 ** ($l10 - ($l10 >= 0 ? int($l10) : int($l10)-1));
	if ($xnorm <= 2) {
	    $tics = 0.2;
	} elsif ($xnorm <= 5) {
	    $tics = 0.5;
	} else {
	    $tics = 1.0; 
	}
	$tic = $tics * dbl_raise(10.0, ($l10 >= 0 ? int($l10) : int($l10)-1));
    }
    
#    print STDERR "make_tics: ... end\n" if $debug;

    $tic;
}

sub dbl_raise {
    my($x, $y) = @_;

    my $val = 1;
    my $i;
    for($i = 0; $i < abs($y); $i++) {
	$val *= $x;
    }

    if ($y < 0) {
	1/$val;
    } else {
	$val;
    }
}

# REPO BEGIN
# REPO NAME is_in_path /home/e/eserte/work/srezic-repository 
# REPO MD5 e18e6687a056e4a3cbcea4496aaaa1db

=head2 is_in_path($prog)

=for category File

Return the pathname of $prog, if the program is in the PATH, or undef
otherwise.

DEPENDENCY: file_name_is_absolute

=cut

sub is_in_path {
    my($prog) = @_;
    if (file_name_is_absolute($prog)) {
	if ($^O eq 'MSWin32') {
	    return $prog       if (-f $prog && -x $prog);
	    return "$prog.bat" if (-f "$prog.bat" && -x "$prog.bat");
	    return "$prog.com" if (-f "$prog.com" && -x "$prog.com");
	    return "$prog.exe" if (-f "$prog.exe" && -x "$prog.exe");
	    return "$prog.cmd" if (-f "$prog.cmd" && -x "$prog.cmd");
	} else {
	    return $prog if -f $prog and -x $prog;
	}
    }
    require Config;
    %Config::Config = %Config::Config if 0; # cease -w
    my $sep = $Config::Config{'path_sep'} || ':';
    foreach (split(/$sep/o, $ENV{PATH})) {
	if ($^O eq 'MSWin32') {
	    # maybe use $ENV{PATHEXT} like maybe_command in ExtUtils/MM_Win32.pm?
	    return "$_\\$prog"     if (-f "$_\\$prog" && -x "$_\\$prog");
	    return "$_\\$prog.bat" if (-f "$_\\$prog.bat" && -x "$_\\$prog.bat");
	    return "$_\\$prog.com" if (-f "$_\\$prog.com" && -x "$_\\$prog.com");
	    return "$_\\$prog.exe" if (-f "$_\\$prog.exe" && -x "$_\\$prog.exe");
	    return "$_\\$prog.cmd" if (-f "$_\\$prog.cmd" && -x "$_\\$prog.cmd");
	} else {
	    return "$_/$prog" if (-x "$_/$prog" && !-d "$_/$prog");
	}
    }
    undef;
}
# REPO END

# REPO BEGIN
# REPO NAME file_name_is_absolute /home/e/eserte/work/srezic-repository 
# REPO MD5 89d0fdf16d11771f0f6e82c7d0ebf3a8

=head2 file_name_is_absolute($file)

=for category File

Return true, if supplied file name is absolute. This is only necessary
for older perls where File::Spec is not part of the system.

=cut

BEGIN {
    if (eval { require File::Spec; defined &File::Spec::file_name_is_absolute }) {
	*file_name_is_absolute = \&File::Spec::file_name_is_absolute;
    } else {
	*file_name_is_absolute = sub {
	    my $file = shift;
	    my $r;
	    if ($^O eq 'MSWin32') {
		$r = ($file =~ m;^([a-z]:(/|\\)|\\\\|//);i);
	    } else {
		$r = ($file =~ m|^/|);
	    }
	    $r;
	};
    }
}
# REPO END

# REPO BEGIN
# REPO NAME save_pwd /home/e/eserte/work/srezic-repository 
# REPO MD5 0f7791cf8e3b62744d7d5cfbd9ddcb07

=head2 save_pwd(sub { ... })

=for category File

Save the current directory and assure that outside the block the old
directory will still be valid.

=cut

sub save_pwd (&) {
    my $code = shift;
    require Cwd;
    my $pwd = Cwd::cwd();
    eval {
	$code->();
    };
    my $err = $@;
    chdir $pwd or die "Can't chdir back to $pwd: $!";
    die $err if $err;
}
# REPO END

1;

__END__
