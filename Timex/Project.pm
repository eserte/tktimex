# -*- perl -*-

package Project;

my $pool = [];

sub new {
    my($pkg, $label) = @_;
    my $self = {};
    $self->{'label'} = $label;
    $self->{'subprojects'} = [];
    $self->{'archived'} = 0;
    $self->{'times'} = [];
    bless $self, $pkg;
    $self->push_pool;
    $self;
}

sub push_pool {
    my $self = shift;
    push(@{$Project::pool}, $self);
}

sub pool {
    my($pkg, $pool) = @_;
    if (defined $pool) {
	$Project::pool = $pool;
    } else {
	$Project::pool;
    }
}

sub label {
    $_[0]->{'label'};
}

sub parent {
    undef;
}

sub subproject {
    my($self, $label) = @_;
    if (defined $label) {
	my $sub = Subproject->new($label);
	$sub->{'parent'} = $self;
	push(@{$self->{'subprojects'}}, $sub);
	$sub;
    } else {
	$self->{'subprojects'};
    }
}

sub level {
    0;
}

sub start_time {
    my($self, $time) = @_;
    $time = time unless $time;
    push(@{$self->{'times'}}, [$time]);
}

sub end_time {
    my($self, $time) = @_;
    $time = time unless $time;
    my @times = @{$self->{'times'}};
    $times[$#times]->[1] = $time;
}

sub sum_time {
    my($self, $since, $recursive) = @_;
    my $sum = 0;
    if ($recursive) {
	foreach (@{$self->subproject}) {
	    $sum += $_->sum_time($since, $recursive);
	}
    }
    my @times = @{$self->{'times'}};
    my $i = -1;
    foreach (@times) {
	my($from, $to) = ($_->[0], $_->[1]);
	$i++;
	if (defined $from) {
	    if (!defined $to) {
		if ($i != $#times) {
		    warn "No end time in $self";
		    next;
		} else {
		    $to = time;
		}
	    }
	    if ($since =~ /^\d+$/ && $to >= $since) {
		if ($from >= $since) {
		    $sum += $to - $from;
		} else {
		    $sum += $to - $since;
		}
	    }
	} else {
	    warn "No start time in $self";
	}
    }
    $sum;
}

sub archived {
    my($self, $flag) = @_;
    if (!defined $flag) {
	$self->{'archived'};
    } else {
	if ($flag) {
	    $self->{'archived'} = 1;
	} else {
	    $self->{'archived'} = 0;
	}
    }
}

######################################################################

package Subproject;
@Subproject::ISA = qw(Project);

sub parent {
    $_[0]->{'parent'};
}

sub level {
    my $self = shift;
    $self->parent->level + 1;
}

sub push_pool { }

######################################################################

1;
