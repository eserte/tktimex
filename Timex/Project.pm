# -*- perl -*-

package Project;

my $pool = [];
my $magic = '#PS1';

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
    my $pool = $Project::pool;
    my $res = "$magic\n";
    foreach (@$pool) {
	if ($_->isa('Project')) {
	    $res .= &dump_data_project($_, 1);
	}
    }
    $res;
}

sub dump_data_project {
    my($self, $indent) = @_;
    my $res;
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
    my $subproject;
    foreach $subproject (@{$self->{'subprojects'}}) {
	$res .= &dump_data_project($subproject, $indent+1);
    }
    $res;
}

sub save {
    my($file) = @_;
    if (!open(FILE, ">$file")) {
	warn "Can't write to $file";
	undef;
    } else {
	print FILE &dump_data();
	close FILE;
	1;
    }
}

sub interpret_data {
    my $data = shift;
    my $i = $[;
    
    if ($data->[$i] ne $magic) {
	warn "Wrong magic!";
	return undef;
    }
    $i++;

    while ($i <= $#{$data}) {
	($i) = &interpret_data_project($data, 1, $i);
	return undef if !defined $i;
    }

    1;
}

sub interpret_data_project {
    my($data, $indent, $i) = @_;
    my($label, %attributes, @times, @comment, @subprojects, $subproject);
    if ($data->[$i] !~ /^>+/) {
	warn 'Project does not begin with ">"';
	return undef;
    }
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
    }

    $i;
}

sub load {
    my($file) = @_;
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
	&interpret_data(\@data);
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
