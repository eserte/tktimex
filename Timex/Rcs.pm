# -*- perl -*-

#
# $Id: Rcs.pm,v 1.14 2003/01/22 21:17:23 eserte Exp $
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

# constructor for "current" pseudo version for file $file
sub current {
    my($pkg, $file) = @_;
    my $date;
    my(@s) = stat($file);
    if (@s) {
	my(@l) = localtime $s[9]; # mtime
	$date = sprintf "%04d/%02d/%02d %02d:%02d:%02d",
	                $l[5]+1900, $l[4]+1, @l[3,2,1,0];
    }
    $pkg->new(Revision => 'current',
	      Date     => $date,
	     );
}

sub revision { $_[0]->{Revision} }
sub version  { $_[0]->revision } # VCS.pm compatibility
sub date     { $_[0]->{Date} }
sub unixtime {
    rcsdate2unixtime($_[0]->date);
}
# static method
sub rcsdate2unixtime {
    my $date = shift;
    if ($date =~ m|^(\d+)/(\d+)/(\d+)\s+(\d+):(\d+):(\d+)$|) {
	my $ret;
	if (eval {
	    require Time::Local;
	    $ret = Time::Local::timelocal($6, $5, $4, $3, $2-1, $1-1900);
	    1;
	}) {
	    return $ret;
	}

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
# static method
sub unixtime2rcsdate {
    my $unixtime = shift;
    my @l = localtime $unixtime;
    sprintf "%04d-%02d-%02d %02d:%02d:%02d", $l[5]+1900, $l[4]+1, $l[3],
                                             $l[2], $l[1], $l[0];
}
sub author   { $_[0]->{Author} }
sub desc     { $_[0]->{Desc} }
sub log      { shift->{Log} }

######################################################################

package Timex::RcsFile;
use strict;
use File::Basename;

my $delim_regex = "^----------------------------\$";
my $file_delim_regex = "^=============================================================================\$";

sub new {
    my($pkg, $file) = @_;
    my($base, $dir) = fileparse($file);
    my $self = {File     => $file,
		Dirname  => $dir,
		Basename => $base,
	       };
    bless $self, $pkg;
    $self->_get_vcs_type;
    $self->parse_rcsfile;
    $self;
}

# RLOG is opened ...
sub _open_log {
    my $self = shift;
    my %log_args = @_;

    my $extra_args = "";
    if ($log_args{-from} and $log_args{-to}) {
	$extra_args .=
	    " -d'" . Timex::Rcs::Revision::unixtime2rcsdate($log_args{-from})
	           . "<"
		   . Timex::Rcs::Revision::unixtime2rcsdate($log_args{-to})
	           . "'";
    }

    my $file;
    if (exists $self->{Files}) {
	$file = join(" ", @{ $self->{Files} });
    } else {
	$file = $self->{File};
    }
    my $cmd;
    if ($self->{VCS_Type} eq 'CVS') {
	$cmd = "cvs log $extra_args $file|";
    } else {
	$cmd = "rlog $extra_args $file|";
    }
    open(RLOG, $cmd) or die "$cmd: $!";
}

sub parse_rcsfile {
    my $self = shift;
    $self->{Symbolic_Names} = [];
    $self->{Revisions} = [];
    my $stage    = 'header';
    my $substage = '';
    my $curr_revision = new Timex::Rcs::Revision;
    $self->_open_log;
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
		    # Symbolic_Names: array of [Symbolic, Revision] items
		    # XXX create also (or only?) hashref
		    push @{$self->{Symbolic_Names}}, [$1, $2];
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
	    if (/$delim_regex/ || /$file_delim_regex/) {
		if (keys %$curr_revision) { # non-empty
		    push @{$self->{Revisions}}, $curr_revision;
		}
		$curr_revision = new Timex::Rcs::Revision;
		$substage = '';
		if (/$file_delim_regex/) {
		    $stage = 'header';
		}
	    } elsif ($substage eq 'log') {
		if (!defined $curr_revision->{Log}) {
		    $curr_revision->{Log} = "";
		}
		$curr_revision->{Log} .= $_ . "\n";
	    } elsif ($substage eq 'desc') {
		$curr_revision->{Desc} .= $_ . "\n";
	    } elsif (/^revision\s+(\S+)/) {
		$curr_revision->{Revision} .= $1;
	    } elsif (/^date:\s+([^;]+);\s+author:\s+([^;]+)/) {
		$curr_revision->{Date} = $1;
		$curr_revision->{Author} = $2;
		$substage = 'log';
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
# In scalar context, return the first symbolic name for a revision.
# In array context, return all symbolic names for a revision.
sub symbolic_name  {
    my($self, $rev_o) = @_;
    my $rev = $rev_o->revision;
    my @res;
    foreach ($self->symbolic_names) {
	if ($_->[1] eq $rev) {
	     return $_->[0] if (!wantarray);
	     push @res, $_->[0];
	}
    }
    @res;
}
sub revisions      { @{$_[0]->{Revisions}} }
sub versions       { $_[0]->revisions } # VCS.pm compatibility

sub get_log_entries {
    my($self, $from_date, $to_date) = @_;
    $self->_open_log(-from => $from_date, -to => $to_date);
    local $/ = undef;
    my $log_entries = <RLOG>;
    close RLOG;
    $log_entries;
}

sub _get_vcs_type {
    my $self = shift;
    my $dir = $self->{Dirname};

    my $rcs_file = $self->{Basename} . ",v";
    if (-f "$dir/RCS/$rcs_file" ||
	-f "$dir/$rcs_file") {
	return $self->{VCS_Type} = "RCS";
    }
    if (-d "$dir/CVS") {
	return $self->{VCS_Type} = "CVS";
    }
    if (-d "$dir/.svn") {
	$self->{VCS_Type} = "SVN";
	require Timex::Svn;
	bless $self, 'Timex::Svn::File'; # re-bless hack
	return $self->{VCS_Type};
    }

    # fallback
    $self->{VCS_Type} = "RCS";
}

######################################################################

package Timex::RcsDir;
use base qw(Timex::RcsFile);
use strict;
use File::Find;

sub new {
    my($pkg, $dir, %args) = @_;

    require File::Spec;
    # make absolute:
    if (!File::Spec->file_name_is_absolute($dir)) {
	require Cwd;
	$dir = File::Spec->catdir(Cwd::cwd(), $dir);
    }

    my $self = {Dirname   => $dir,
		Recursive => $args{-recursive},
		Fast      => $args{-fast},
	       };
    bless $self, $pkg;

    $self->{Files} = [];

    my $wanted_rcs = sub {
  	if (!$self->{Recursive} && -d $_ && $_ !~ /^(\.|rcs)$/i) {
  	    $File::Find::prune = 1;
  	}
	if (-f $_ and $File::Find::name =~ m|^(.*)/RCS/(.*),v$|) {
	    my $orig_file = "$1/$2";
	    push @{ $self->{Files} }, $orig_file if (-f $orig_file);
	}
    };

    my $wanted_cvs = sub {
  	if (!$self->{Recursive} && -d $_ && $_ !~ /^(\.|cvs)$/i) {
  	    $File::Find::prune = 1;
  	}
	if (-f $_ and $File::Find::name =~ m|^(.*)/CVS/Entries$|) {
	    my $cvsdir = $1;
	    if (!open(ENTRIES, $_)) {
		warn "Can't open $File::Find::name: $!";
	    } else {
		while(<ENTRIES>) {
		    chomp;
		    if (m|^/([^/]+)|) {
			my $orig_file = "$cvsdir/$1";
			push @{ $self->{Files} }, $orig_file
			    if (-f $orig_file);
		    }
		}
		close ENTRIES;
	    }
	}
    };

    $self->_get_vcs_type;
    if ($self->{VCS_Type} eq 'CVS') {
	find($wanted_cvs, $self->{Dirname});
    } elsif ($self->{VCS_Type} eq 'SVN') {
	require Timex::Svn;
	$self->{Files} = [$self->{Dirname}];
	bless $self, 'Timex::Svn::File'; # re-bless hack
    } else {
	find($wanted_rcs, $self->{Dirname});
    }

    unless ($self->{Fast}) {
	$self->parse_rcsfile;
	$self->create_pseudo_revisions;
    }

    $self;
}

# for multiple files, it is better to use symbolic names instead of revisions
# XXX this probably needs a lot of work...
sub create_pseudo_revisions {
    my $self = shift;
    my @pseudo_revisions;
    my %already_seen;
    foreach my $rev ($self->Timex::RcsFile::revisions) {
	my $sym_name = $self->Timex::RcsFile::symbolic_name($rev);
	if (defined $sym_name && !$already_seen{$sym_name}) {
	    my $pseudo_rev = new Timex::Rcs::Revision;
	    $pseudo_rev->{Desc}     = $rev->{Desc};
	    $pseudo_rev->{Revision} = $sym_name;
	    $pseudo_rev->{Date}     = $rev->{Date};
	    $pseudo_rev->{Author}   = $rev->{Author};
	    push @pseudo_revisions, $pseudo_rev;
	    $already_seen{$sym_name}++;
	}
    }
    $self->{Pseudo_Revisions} = \@pseudo_revisions;
}

sub revisions     { @{ $_[0]->{Pseudo_Revisions} } }
sub symbolic_name { undef }
sub files         { @{ $_[0]->{Files} } }

######################################################################

package Timex::Rcs;
use strict;

sub new {
    my($class, $file) = @_;
    if (-d $file) {
	new Timex::RcsDir $file;
    } else {
	new Timex::RcsFile $file;
    }
}

######################################################################

return 1 if caller();

package main;

require FindBin;
push @INC, "$FindBin::RealBin/..";

my $f = shift or die "Please supply RCS or CVS file";
my $o = new Timex::Rcs $f;
if (1) {
    foreach my $rev ($o->revisions) {
	print $rev->revision.": ".localtime($rev->unixtime)."\n";
    }
    require Data::Dumper;
    print Data::Dumper->Dumpxs([$o], ['o']),"\n";
} else {
    warn $o->co_revision(($o->revisions)[0]->revision);
}
