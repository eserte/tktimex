# -*- perl -*-

=head1 NAME

Timex::Project - manage a list of projects

=head1 SYNOPSIS

    use Timex::Project;
    $root = new Timex::Project;
    $helloproject = $root->project('hello');
    $helloproject->start_time;
    $helloproject->end_time;

=head1 DESCRIPTION

B<Timex::Project> is a project manager, primarily for the programs timex
and tktimex. This module supports the following methods:

=cut

package Timex::Project;
use strict;
use vars qw($magic $emacsmode $pool);

$magic = '#PJ1';
$emacsmode = '-*- project -*-';

=head2 new

    $project = new Timex::Project $label

Constructs a new Timex::Project object with label $label.

=cut

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

sub pathname { # virtual pathname!
    my($self) = @_;
    my @path = $self->path;
    if (!defined $path[0] || $path[0] eq '') {
	shift @path;
    }
    join("/", @path);
}

sub rcsfile {
    my($self, $rcsfile) = @_;
    if (defined $rcsfile) {
	$self->{'rcsfile'} = $rcsfile;
	$self->modified(1);
    } else {
	$self->{'rcsfile'};
    }
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
	if (ref $label ne 'Timex::Project') {
	    $sub = Timex::Project->new($label);
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
    } elsif ($sorted_by =~ /^time$/i) {
	sort { $b->sum_time(0, undef, 1) <=> $a->sum_time(0, undef, 1) }
	       $self->subproject;
    } else {
	die "Unknown sort type: <$sorted_by>";
    }
}

sub _in_interval {
    my($myfrom, $myto, $from, $to) = @_;
    return undef if !defined $myfrom || !defined $myto;
    ((!defined $from || $myfrom >= $from) &&
     (!defined $to || $myfrom <= $to))    ||
    ((!defined $from || $myto >= $from) &&
     (!defined $to || $myto <= $to));
}

sub projects_by_interval {
    my($self, $from, $to) = @_;
    my @res;
    my $p;
    foreach $p ($self->subproject) {
	my $t;
	foreach $t (@{$p->{'times'}}) {
	    my($myfrom, $myto) = ($t->[0], $t->[1]);
	    if (_in_interval($myfrom, $myto, $from, $to)) {
		push(@res, $p);
		last;
	    }
	}
	push(@res, $p->projects_by_interval($from, $to));
    }
    @res;
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
    my @labels;
    push(@labels, $self->label);
    foreach (@{$self->subproject}) {
	push(@labels, $_->all_labels);
    }
    wantarray ? @labels : \@labels;
}

sub all_pathnames {
    my $self = shift;
    my @pathnames;
    push(@pathnames, $self->pathname);
    foreach (@{$self->subproject}) {
	push(@pathnames, $_->all_pathnames);
    }
    wantarray ? @pathnames : \@pathnames;
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

sub _min {
    my $min = shift;
    foreach (@_) {
	next if !defined $_;
	$min = $_ if $_ < $min;
    }
    $min;
}

=head2 sum_time

    $time = $project->sum_time($since, $until, $recursive)

Returns the time the given project accumulated since $since until $until.
If $until is undefined, returns the time until now. If $recursive
is true, recurse into subprojects of $project.

=cut

sub sum_time {
    my($self, $since, $until, $recursive) = @_;
    my $sum = 0;
    if ($recursive) {
	foreach (@{$self->subproject}) {
	    $sum += $_->sum_time($since, $until, $recursive);
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
	    my $to = _min($to, $until);
	    if ($since =~ /^\d+$/ && $to >= $since && $to >= $from) {
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
	$res .= "/rcsfile=" . $self->rcsfile . "\n" if $self->rcsfile;
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
	$@ = "Wrong magic!";
	warn $@;
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
	    $@ = 'Project does not begin with ">"';
	    warn $@;
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
		$self = new Timex::Project $label;
		$self->{'times'} = \@times;
		$self->{'archived'} = delete $attributes{'archived'};
		$self->{'rcsfile'}  = delete $attributes{'rcsfile'};
		warn "Unknown attributes: " . join(" ", %attributes)
		  if %attributes;
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
	    s/\r//g; # strip dos newlines
	    push(@data, $_);
	}
	close FILE;
	&interpret_data($self, \@data);
    }
}

=head2 is_project_file

    $r = Timex::Project->is_project_file($filename);

Returns TRUE if $filename is a project file.

=cut

sub is_project_file {
    shift;
    my $filename = shift;
    if (!open(F, $filename)) {
	return undef;
    } else {
	my $res = 1;
	chomp(my $magicline = <F>);
	if ($magicline !~ /^$magic/) {
	    $@ = "Wrong magic <$magicline>.";
	    $res = undef;
	}
	close F;
	return $res;
    }
}

sub load_old {
    my($self, $file) = @_;
    do $file;
    warn "Can't read $file: $@" if $@;
    foreach (@$pool) {
	if (ref $_ eq 'Timex::Project') {
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
	bless $_, 'Timex::Project';
	$_->rebless_subprojects;
    }
}

sub traverse {
    my($self, $sub, @args) = @_;
    &$sub($self, @args);
    foreach ($self->subproject) {
	$_->traverse($sub, @args);
    }
}

sub last_project {
    my $self = shift;
    my($last_project, $last_time) = @_;
    $last_time = 0;
    my $sub = sub {
	my($self, $last_project, $last_time) = @_;
	my $end_time_pair = $self->{'times'}[$#{$self->{'times'}}];
	my $end_time = $end_time_pair->[$#{$end_time_pair}];
	return if !defined $end_time;
	if ($$last_time < $end_time) {
	    $$last_project = $self;
	    $$last_time = $end_time;
	}
    };
    $self->traverse($sub, \$last_project, \$last_time);
    $last_project;
}

sub merge {
    my($self, $other) = @_;
    if (!$other->isa('Timex::Project')) {
	die "merge: arg must be Timex::Project!";
    }

    my %self_label;
    my $sub;
    foreach $sub ($self->subproject) {
	$self_label{$sub->label} = $sub;
    }

    my $modified = 0;

    my $other_sub;
    foreach $other_sub ($other->subproject) {
	if (exists $self_label{$other_sub->label}) {
	    my $sub = $self_label{$other_sub->label};
	    my $self_i = 0;
	    my $other_i = 0;
	    while($self_i <= $#{$sub->{'times'}} &&
		  $other_i <= $#{$other_sub->{'times'}}) {
		my $self_t  = $sub->{'times'}[$self_i];
		my $other_t = $other_sub->{'times'}[$other_i];
		if ($self_t->[0] < $other_t->[0]) {
		    $self_i++;
		} elsif ($self_t->[0] == $other_t->[0]) {
		    if ($self_t->[1] != $other_t->[1]) {
			warn "Warning: incompatible times for " .
			  $sub->label . ": " . $self_t->[1] . " != " .
			    $other_t->[1];
		    }
		    $self_i++;
		    $other_i++;
		} else { # $self_t > $other_t
		    splice @{$sub->{'times'}}, $self_i, 0, $other_t;
		    $self_i++;
		    $other_i++;
		    $modified++;
		}
	    }
	    if ($other_i <= $#{$other_sub->{'times'}}) {
		push(@{$sub->{'times'}},
		     @{$other_sub->{'times'}}[$other_i ..
					      $#{$other_sub->{'times'}}]);
		$modified += $#{$other_sub->{'times'}} - $other_i + 1;
	    }
	    $modified += $sub->merge($other_sub);
	} else {
	    $self->subproject($other_sub);
	    $modified++;
	}
    }

    if ($modified) {
	$self->modified(1);
    }

    $modified;
}

######################################################################

1;

