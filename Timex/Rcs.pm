# -*- perl -*-

#
# $Id: Rcs.pm,v 1.3 2000/07/06 00:48:09 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 1998 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

BEGIN {
    die "Timex::Rcs does not work with DOS/Windows"
      if $^O =~ /(mswin|dos)i/;
}


package Timex::Rcs::Revision;

sub new {
    my($pkg, %args) = @_;
    my $self = {%args};
    bless $self, $pkg;
}

sub revision { $_[0]->{Revision} }
sub date     { $_[0]->{Date} }
sub unixtime {
    my $date = $_[0]->date;
    if ($date =~ m|^(\d+)/(\d+)/(\d+)\s+(\d+):(\d+):(\d+)$|) {
	require POSIX;
	# XXX unterschiedliche Sommerzeit????
	my $time = POSIX::mktime($6, $5, $4, $3, $2-1, $1-1900);
	my $t1 = POSIX::mktime(localtime($time));
	my $t2 = POSIX::mktime(gmtime($time));
	$time + $t1 - $t2;
    } else {
	die "Can't parse date: $date";
    }
}
sub author   { $_[0]->{Author} }
sub desc     { $_[0]->{Desc} }

package Timex::Rcs;
use strict;
use File::Basename;

my $delim_regex = "^----------------------------\$";

sub new {
    my($pkg, $file) = @_;
    my($base, $dir) = fileparse($file);
    my $self = {File     => $file,
		Dirname  => $dir,
		Basename => $base,
	       };
    bless $self, $pkg;
    $self->parse_rcsfile;
    $self;
}

sub parse_rcsfile {
    my $self = shift;
    my $file = $self->{File};
    $self->{Symbolic_Names} = [];
    $self->{Revisions} = [];
    my $stage    = 'header';
    my $substage = '';
    my $curr_revision = new Timex::Rcs::Revision;
    if (-d dirname($file) . "/CVS" and
	!-d dirname($file) . "/RCS") {
	# try CVS instead of RCS
	open(RLOG, "cvs log $file|") or die "$file: $!";
    } else {
	open(RLOG, "rlog $file|") or die "$file: $!";
    }
    while(<RLOG>) {
	chomp;
	if ($stage eq 'header') {
	    if (/$delim_regex/) {
		if ($stage eq 'header') {
		    $stage = 'desc';
		} else {
		    last;
		}
	    } elsif ($substage eq 'symnames') {
		if (/^\t(.*):\s*(.*)$/) {
		    push(@{$self->{Symbolic_Names}}, [$1, $2]);
		} else {
		    $substage = '';
		    redo;
		}
	    } elsif (/^RCS file:\s+(.*)$/) {
		$self->{RCS_File} = $1;
	    } elsif (/^Working file:\s+(.*)$/) {
		$self->{Working_File} = $1;
	    } elsif (/^symbolic names:$/) {
		$substage = 'symnames';
	    }
	} elsif ($stage eq 'desc') {
	    if (/$delim_regex/) {
		push(@{$self->{Revisions}}, $curr_revision);
		$curr_revision = new Timex::Rcs::Revision;
		$substage = '';
	    } elsif ($substage eq 'desc') {
		$curr_revision->{Desc} .= $_ . "\n";
	    } elsif (/^revision\s+(\S+)/) {
		$curr_revision->{Revision} .= $1;
	    } elsif (/^date:\s+([^;]+);\s+author:\s+([^;]+)/) {
		$curr_revision->{Date} = $1;
		$curr_revision->{Author} = $2;
	    } else {
		$substage = 'desc';
		redo;
	    }
	}
    }
    close RLOG;
}

sub rcs_file       { $_[0]->{RCS_File} }
sub working_file   { $_[0]->{Working_File} }
sub symbolic_names { @{$_[0]->{Symbolic_Names}} }
sub symbolic_name  {
    my($self, $rev_o) = @_;
    my $rev = $rev_o->revision;
    foreach ($self->symbolic_names) {
	if ($_->[1] eq $rev) {
	    return $_->[0];
	}
    }
}
sub revisions      { @{$_[0]->{Revisions}} }

return 1 if caller();

package main;

my $f = shift or die;
my $o = new Timex::Rcs $f;
foreach my $rev ($o->revisions) {
    print $rev->revision.": ".localtime($rev->unixtime)."\n";
}
require Data::Dumper;
print Data::Dumper->Dumpxs([$o], ['o']),"\n";
