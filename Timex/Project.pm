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
use vars qw($magic $emacsmode $pool);

$magic = '#PJ1';
$emacsmode = '-*- project -*-';

sub new {
    my($pkg, $label) = @_;
    my $self = {};
    $self->{'label'} = $label;
    $self->{'subprojects'} = [];
    $self->{'archived'} = 0;
    $self->{'times'} = [];
    $self->{'parent'} = undef;
    $self->{'modified'} = 1;
    bless $self, $pkg;
    $self;
}

sub label {
    my($self, $label) = @_;
    if (defined $label) {
	$self->{'label'} = $label;
	$self->modified(1);
    } else {
	$self->{'label'};
    }
}

sub path {
    my($self) = @_;
    my @path;
    if (!defined $self->parent) {
	@path = ($self->label);
    } else {
	@path = ($self->parent->path, $self->label);
    }
    wantarray ? @path : \@path;
}

sub parent {
    my($self, $parent) = @_;
    if (defined $parent) {
	$self->{'parent'} = $parent;
	$self->modified(1);
    } else {
	$self->{'parent'};
    }
}

sub reparent {
    my($self, $newparent) = @_;
    my $oldparent = $self->parent;
    # don't become a child of a descended project :-)
    return if $self->is_descendent($newparent);
    return if !$oldparent;         # don't reparent root
    $oldparent->delete_subproject($self);
    $newparent->subproject($self);
}

sub delete_subproject {
    my($self, $subp) = @_;
    my @subprojects = @{$self->subproject};
    my @newsubprojects;
    foreach (@subprojects) {
	push(@newsubprojects, $_) unless $_ eq $subp;
    }
    $self->{'subprojects'} = \@newsubprojects;
}

sub delete_all {
    my($self) = @_;
    foreach ($self->subproject) {
	$self->delete_subproject($_);
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
	$self->modified(1);
	$sub;
    } else {
	wantarray ? @{$self->{'subprojects'}} : $self->{'subprojects'};
    }
}

sub sorted_subprojects {
    my($self, $sorted_by) = @_;
    if (!$sorted_by || $sorted_by =~ /^nothing$/i) {
	$self->subproject;
    } elsif ($sorted_by =~ /^name$/i) {
	sort { lc($a->label) cmp lc($b->label) } $self->subproject;
    } else {
	die "Unknown sort type: <$sorted_by>";
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

sub find_by_label {
    my($self, $label) = @_;
    return $self if $self->label eq $label;
    foreach (@{$self->subproject}) {
	my $r = $_->find_by_label($label);
	return $r if defined $r;
    }
    return undef;
}

sub is_descendent {
    my($self, $project) = @_;
    return 1 if $self eq $project;
    foreach (@{$self->subproject}) {
	my $r = $_->is_descendent($project);
	return 1 if $r;
    }
    0;
}

sub all_labels {
    my $self = shift;
    my $labels;
    push(@$labels, $self->label);
    foreach (@{$self->subproject}) {
	push(@$labels, @{$_->all_labels});
    }
    $labels;
}

sub start_time {
    my($self, $time) = @_;
    $time = time unless $time;
    push(@{$self->{'times'}}, [$time]);
    $self->modified(1);
}

sub end_time {
    my($self, $time) = @_;
    $time = time unless $time;
    my @times = @{$self->{'times'}};
    $times[$#times]->[1] = $time;
    $self->modified(1);
}

sub unend_time {
    my $self = shift;
    my @times = @{$self->{'times'}};
    pop(@{$times[$#times]});
    $self->modified(1);
}

=head2 sum_time

    $time = $project->sum_time($since, $recursive)

Returns the time the given project accumulated since $since. If $recursive
is true, recurse into subprojects of $project.

=cut

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

=head2 archived

    $archived = $project->archived

Returns true if the project or one of the parent projects are archived. 
Use $project->{'archived'} for the value of *this* project.

    $project->archived($archived)

Set the archived attribute (0 or 1) for this project.

=cut

sub archived {
    my($self, $flag) = @_;
    if (!defined $flag) {
	($self->{'archived'} || 
	 ($self->parent && $self->parent->archived)) ? 1 : 0;
    } else {
	$self->{'archived'} = ($flag ? 1 : 0);
	$self->modified(1);
    }
}

=head2 modified

    $modfied = $project->modified

Returns true if the root project is modified, that is, one of root's #'
subprojects are modified.

    $project->modified($modified)

Set the modified attribute (0 or 1) for the root project.

=cut

sub modified {
    my($self, $flag) = @_;
    if ($self->parent) {
	$self->parent->modified($flag);
    } else {
	if (defined $flag) {
	    $self->{'modified'} = ($flag ? 1 : 0);
	} else {
	    $self->{'modified'};
	}
    }
}

sub dump_data {
    my($self, $indent) = @_;
    my $res;
    if (!$indent) {
	$res = "$magic $emacsmode\n";
	$indent = 0; # because of $^W
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
	$@ = "Can't write to <$file>: $!";
	warn $@;
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
    
    if ($data->[$i] !~ /^$magic/) {
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

=head2 load

    $r = $project->load($filename)

Loads the project file $filename and returns true if the loading was
successfull. New data is merged to the existing project.

=cut

sub load {
    my($self, $file) = @_;
    my @data;
    if (!open(FILE, $file)) {
	$@ = "Can't read <$file>: $!";
	warn $@;
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

