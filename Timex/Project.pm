# -*- perl -*-

=head1 NAME

Project - manage a list of projects

=head1 SYNOPSIS

    use Project;
    $root = new Project;
    $helloproject = $root->project('hello');
    $helloproject->start_time;
    $helloproject->end_time;

=cut

package Project;
use strict;
use vars qw($magic $pool);

$magic = '#PJ1';

sub new {
    my($pkg, $label) = @_;
    my $self = {};
    $self->{'label'} = $label;
    $self->{'subprojects'} = [];
    $self->{'archived'} = 0;
    $self->{'times'} = [];
    $self->{'parent'} = undef;
    bless $self, $pkg;
}

sub label {
    my($self, $label) = @_;
    if (defined $label) {
	$self->{'label'} = $label;
    } else {
	$self->{'label'};
    }
}

sub parent {
    my($self, $parent) = @_;
    if (defined $parent) {
	$self->{'parent'} = $parent;
    } else {
	$self->{'parent'};
    }
}

sub subproject {
    my($self, $label) = @_;
    if (defined $label) {
	my $sub;
	if (ref $label ne 'Project') {
	    $sub = Project->new($label);
	} else {
	    $sub = $label;
	}
	$sub->parent($self);
	push(@{$self->{'subprojects'}}, $sub);
	$sub;
    } else {
	$self->{'subprojects'};
    }
}

sub level {
    my $self = shift;
    if (!defined $self->{'parent'}) {
	0;
    } else {
	$self->{'parent'}->level + 1;
    }
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

sub unend_time {
    my $self = shift;
    my @times = @{$self->{'times'}};
    pop(@{$times[$#times]});
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

sub dump_data {
    my($self, $indent) = @_;
    my $res;
    if (!$indent) {
	$res = "$magic\n";
    } else {
	$res .= (">" x $indent) . "$self->{'label'}\n";
	$res .= "/archived=$self->{'archived'}\n";
	my $time;
	foreach $time (@{$self->{'times'}}) {
	    $res .= "|" . $time->[0];
	    if (defined $time->[1]) {
		$res .= "-" . $time->[1];
	    }
	    $res .= "\n";
	}
    }
    my $subproject;
    foreach $subproject (@{$self->{'subprojects'}}) {
	$res .= $subproject->dump_data($indent+1);
    }
    $res;
}

sub save {
    my($self, $file) = @_;
    if (!open(FILE, ">$file")) {
	warn "Can't write to $file";
	undef;
    } else {
	print FILE $self->dump_data;
	close FILE;
	1;
    }
}

sub interpret_data {
    my($self, $data) = @_;
    my $i = $[;
    
    if ($data->[$i] ne $magic) {
	warn "Wrong magic!";
	return undef;
    }
    $i++;

    $i = $self->interpret_data_project($data, $i);
    return undef if !defined $i;

    1;
}

sub interpret_data_project {
    my($parent, $data, $i) = @_;
    my($indent, $self);
    while(defined $data->[$i]) {
	if ($data->[$i] !~ /^>+/) {
	    warn 'Project does not begin with ">"';
	    return undef;
	}
	my $label = $';
	my $newindent = length($&);
	if (!defined $indent) {
	    $indent = $newindent;
	} else {
	    if ($newindent < $indent) { # Rekursion verlassen
		return $i;
	    } elsif ($newindent > $indent) { # Subprojekte bearbeiten
		$i = $self->interpret_data_project($data, $i);
	    } else { # Projekt bearbeiten
		$i++;
		my(%attributes, @times, @comment);
		while(defined $data->[$i]) {
		    $data->[$i] =~ /^./;
		    my $first = $&;
		    my $rest = $';
		    last if $first eq '>';
		    if ($first eq '|') {
			my(@interval) = split(/-/, $rest);
			warn "Interval must be two values" if $#interval != 1;
			push(@times, [@interval]);
		    } elsif ($first eq '/') {
			my(@attrpair) = split(/=/, $rest);
			$attributes{$attrpair[0]} = $attrpair[1];
		    } elsif ($first eq '#') {
			push(@comment, $rest);
		    } else {
			warn "Unknown command $first";
		    }
		    $i++;
		}
#		print STDERR (">" x $indent) . $label, "\n";
		$self = new Project($label);
		$self->{'times'} = \@times;
		$self->{'archived'} = $attributes{'archived'};
		$parent->subproject($self);
	    }
	}
    }

    $i;
}

sub load {
    my($self, $file) = @_;
    my @data;
    if (!open(FILE, $file)) {
	warn "Can't read $file";
	undef;
    } else {
	while(<FILE>) {
	    chomp;
	    push(@data, $_);
	}
	close FILE;
	&interpret_data($self, \@data);
    }
}

sub load_old {
    my($self, $file) = @_;
    do $file;
    warn "Can't read $file: $@" if $@;
    foreach (@$pool) {
	if (ref $_ eq 'Project') {
	    $self->subproject($_);
	    $_->rebless_subprojects;
	} else {
	    warn "Unknown object $_";
	}
    }
}

sub rebless_subprojects {
    my $self = shift;
    foreach (@{$self->subproject}) {
	bless $_, 'Project';
	$_->rebless_subprojects;
    }
}

######################################################################

1;

