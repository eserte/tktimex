# -*- perl -*-

#
# $Id: Svn.pm,v 1.4 2003/01/22 00:34:48 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 2003 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

package Timex::Svn;

use strict;
use vars qw($VERSION);
$VERSION = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);

package Timex::Svn::File;
use vars qw(@ISA);
@ISA = qw(Timex::RcsFile);

my $tmpdir = "/tmp/timex-svn-file-$$"; # do not hardcode

sub parse_rcsfile {
    shift->parse_svnlog(@_);
}

sub parse_svnlog {
    my($self) = @_;

    $self->{Symbolic_Names} = []; # no symbolic names with subversion (yet)
    $self->{Revisions} = [];
    $self->{RCS_File} = "???";
    $self->{Working_File} = "???";

    $self->_open_log;
    scalar <RLOG>; # overread separator
    while(!eof(RLOG)) {
	chomp($_ = scalar <RLOG>);
	if (!/^rev\s+(\d+):\s*(.+?)\s*\|\s*(\d+)-(\d+)-(\d+)\s+(\d+):(\d+):(\d+).*?\s*\|\s*(\d+)\s+lines?/) {
	    die "Can't parse $_";
	}
	my($rev, $name, $Y, $M, $D, $h, $m, $s, $lines) =
	    ($1, $2, $3, $4, $5, $6, $7, $8, $9);
	scalar <RLOG>; # empty line;
	my $log = "";
	for (1..$lines) {
	    $log .= scalar <RLOG>;
	}
	scalar <RLOG>; # separator

	my $curr_revision = new Timex::Rcs::Revision;
	$curr_revision->{Log} = $log;
	$curr_revision->{Revision} = $rev;
	$curr_revision->{Date} =
	    sprintf "%04d/%02d/%02d %02d:%02d:%02d", $Y, $M, $D, $h, $m, $s;
	$curr_revision->{Author} = $name;
	push @{$self->{Revisions}}, $curr_revision;
    }
    close RLOG;

    # get more info
    if (defined $self->{File}) {
	open(INFO, "svn info $self->{File} |");
	while(<INFO>) {
	    chomp;
	    my($k,$v) = $_ =~ /^(.*?):\s*(.*)/;
	    next if !defined $k;
	    $k =~ s/\s+//g;
	    $self->{Info}{$k} = $v;
	}
	close INFO;
    }
}

sub _open_log {
    my $self = shift;
    my %log_args = @_;

    my $extra_args = "";
## XXX no svn support
#      if ($log_args{-from} and $log_args{-to}) {
#  	$extra_args .=
#  	    " -d'" . Timex::Rcs::Revision::unixtime2rcsdate($log_args{-from})
#  	           . "<"
#  		   . Timex::Rcs::Revision::unixtime2rcsdate($log_args{-to})
#  	           . "'";
#      }

    my $file = $self->_get_file;
    my $cmd = "svn log $extra_args $file|";
    open(RLOG, $cmd) or die "$cmd: $!";
    if (eof(RLOG)) {
	$self->_log_hack or die;
    }
}

sub _log_hack {
    my $self = shift;
    if (!eval { require XML::Simple }) {
	warn "_log_hack requires XML::Simple";
	return;
    }
    if ($self->{Files} && @{$self->{Files}} > 1) {
	warn "_log_hack works only with one file, not with @{$self->{Files}}";
	return;
    }
    require File::Basename;
    my $file = $self->_get_file;
    my $dir = File::Basename::dirname($file);
    my $base = File::Basename::basename($file);
    my $cmd = "svn --verbose --xml log $dir|";
    open(XMLLOG, "$cmd") or die "$cmd: $!";
    local $/ = undef;
    my $buf = <XMLLOG>;
    close XMLLOG;
    my $xs = XML::Simple->new(forcearray => 1);
    my $ref = $xs->XMLin($buf);
    my $end_rev;
    foreach my $logentry (@{ $ref->{logentry} }) {
	foreach my $path (@{ $logentry->{paths}->[0]->{path} }) {
  	    if ($path->{content} =~ m|/\Q$base\E$| && # XXX only approx!
  		$path->{action} eq 'D') {
		$end_rev = $logentry->{revision};
		last;
  	    }
	}
    }
    if (defined $end_rev) {
	my $cmd = "svn log -r 1:" . ($end_rev-1) . " $file|";
	open(RLOG, $cmd) or die "$cmd: $!";
	1;
    } else {
	warn "Can't found D entry for $file";
	0;
    }
}

sub _get_file {
    my $self = shift;
    my $file;
    if (exists $self->{Files}) {
	$file = join(" ", @{ $self->{Files} });
    } else {
	$file = $self->{File};
    }
    $file;
}

sub create_pseudo_revisions {
    my $self = shift;
    my @pseudo_revisions;
    $self->{Pseudo_Revisions} = \@pseudo_revisions;
}

sub co_revision {
    my($self, $revision) = @_;
    if (!$self->{Info}{Url}) {
	die "Url needed for co_revision";
    }
#      require File::Path;
#      require File::Basename;
#      my $dir  = File::Basename::dirname($self->{Info}{Url});
#      my $base = File::Basename::basename($self->{Info}{Url});
#      File::Path::rmtree([$tmpdir]);
#      File::Path::mkpath([$tmpdir], 0, 0700);
#      my $cmd = "svn co -N -r $revision " . $dir . " " . $tmpdir . " 2>&1 >/dev/null";
#      system $cmd;
#      if ($?) {
#  	die "Error while doing $cmd: $?";
#      }
#      open(F, "$tmpdir/$base") or die "Can't open $tmpdir/$base: $!";
#      local $/ = undef;
#      my $buf = <F>;
#      close F;

#      File::Path::rmtree([$tmpdir]);

    my $buf = `svn cat $self->{Info}{Url}`;
    $buf;
}

1;

__END__
