# -*- perl -*-

#
# $Id: Hooks.pm,v 1.1 2005/10/10 19:11:20 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 2000,2005 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

package Hooks;

use strict;
use vars qw(%pool $VERBOSE $VERSION);

$VERSION = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);

sub get_hooks {
    my $label = shift;
    $pool{$label};
}

sub new {
    my($class, $label) = @_;
    my $self = { Hooks => {},
		 Seq   => 0,
		 Order => [],
	       };
    bless $self, $class;
    if (defined $label) {
	$pool{$label} = $self; # XXX weakref!
	$self->{Label} = $label;
    }

    $self;
}

# XXX replace any hooks with same label!
sub add {
    my($self, $code, $label) = @_;
    my $hook_def = { Code  => $code,
		     Label => $label,
		     Seq   => $self->{Seq}++,
		   };
    if ($VERBOSE) {
	warn "Add hook $label to $self->{Label}\n";
    }
    $self->{Hooks}{$label} = $hook_def;
    $self->_create_list;
}

sub del {
    my($self, $label) = @_;
    if ($VERBOSE) {
	warn "Delete hook $label from $self->{Label}\n";
    }
    delete $self->{Hooks}{$label};
    $self->_create_list;
}

sub _create_list {
    my $self = shift;
    my $hooks = $self->{Hooks};
    $self->{Order} = [map { $hooks->{$_} }
		      sort { $hooks->{$a}{Seq} <=> $hooks->{$b}{Seq} }
		      keys %$hooks ];
}

sub execute {
    my $self = shift;
    $self->execute_except([], @_);
}

sub execute_except {
    my($self, $except_ref, @args) = @_;
    my %except = (ref $except_ref eq 'ARRAY'
		  ? map { ($_=>1) } @$except_ref
		  : ($except_ref => 1));
    my %ret;
    foreach my $hook_def (@{ $self->{Order} }) {
	my $label = $hook_def->{Label};
	if ($except{$label}) {
	    warn "Skip hook $label of $self->{Label}\n"
		if $VERBOSE;
	    next;
	}
	if ($VERBOSE) {
	    warn "Execute hook $label of $self->{Label}\n";
	}
	$ret{$label} = $hook_def->{Code}->(@args);
    }
    +{ReturnCodes => \%ret};
}

sub DESTROY {
    my $self = shift;
    if (defined $self->{Label}) {
	delete $pool{$self->{Label}};
    }
}

1;

__END__
