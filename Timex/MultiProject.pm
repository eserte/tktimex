# -*- perl -*-

#
# $Id: MultiProject.pm,v 1.2 2001/04/04 21:50:13 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 2001 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

=head1 NAME

Timex::MultiProject - manage a number of project files

=head1 SYNOPSIS

    use Timex::MultiProject;
    $root = new Timex::MultiProject $master_file, $backup1_file ...;

=cut

package Timex::MultiProject;

use strict;
use vars qw($AUTOLOAD);

use Timex::Project;
use File::Basename;

sub new {
    my($pkg, @files) = @_;
    my $self = {};
    $self->{Master} = shift @files;
    $self->{Backup} = \@files;
    bless $self, $pkg;
}

sub master_project {
    my $self = shift;
    if (@_) {
	$self->{MasterProject} = shift;
    } else {
	$self->{MasterProject};
    }
}

sub master {
    my $self = shift;
    if (@_) {
	$self->{Master} = shift;
    } else {
	$self->{Master};
    }
}

sub backups {
    my $self = shift;
    if (@_) {
	$self->{Backups} = [@_];
    } else {
	@{ $self->{Backups} };
    }
}

sub add_backups {
    my $self = shift;
    push @{ $self->{Backups} }, @_;
}

sub load {
    my($self, $dummy, %args) = @_;

    my $master_project;
    foreach my $file ($self->master, $self->backups) {
	if (Timex::Project->is_project_file($file)) {
	    my $project = Timex::Project->new;
	    $project->load($file);
	    if (!$master_project) {
		$master_project = $project;
	    } else {
		$master_project->merge($project);
	    }
	}
    }

    if (!$master_project) {
	# empty project
	$master_project = Timex::Project->new;
    }

    $self->master_project($master_project);

    !!$master_project;
}

sub save {
    my($self, $dummy, %args) = @_;

    my $master_project = $self->master_project;
    die "No master project found" if !$master_project;

    foreach my $file ($self->master, $self->backups) {
	my $dir = dirname $file;
	my $writable;

	if (-f $file) {
	    if (-w $file) {
		if (Timex::Project->is_project_file($file) || -z $file) {
		    $writable = 1;
		}
	    } else {
		$writable = 0;
	    }
	}

	if (!defined $writable && -d $dir && -w $dir) {
	    $writable = 1;
	}

	if ($writable) {
	    $master_project->save($file, %args);
	}
    }
}

sub merge { die "No merging with " . __PACKAGE__ }

sub AUTOLOAD {
    my $base = (split /::/, $AUTOLOAD)[-1];
    my $cmd = <<EOF;
sub $AUTOLOAD { shift->{MasterProject}->$base(\@_) }
EOF
    #warn $cmd;
    eval $cmd;
    die $@ if $@;
    goto &$AUTOLOAD;
}

1;

__END__
