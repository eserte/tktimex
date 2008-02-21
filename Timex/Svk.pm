# -*- perl -*-

#
# $Id: Svk.pm,v 1.1 2008/02/21 22:51:20 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 2008 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

package Timex::Svk;

use strict;
use vars qw($VERSION);
$VERSION = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);

package Timex::Svk::File;
use vars qw(@ISA);
@ISA = qw(Timex::RcsFile);

sub parse_rcsfile {
    shift->parse_svklog(@_);
}

sub parse_svklog {
    my($self) = @_;

    $self->{Symbolic_Names} = []; # no symbolic names with svk (yet)
    $self->{Revisions} = [];
    $self->{RCS_File} = "???";
    $self->{Working_File} = "???";

    my $cmd = "svk log " . $self->_get_file;
    open RLOG, $cmd . " |"
	or die "Cannot execute $cmd: $!";
    scalar <RLOG>; # overread separator
    while(!eof(RLOG)) {
	my $l = $_;
	chomp($l = scalar <RLOG>);
	if ($l !~ /^r(\d+):\s*(.+?)\s*\|\s*(\d+)-(\d+)-(\d+)\s+(\d+):(\d+):(\d+)\s*([+-]?\d+)/) {
	    die "Can't parse $_";
	}
	my($rev, $name, $Y, $M, $D, $h, $m, $s, $tzoffset) =
	    ($1, $2, $3, $4, $5, $6, $7, $8, $9);
	scalar <RLOG>; # empty line;
	my $log = "";
	while(!eof(RLOG)) {
	    chomp(my $line = scalar <RLOG>);
	    if ($line =~ m{^------------------+$}) {
		last;
	    }
	    $log .= $line . "\n";
	}

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
	open(INFO, "svk info $self->{File} |");
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

sub _get_file {
    my $self = shift;
    my $file;
    if (exists $self->{Files}) {
	warn "XXX Support only for first file!!!";
	$file = $self->{Files}->[0];
    } else {
	$file = $self->{File};
    }
    $file;
}

#XXX?
sub create_pseudo_revisions {
    my $self = shift;
    my @pseudo_revisions;
    $self->{Pseudo_Revisions} = \@pseudo_revisions;
}

#XXX?
sub co_revision {
    my($self, $revision) = @_;
    if (!$self->{Info}{Url}) {
	die "Url needed for co_revision";
    }
    my $buf = `svn cat $self->{Info}{Url}`;
    $buf;
}

1;

__END__
