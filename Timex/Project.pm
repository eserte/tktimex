# -*- perl -*-
# $Id: Project.pm,v 3.51 2005/04/28 22:10:02 eserte Exp $
#

=head1 NAME

Timex::Project - manage a list of projects

=head1 SYNOPSIS

    use Timex::Project;
    $root = new Timex::Project;
    $helloproject = $root->project('hello');
    $helloproject->start_time;
    $helloproject->end_time;

=head1 DESCRIPTION

B<Timex::Project> is a project manager, primarily for the programs ctimex
and tktimex. This module supports the following methods:

=cut

package Timex::Project;
use strict;
use vars qw($VERSION $magic $magic_template $emacsmode $pool @project_attributes);

$VERSION = sprintf("%d.%02d", q$Revision: 3.51 $ =~ /(\d+)\.(\d+)/);

$magic = '#PJ1';
$magic_template = '#PJT';
$emacsmode = '-*- project -*-';
@project_attributes = qw/archived rate rcsfile domain id notimes closed icon jobnumber/;

##XXX use some day?
#use constant TIMES_SINCE      => 0;
#use constant TIMES_UNTIL      => 1;
#use constant TIMES_ANNOTATION => 2;

sub Timex_Project_API () { 1 }

=head2 new

    $project = new Timex::Project $label

Construct a new Timex::Project object with label $label.

=cut

sub new {
    my($pkg, $label) = @_;
    my $self = {};

    $self->{'label'} = $label;
    $self->{'subprojects'} = [];
    $self->{'archived'} = 0;
    $self->{'cached_time'} = {};
    $self->{'times'} = [];
    $self->{'parent'} = undef;
    $self->{'id'} = 0;
    $self->{'max_id'} = 0;
    $self->{'modified'} = 1;
    $self->{'separator'} = "/";
    $self->{'current'} = undef;
    $self->{'rate'} = undef;

    $pkg = ref $pkg if (ref $pkg);
    bless $self, $pkg;
}

=head2 clone

    $new_project = clone Timex::Project $old_project
    $new_project = $old_project->clone

Clone a new Timex::Project object from an old one.

=cut

sub clone {
    my $pkg = shift;
    my $orig_project;
    if (ref $pkg and $pkg->isa('Timex::Project')) {
	$orig_project = $pkg;
	$pkg = ref $orig_project;
    } else {
	$orig_project = shift;
    }

    require Data::Dumper;
    my $self;
    eval {
	my $dd = new Data::Dumper([$orig_project], ['self']);
	$dd->Indent(0);
	$dd->Purity(1);
	my $evals = $dd->Dumpxs;
	eval $evals;
    };
    warn $@ if $@;
    bless $self, $pkg;
    $self->rebless_subprojects($pkg);
    $self;
}

sub equal {
    my($self, $p2) = @_;
    $self->pathname eq $p2->pathname;
}

=head2 concat

    $project = concat Timex::Project [-flat => 1,] $proj1, $proj2 ...

Concats the specified projects and create a new one. The concatenated
projects are not cloned.

If -flat is set to a true value, then projects are not seen as
complete project hierarchies (i.e. root element is not a real project).

=cut

sub concat {
    my $class = shift;

    my %args;
    while (@_ && $_[0] =~ /^-/) {
	my $key = shift;
	$args{$key} = shift;
    }
    my @p = @_;

    my $project = $class->new;
    my %seen;
    foreach my $p (@p) {
	if ($args{-flat}) {
	    my $path = $p->pathname;
	    if ($seen{$path}) {
		warn "There is already a project with path $path";
	    } else {
		$project->subproject($p);
		$seen{$path}++;
	    }
	} else {
	    foreach my $subp ($p->subproject) {
		my $path = $subp->pathname;
		if ($seen{$path}) {
		    warn "There is already a project with path $path";
		} else {
		    $project->subproject($subp);
		    $seen{$path}++;
		}
	    }
	}
    }
    $project;
}

=head2 shuffle

    $new_project = $project->shuffle($in => $out);

Shuffle the projects in level $in to level $out. The special level
"leaf" can be used to shuffle to the leaf. Note: only $in == 1 is
implemented yet. Top level is level == 1.

=cut

sub shuffle {
    my($project, $in_level, $out_level) = @_;
    my $class = ref $project;
    my $new_project = $class->new;

    my @sub = $project->all_subprojects;
#XXXXXXXXXXXXX
    my @tops;
    foreach my $sp (@sub) {
	if ($sp->level == $in_level) {
	    push @tops, $sp;
	}
    }
    foreach my $sp (@sub) {
	my $level = $sp->level;
	if ($level == $in_level) {
#XXXXXXXXXXXXX
	}
    }

    $new_project;
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
    my($self, $separator) = @_;
    $separator = $self->separator if (!defined $separator);
    my @path = $self->path;
    if (!defined $path[0] || $path[0] eq '') {
	shift @path;
    }
    join($separator, @path);
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

sub closed {
    my($self, $closed) = @_;
    if (defined $closed) {
	$self->{'closed'} = $closed;
	$self->modified(1);
    } else {
	$self->{'closed'};
    }
}

=head2 icon

    $icon = $project->icon;
    $project->icon($icon);

Get or set icon for project.

=cut

sub icon {
    my($self, $icon) = @_;
    if (defined $icon) {
	$self->{'icon'} = $icon;
	$self->modified(1);
    } else {
	$self->{'icon'};
    }
}

=head2 jobnumber

    $jobnumber = $project->jobnumber;
    $project->jobnumber($jobnumber);

Get or set jobnumber for project.

=cut

sub jobnumber {
    my($self, $jobnumber) = @_;
    if (defined $jobnumber) {
	$self->{'jobnumber'} = $jobnumber;
	$self->modified(1);
    } else {
	$self->{'jobnumber'};
    }
}

=head2 jobnumber_from_parent

    $jobnumber = $project->jobnumber_from_parent;

Get jobnumber for this project, either from the project itself or from
any of the parents. Return undef if no jobnumber could be found.

=cut

sub jobnumber_from_parent {
    my($self) = @_;
    my $jobnumber = $self->{'jobnumber'};
    return $jobnumber if defined $jobnumber && $jobnumber ne "";
    my $parent = $self->parent;
    return undef if !defined $parent;
    $self->parent->jobnumber_from_parent;
}


=head2 note

    @notes = $project->note;

Get notes for project.

=cut

sub note {
    my($self, @note_lines) = @_;
    if ($self->{'note'}) {
	@{$self->{'note'}};
    } else {
	();
    }
}

=head2 set_note

    $project->note("First note", "Second note");
    $project->note(["First note", "Second note"]);

=cut

sub set_note {
    my($self, @note_lines) = @_;
    if (@note_lines == 0) {
	undef $self->{'note'};
    } else {
	if (ref $note_lines[0] eq 'ARRAY') {
	    @note_lines = @{$note_lines[0]};
	}
	foreach (@note_lines) {
	    s/[\r\n]/_/g;
	}
	$self->{'note'} = [@note_lines];
	$self->modified(1);
    }
}

=head2 has_note

    $project->has_note

Return, if $project has a note attached.

=cut

sub has_note {
    my $self = shift;
    $self->{'note'} and
    ref $self->{'note'} eq 'ARRAY' and
    scalar @{ $self->{'note'} };
}

=head2 last_times

    $time_ref = $project->last_times;

Return an array reference to the last activity of the project, or undef if
there was no activity at all.

=cut

sub last_times {
    my $self = shift;
    return if !@{$self->{'times'}};
    return $self->{'times'}[$#{$self->{'times'}}];
}

=head2 last_time_subprojects

    $time_ref = $project->last_time_subprojects;

Return the time of the last activity of all subprojects, or undef if
there was no activity at all. Note that the method is spelled "time"
instead of "times".

=cut

sub last_time_subprojects {
    my($self, $last) = @_;
    my $this_last = $self->last_times;
    if ($this_last and (!defined $last or $this_last->[0] > $last)) {
	$last = $this_last->[0];
    }
    foreach ($self->subproject) {
	$last = $_->last_time_subprojects($last);
    }
    return $last;
}

=head2 interval_times

    @times = $project->interval_times("daily", %args)

Return the @times array (like $project->{'times'}) aggregated to an
interval. Valid argument values are: "" (no aggregation), daily,
weekly, monthly and yearly.

Further options:

=over

=item -recursive

If given and true, sum times for all subprojects too.

=item -asref

If given and true, then the returned value is a reference to
an array. This is useful for the "" interval, because it returns the
@times array of the project itself, which makes it easier for
manipulation.

=item -annotations

Include annotations as 3th element in times array.

=back

COMPATIBILITY: In Timex::Project prior 3.48, the order of an element
array was: [from_time, to_time, interval] (interval only with
aggregation). Since 3.48, this is [from_time, to_time, annotation,
interval].

=cut

sub interval_times {
    my $self = shift;
    my $interval_type = shift;
    my %args = @_;

    my $times;

    my $as_ref = $args{'-asref'};
    my $do_annotations = $args{'-annotations'};

    if ($args{'-recursive'}) {

	my @all_subs  = $self->all_subprojects;
	my @all_times = map { @{ $_->{'times'} } } @all_subs;
	my $combined = new Timex::Project;
	@{ $combined->{'times'} } = @all_times;
	$combined->sort_times;
	$times = $combined->{'times'};

    } else {

	$times = $self->{'times'};

    }

    if ($interval_type eq 'weekly') {
	eval {
	    require Date::Calc;
	};
	if ($@) {
	    warn "$@. Reverting to daily";
	    $interval_type = "daily";
	}
    }

    use constant INTERVAL_TYPE_NONE    => 0;
    use constant INTERVAL_TYPE_DAILY   => 1;
    use constant INTERVAL_TYPE_WEEKLY  => 2;
    use constant INTERVAL_TYPE_MONTHLY => 3;
    use constant INTERVAL_TYPE_YEARLY  => 4;

    my $it = {''        => INTERVAL_TYPE_NONE,
	      'daily'   => INTERVAL_TYPE_DAILY,
	      'weekly'  => INTERVAL_TYPE_WEEKLY,
	      'monthly' => INTERVAL_TYPE_MONTHLY,
	      'yearly'  => INTERVAL_TYPE_YEARLY,
	     }->{$interval_type};

    if ($it == INTERVAL_TYPE_NONE) {
	return ($as_ref ? $times : @$times);
    }

    require Time::Local;

    require Data::Dumper;
    my $t;
    my $tc = Data::Dumper->new([$times], ['t'])->Dump; # clone
    my(@times) = eval "$tc;" . '@$t';
    die @$ if $@;

    my @res;
    my($last_wday); # not really wday... for weeks this is the week number etc.

    my %annotations;
    my $out_annotations = sub {
	if ($do_annotations) {
	    join "; ", sort keys %annotations;
	} else {
	    undef;
	}
    };

    for(my $i = 0; $i<=$#times; $i++) {
	my @d = @{ $times[$i] }; # important: don't operate on ref!
	next if !defined $d[1]; # ignore running project
	my(@a1) = localtime $d[0];
	my(@a2) = localtime $d[1];
	if ($a1[7] != $a2[7]) {
	    # split into today and tomorrow
	    my $old_end = $d[1];
	    $d[1] = Time::Local::timelocal(59,59,23,$a1[3],$a1[4],$a1[5]);
	    splice @times, $i+1, 0, [$d[1]+1, $old_end, $out_annotations->()];
	}
	my $interval = $d[1] - $d[0];

	my $this_wday;
	if      ($it == INTERVAL_TYPE_DAILY) {
	    $this_wday = $a1[7];

	} elsif ($it == INTERVAL_TYPE_WEEKLY) {
	    $this_wday = Date::Calc::Week_Number
		(1900+$a1[5], 1+$a1[4], $a1[3]);

	} elsif ($it == INTERVAL_TYPE_MONTHLY) {
	    $this_wday = $a1[4]; # verzichte auf +1 ...

	} elsif ($it == INTERVAL_TYPE_YEARLY) {
	    $this_wday = $a1[5]; # verzichte auf +1900 ...
	}

	if (defined $last_wday && $last_wday == $this_wday) {
	    $res[$#res]->[1] = $d[1]; # correct end time
	    $annotations{$d[2]}++ if defined $d[2];
	    $res[$#res]->[2] = $out_annotations->();
	    $res[$#res]->[3] += $interval; # update daily/weekly... interval
	} else {
	    %annotations = ();
	    $annotations{$d[2]}++ if defined $d[2];
	    push @res, [$d[0], $d[1], $d[2], $interval]; # new interval
	}
	$last_wday = $this_wday;
    }

    # the ref thingy is unnecassary here, but do it for consistency...
    ($as_ref ? \@res : @res);

}

=head2 daily_times

    @times = $project->daily_times;

Same as interval_times('daily').

=cut

sub daily_times {
    my $self = shift;
    $self->interval_times("daily");
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

=head2 top_parent

    $top_parent = $project->top_parent

Return real top parent (that is, not the root project) of $project.

=cut

sub top_parent {
    my $self = shift;
    if (!$self->parent) {
	# this is already the root project, not defined
	undef;
    } elsif (!$self->parent->parent) {
	$self;
    } else {
	$self->parent->top_parent;
    }
}

=head2 reparent

    $project->reparent($newparent)

Use this method only if there is already a parent. Otherwise, use the
parent method.

=cut

sub reparent {
    my($self, $newparent) = @_;
    my $oldparent = $self->parent;
    # don't become a child of a descended project :-)
    return if $self->is_descendent($newparent);
    return if !$oldparent;         # don't reparent root
    $oldparent->delete_subproject($self);
    $newparent->subproject($self);
}

=head2 root

    $root = $p->root;

Return root node of the given project $p.

=cut

sub root {
    my $self = shift;
    if ($self->parent) {
	$self->parent->root;
    } else {
	$self;
    }
}

=head2 delete

    $p->delete;

Delete project $p. Note that you cannot delete the root project itself.

=cut

sub delete {
    my($self) = @_;
    my $parent = $self->parent;
    return if !$parent;
    $parent->delete_subproject($self);
}

sub delete_subproject {
    my($self, $subp) = @_;
    my @subprojects = @{$self->subproject};
    my @newsubprojects;
    foreach (@subprojects) {
	push(@newsubprojects, $_) unless $_ eq $subp;
    }
    $self->{'subprojects'} = \@newsubprojects;
    $self->modified(1);
}

sub delete_all {
    my($self) = @_;
    foreach ($self->subproject) {
	$self->delete_subproject($_);
    }
}

=head2 subproject

    $root->subproject([$label,[-useid => 1]]);

With label defined, create a new subproject labeled $label. Without
label, return either an array of subprojects (in array context) or a
reference to the array of subprojects (in scalar context).

=cut 

sub subproject {
    my($self, $label, %args) = @_;
    if (defined $label) {
	my $sub;
	my $ref_label = ref $label;
	if (!$ref_label || $ref_label !~ /^Timex::Project/) {
	    $sub = $self->new($label);
	} else {
	    $sub = $label;
	}
	$sub->parent($self);
	push @{ $self->{'subprojects'} }, $sub;
	if (!$args{-useid}) {
	    $sub->{'id'} = $self->next_id;
	}
	$self->modified(1);
	$sub;
    } else {
	wantarray ? @{$self->{'subprojects'}} : $self->{'subprojects'};
    }
}

=head2 sorted_subprojects

    $root->sorted_subprojects($sorted_by)

Return subprojects according to $sorted_by. If $sorted_by is 'name',
sorting is done lexically by name. If $sorted_by is 'time', sorting is
done by time (more time consuming subprojects come first). If $sorted_by
is 'latest', the last active projects come first.
If $sorted_by is not given or is 'nothing', no sorting is done.

=cut

sub sorted_subprojects {
    my($self, $sorted_by) = @_;
    if (!$sorted_by || $sorted_by =~ /^nothing$/i) {
	$self->subproject;
    } elsif ($sorted_by =~ /^name$/i) {
	sort { lc($a->label) cmp lc($b->label) } $self->subproject;
    } elsif ($sorted_by =~ /^time$/i) {
	sort { $b->sum_time(0, undef, -recursive => 1) <=> 
		 $a->sum_time(0, undef, -recursive => 1) }
	       $self->subproject;
    } elsif ($sorted_by =~ /^latest$/i) {
	sort { my $a_t = $a->last_time_subprojects;
	       my $b_t = $b->last_time_subprojects;
	       return -1 if (!defined $a_t);
	       return 1 if (!defined $b_t);
	       $b_t <=> $a_t } $self->subproject;
    } else {
	die "Unknown sort type: <$sorted_by>";
    }
}

=head2 all_subprojects

    @sub = $root->all_subprojects()

Return all projects below $root (recurse into tree) as an flat array
of Projects.

=cut

sub all_subprojects {
    my($self) = @_;
    my @res;
    push @res, $self;
    foreach ($self->subproject) {
	push @res, $_->all_subprojects;
    }
    @res;
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

=head2 find_by_pathname

    $project = $root->find_by_pathname($pathname);

Search and return the corresponding $project (or undef if no such
project exists) for the given $pathname.

=cut

sub find_by_pathname {
    my($self, $pathname) = @_;
    return $self if $self->pathname eq $pathname;
    foreach (@{$self->subproject}) {
	my $r = $_->find_by_pathname($pathname);
	return $r if defined $r;
    }
    return undef;
}

=head2 find_by_regex

    @projects = $root->find_by_regex($regex);

Search and return the projects, which labels match with $regex. The
returndes project objects are accumulated in an array.

=cut

sub find_by_regex {
    my($self, $regex) = @_;
    my @res;
    foreach my $p ($self->all_subprojects) {
	if (defined $p->label and $p->label =~ /$regex/) {
	    push @res, $p;
	}
    }
    @res;
}

=head2 find_by_regex_pathname

    @projects = $root->find_by_regex_pathname($regex);

Search and return the projects, which pathnames match with $regex. The
returndes project objects are accumulated in an array.

=cut

sub find_by_regex_pathname {
    my($self, $regex) = @_;
    my @res;
    foreach my $p ($self->all_subprojects) {
	if (defined $p->pathname and $p->pathname =~ /$regex/) {
	    push @res, $p;
	}
    }
    @res;
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
    push @{$self->{'times'}}, [$time];
    $self->update_cached_time;
    $self->modified(1);
}

sub end_time {
    my($self, $time) = @_;
    $time = time unless $time;
    my @times = @{ $self->{'times'} };
    $times[$#times][1] = $time;
    $self->update_cached_time;
    $self->modified(1);
}

sub unend_time {
    my $self = shift;
    my @times = @{ $self->{'times'} };
    return if (@{ $times[$#times] } != 2);
    pop @{ $times[$#times] };
    $self->update_cached_time;
    $self->modified(1);
}

sub set_times {
    my($self, $i, $start, $end, $annotation) = @_;
    if (defined $start) {
	$self->{'times'}[$i][0] = $start;
    }
    if (defined $end) {
	$self->{'times'}[$i][1] = $end;
    }
    if (defined $annotation) {
	$self->{'times'}[$i][2] = $annotation;
    }
    $self->update_cached_time;
    $self->modified(1);
}

=head2 delete_times

    $root->delete_times($index1, $index2 ...)

Delete the times definitions by the given indexes. If index is "all", then
all times definitions are deleted.

=cut

sub delete_times {
    my($self, @i) = @_;
    return if !@i;
    my @res;
    if (!(@i == 1 && $i[0] eq 'all')) {
	@i = sort { $a <=> $b } @i;
	for(my $i = 0; $i<=$#{ $self->{'times'} }; $i++) {
	    if (!@i) {
		push @res, @{$self->{'times'}}[$i .. $#{ $self->{'times'} }];
		last;
	    } elsif ($i == $i[0]) {
		shift @i;
	    } else {
		push @res, $self->{'times'}[$i];
	    }
	}
    }
    @{ $self->{'times'} } = @res;
    $self->update_cached_time;
    $self->modified(1);
}

sub insert_times_after {
    my($self, $i, $start, $end) = @_;
    splice @{ $self->{'times'} }, $i+1, 0, [$start, $end];
    $self->update_cached_time;
    $self->modified(1);
}

=head2 move_times_after

    $root->move_times_after($index_from, $index_before);

Move the times definition at $index_from after $index_before.

=cut

sub move_times_after {
    my($self, $i, $after) = @_;
    my $save = $self->{'times'}[$i];
    if ($i > $after) { # Reihenfolge beachten!
	$self->delete_times($i);
	$self->insert_times_after($after, $save->[0], $save->[1]);
    } else {
	$self->insert_times_after($after, $save->[0], $save->[1]);
	$self->delete_times($i);
    }
    # modified ist bereits gesetzt
}

sub sort_times {
    my($self) = @_;
    @{ $self->{'times'} } = sort { $a->[0] <=> $b->[0] } @{ $self->{'times'} };
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

    $time = $project->sum_time($since, $until, %args)

Return the time the given project accumulated since $since until $until.
If $until is undefined, return the time until now. If -recursive is set in
the %args hash to a true value, recurse into subprojects of $project.

=cut

sub sum_time {
    my($self, $since, $until, %args) = @_;
    my $sum = 0;
    if ($args{'-recursive'}) {
	foreach (@{$self->subproject}) {
	    $sum += $_->sum_time($since, $until, %args);
	}
    }
    if ($args{'-usecache'} && !defined $until &&
	exists $self->{'cached_time'}{$since}) {
 	$sum += $self->{'cached_time'}{$since};
	my $last_times = $self->{'times'}[$#{$self->{'times'}}];
 	if (!defined $last_times->[1] && defined $last_times->[0]) {
 	    $sum += time - $last_times->[0]; # XXX was wenn undefined?
 	}
    } else {
	my $this_sum = 0;
	my $dont_cache = 0;
	my @times = @{$self->{'times'}};
	my $i = -1;
	foreach (@times) {
	    my($from, $to) = ($_->[0], $_->[1]);
	    $i++;
	    if (defined $from) {
		if (!defined $to) {
		    if ($i != $#times) {
			warn "No end time in " . $self->pathname . " (pos $i)\n";
			next;
		    } else {
			$dont_cache++; # implizites Setzen, daher nicht cachen
			$to = time;
		    }
		}
		my $to = _min($to, $until);
		if ($since =~ /^\d+$/ && $to >= $since && $to >= $from) {
		    if ($from >= $since) {
			$this_sum += $to - $from;
		    } else {
			$this_sum += $to - $since;
		    }
		}
	    } else {
		warn "No start time in $self";
	    }
	}
	$sum += $this_sum;

	if ($args{'-usecache'} && !defined $until &&
	    !exists $self->{'cached_time'}{$since} &&
	    !$dont_cache) {
	    $self->{'cached_time'}{$since} = $this_sum;
	}
    }

    $sum;
}

=head2 update_cached_time

    $project->update_cached_time

STUB: Update the cached_time field of the project object.
NOW: Invalidate the cached_time field, so it may be racalculated by
sum_time.

=cut

sub update_cached_time {
    my $self = shift;
    while(my($from, $k) = each %{ $self->{'cached_time'} }) {
	delete $self->{'cached_time'}{$from};
#	$self->{'cached_time'}{$from} = $self->sum_time($from, undef);
    }
}

=head2 restricted_times

    @flattimes = $project->restricted_times($since, $until)

Return the times from the given project and subprojects since $since
until $until. If $until is undefined, return the time until now. The
returned array consists of elements with the following form:

   [$project, $from, $to]

=cut

sub restricted_times {
    my($self, $since, $until) = @_;
    my @times;
    foreach (@{$self->subproject}) {
	push @times, $_->restricted_times($since, $until);
    }
    foreach (@{$self->{'times'}}) {
	my($from, $to) = ($_->[0], $_->[1]);
	if (defined $from) {
	    if (!defined $to) {
		$to = time;
	    }
	}
	# fix from
	if ($since > $from && $since < $to) {
	    $from = $since;
	}
	# fix to
	if (defined $until) {
	    if ($until > $from && $until < $to) {
		$to = $until;
	    }
	}
	# check interval
	if ($since <= $from &&
	    (!defined $until || ($until >= $to))) {
	    push @times, [$self, $from, $to];
	}
    }

    sort { $a->[1] <=> $b->[1] } @times;
}

=head2 get_from_upper

    $value = $project->get_from_upper($attribute)
    $project->get_from_upper($attribute, $value)

Get the value for an attribute for this project, or, if undefined, for
one of the parents of this project.

With two arguments, set the value of the attribute of this project.

An alias C<_get_from_upper> exists for backward compatibility.

=cut

sub get_from_upper {
    my($self, $attribute) = (shift, shift);
    if (@_ > 0) {
	$self->{$attribute} = shift;
    } else {
	if (defined $self->{$attribute} && $self->{$attribute} ne "") {
	    $self->{$attribute};
	} elsif ($self->parent) {
	    $self->parent->get_from_upper($attribute);
	} else {
	    undef;
	}
    }
}
*_get_from_upper = \&get_from_upper;

=head2 archived

    $archived = $project->archived

Return true if the project or one of the parent projects are archived.
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

Return true if the root project is modified, that is, one of root's #'
subprojects are modified.

    $project->modified($modified)

Set the modified attribute (0 or 1) for the root project.

=cut

sub modified {
    my($self, $flag) = @_;
    my $root = $self->root;
    if (defined $flag) {
	$root->{'modified'} = ($flag ? 1 : 0);
    } else {
	$root->{'modified'};
    }
}

=head2 next_id

    $id = $project->next_id

Return the next free id in the project tree.

=cut

sub next_id {
    my($self) = @_;
    my $root = $self->root;
    ++$root->{'max_id'};
}

=head2 id

    $id = $project->id

Return the id of the project.

=cut

sub id { defined $_[0]->{'id'} ? $_[0]->{'id'} : "" }

=head2 rate

    $rate = $project->rate
    $project->rate($rate)

Get or set the rate for this project.

=cut

sub rate { shift->get_from_upper("rate", @_) }

=head2 domain

Get the project domain. A domain is just a user-specified label, which
can be used to separate private from corporate projects.

=cut

sub domain { shift->get_from_upper("domain", @_) }

=head2 get_all_domains

Return a list of all domains.

=cut

sub get_all_domains {
    my $self = shift;
    my $list = {};
    my $sub = sub {
	my $self = shift;
	if (defined $self->{'domain'} && $self->{'domain'} ne '') {
	    $list->{$self->{'domain'}}++;
	}
    };
    $self->traverse($sub);
    keys %$list;
}

=head2 get_all_annotations

    @annotations = $project->get_all_annotations($since, $until, %args)

Return all annotations as an array for the given project since $since
until $until. If $until is undefined, return the time until now.

=cut

sub get_all_annotations {
    my($self, $since, $until, %args) = @_;
    my @annotations;
    if ($args{'-recursive'}) {
	foreach (@{$self->subproject}) {
	    push @annotations, $_->get_all_annotations($since, $until, %args);
	}
    }

    my @times = @{$self->{'times'}};
    my $i = -1;
    foreach (@times) {
	my($from, $to, $annotation) = (@$_[0..2]);
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
		push @annotations, $annotation if defined $annotation;
	    }
	} else {
	    warn "No start time in $self";
	}
    }
    @annotations;
}

=head2 notimes

    $notimes = $project->notimes
    $project->notimes($notimes)

Get or set the notimes flag for this project.

=cut

sub notimes { shift->get_from_upper("notimes", @_) }

=head2 separator

    $separator = $project->separator

Return the separator for this tree (the root project). Defaults to /.

    $project->separator($separator);

Set the separator for this tree (the root project) to $separator.

=cut

sub separator {
    my($self, $separator) = @_;
    my $root = $self->root;
    if (defined $separator) {
	$root->{'separator'} = $separator;
    } else {
	$root->{'separator'};
    }
}

=head2 current

    $p = $project->current

Return the current project for this tree.

=cut

sub current {
    my($self) = @_;
    my $root = $self->root;
    $root->{'current'};
}

=head2 set_current

    $p->set_current

Set project $p as the current project for the tree. XXX Should
start/stop be called automatically?

=cut

sub set_current {
    my($self) = @_;
    my $root = $self->root;
    $root->{'current'} = $self;
}

=head2 no_current

    $p->no_current

Undef the current project setting for the project tree.

=cut

sub no_current {
    my($self) = @_;
    my $root = $self->root;
    $root->{'current'} = undef;
}

sub dump_data {
    my($self, %args) = @_;
    my $indent = delete $args{'-indent'};
    my $magic = ($args{-template} ? $magic_template : $magic);
    my $res;
    if (!$indent) {
	$res = "$magic $emacsmode\n";
	# XXX other root attributes too
	if ($self->notimes) {
	    $res .= "/notimes=1\n";
	}
	$indent = 0; # because of $^W
    } else {
	$res .= (">" x $indent) . "$self->{'label'}\n";

	# normal attributes
	foreach my $attr (@project_attributes) {
	    $res .= "/$attr=$self->{$attr}\n"
		if defined $self->{$attr} and $self->{$attr} ne "";
	}

	if ($self->note) {
	    $res .= join("\n", map { "/note=" . $_ } $self->note) . "\n";
	}
	if (!$args{'-skeleton'}) {
	    my $time;
	    foreach $time (@{$self->{'times'}}) {
		$res .= "|" . $time->[0];
		if (defined $time->[1]) {
		    $res .= "-" . $time->[1];
		}
		if (defined $time->[2]) {
		    # For now only one-liners are permitted. This may change.
		    (my $annotation = $time->[2]) =~ s/\n/ /gs;
		    $res .= " # $annotation";
		}
		$res .= "\n";
	    }
	}
    }
    my $subproject;
    foreach $subproject (@{$self->{'subprojects'}}) {
	$res .= $subproject->dump_data(-indent => $indent+1,
				       %args,
                                      );
    }
    $res;
}

=head2 save

    $project->save($file, ...);

Save the project to file $file. If the optional argument -skeleton is set
to true, do not save times.

Return 1 if the saving was successful, otherwise C<undef> or 0.

=cut

sub save {
    my($self, $file, %args) = @_;
    # first dump data, then open file... so crashes between open and print
    # are less likely
    my $buf = $self->dump_data(%args);
    if (!open(FILE, ">$file")) {
	$@ = "Can't write to <$file>: $!";
	warn $@;
	undef;
    } else {
	print FILE $buf;
	close FILE;
	# Filesize could be actually larger, because of different line
	# endings (so on MS-DOS/Windows)
	if (-f $file && 
	    length($buf) <= -s $file) {
	    1;
	} else {
	    $@ = "Expected size " . length($buf) . 
	      " of file <$file>, but got " . (-s $file) . "\n";
	    warn $@;
	    undef;
	}
    }
}

sub interpret_data {
    my($self, $data, %args) = @_;
    my $i = $[;
    my $found_magic = 0;
    for(; $i < $#$data; $i++) {
	if ($data->[$i] =~ /^($magic|$magic_template)/) {
	    $found_magic++;
	    last;
	}
    }
    $i++;
    if (!$found_magic) {
	if ($data->[0] =~ /<\?xml.*\?>/) {
	    eval q{
		use Timex::Project::XML;
		$self->rebless_subprojects("Timex::Project::XML");
		$found_magic = 1 if $self->interpret_data($data, %args);
	    };
	    warn $@ if $@;
	    return 1 if $found_magic;
	}
    }

    if (!$found_magic) {
	$@ = "Can't find magic in data!";
	warn $@;
	return undef;
    }

    $i = $self->interpret_data_project($data, $i, %args);
    return undef if !defined $i;

    1;
}

sub interpret_data_project {
    my($parent, $data, $i, %args) = @_;
    my $root = $parent->root;
    my($indent, $self);

    my $handle_attribute = sub {
	my($rest, $attributes) = @_;
	my(@attrpair) = split(/=/, $rest);
	# handle multiple attributes:
	if (exists $attributes->{$attrpair[0]}) {
	    if (ref $attributes->{$attrpair[0]} eq 'ARRAY') {
		push @{$attributes->{$attrpair[0]}}, $attrpair[1];
	    } else {
		$attributes->{$attrpair[0]} =
		    [$attributes->{$attrpair[0]}, $attrpair[1]];
	    }
	} else {
	    $attributes->{$attrpair[0]} = $attrpair[1];
	}
    };

    while(defined $data->[$i]) {
	if ($data->[$i] =~ m|^/| && $root eq $parent) {
	    # workaround: handle root attributes
	    my %root_attributes;
	    while(defined $data->[$i]) {
		last if $data->[$i] !~ m|^/(.*)|;
		$handle_attribute->($1, \%root_attributes);
		$i++;
	    }
	    if (keys %root_attributes) {
		foreach my $attr (@project_attributes) {
		    $parent->{$attr} = delete $root_attributes{$attr};
		}
		# XXX check for superfluous attributes
	    }
	}

	if ($data->[$i] !~ /^(>+)(.*)/) {
	    $@ = 'Project does not begin with ">"';
	    warn $@;
	    return undef;
	}
	my $label = $2;
	my $newindent = length($1);
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
		    $data->[$i] =~ /^(.)(.*)/;
		    my $first = $1;
		    my $rest = $2;
		    last if $first eq '>';
		    if ($first eq '|') {
			if (!$args{-skeleton}) {
			    my $annotation;
			    if ($rest =~ /^(.*?)\s*\#\s*(.*)$/) {
				$rest = $1;
				$annotation = $2;
			    }
			    my(@interval) = split(/-/, $rest);
			    warn "Interval must be two values in <" . $parent->pathname . "/$label>\n"
				if $#interval != 1;
			    push @times, [@interval,
					  (defined $annotation ? $annotation : ())
					 ];
			}
		    } elsif ($first eq '/') {
			$handle_attribute->($rest, \%attributes);
		    } elsif ($first eq '#') {
			push @comment, $rest;
		    } else {
			warn "Unknown command $first, ignoring...\n";
		    }
		    $i++;
		}
#		print STDERR (">" x $indent) . $label, "\n";
		$self = new Timex::Project $label;
		$self->{'times'} = \@times;
		foreach my $attr (@project_attributes) {
		    $self->{$attr} = delete $attributes{$attr};
		}
		if (defined $attributes{'note'}) {
		    $self->set_note($attributes{'note'});
		    delete $attributes{'note'};
		}
		warn "Unknown attributes: " . join(" ", %attributes)
		  if %attributes;
		$parent->subproject($self, -useid => 1);
		if ($self->id ne "") {
		    if ($root->{'max_id'} < $self->id) {
			$root->{'max_id'} = $self->id;
		    }
		} else {
		    $self->{'id'} = $root->next_id;
		}
                $self->update_cached_time;
	    }
	}
    }

    $i;
}

=head2 load

    $r = $project->load($filename, %args)

Load the project file $filename and returns true if the loading was
successfull. New data is merged to the existing project.

With -skeleton set to a true value, just load the project tree, but no
times.

=cut

sub load {
    my($self, $file, %args) = @_;
    my @data;
    if (!open(FILE, $file)) {
	$@ = "Can't read <$file>: $!";
	warn $@;
	undef;
    } else {
	while(<FILE>) {
	    chomp;
	    s/\r//g; # strip dos newlines
	    next if /^\s*$/; # overread empty lines
	    push @data, $_;
	}
	close FILE;
	$self->interpret_data(\@data, %args);
    }
}

=head2 is_project_file

    $r = Timex::Project->is_project_file($filename);

Return TRUE if $filename is a project file.

=cut

sub is_project_file {
    shift;
    my $filename = shift;
    if (!open(F, $filename)) {
	return undef;
    } else {
	my $res = 1;
	chomp(my $magicline = <F>);
	if ($magicline !~ /^($magic|$magic_template)/) {
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
	if (ref $_ and $_->isa('Timex::Project')) {
	    $self->subproject($_, -useid => 1);
	    $_->rebless_subprojects;
	} else {
	    warn "Unknown object $_";
	}
    }
}

sub rebless_subprojects {
    my($self, $class) = @_;
    $class = 'Timex::Project' unless $class;
    bless $self, $class;
    foreach (@{$self->subproject}) {
	bless $_, $class;
	$_->rebless_subprojects($class);
    }
}

sub traverse {
    my($self, $sub, @args) = @_;
    &$sub($self, @args);
    foreach ($self->subproject) {
	$_->traverse($sub, @args);
    }
}

=head2 last_project

    $last_project = $root->last_project

Return the last running project.

=cut

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

=head2 last_project

    $last_project = $root->last_projects([$nr])

Return the $nr last projects as an array. If $nr is not defined, return
the last project (same as the last_project method).

=cut

sub last_projects {
    my($self, $number) = @_;
    $number = 1 if !$number;
    my(@all);
    foreach ($self->all_subprojects) {
	my $end_time_pair = $_->{'times'}[$#{$_->{'times'}}];
	my $end_time = $end_time_pair->[$#{$end_time_pair}];
	if (defined $_->parent) {
	    $end_time = 0 if !defined $end_time;
	    push @all, [$_, $end_time];
	}
    } 
    @all = map { $_->[0] } sort { $b->[1] <=> $a->[1] } @all;
    splice @all, 0, $number;
}

=head2 merge

    ($modified, $new_proj_ref, $changed_proj_ref) = $project->merge($other_p)

=cut

sub merge {
    my($self, $other, %args) = @_;
    if (!$other->isa('Timex::Project')) {
	die "merge: arg must be Timex::Project!";
    }

    my %self_label;
    my $sub;
    foreach $sub ($self->subproject) {
	$self_label{$sub->label} = $sub;
    }

    my $modified = 0;
    my @new_p;
    my @changed_p;
    my %changed_p;

    my $allow_duplicates = $args{-allowduplicates};

    my $other_sub;
    foreach $other_sub ($other->subproject) {
	my $other_sub_path = $other_sub->pathname;
	if (exists $self_label{$other_sub->label}) {
	    my $sub = $self_label{$other_sub->label};

	    # otherwise bad inconsistencies can occur!
	    $sub->sort_times;
	    $other_sub->sort_times;

	    my $self_i = 0;
	    my $other_i = 0;
	    while($self_i <= $#{$sub->{'times'}} &&
		  $other_i <= $#{$other_sub->{'times'}}) {
		my $self_t  = $sub->{'times'}[$self_i];
		my $other_t = $other_sub->{'times'}[$other_i];
		if ($self_t->[0] < $other_t->[0]) {
		    $self_i++;
		} elsif ($self_t->[0] == $other_t->[0] &&
			 !$allow_duplicates) {
		    if ($self_t->[1] != $other_t->[1]) {
			warn "Warning: incompatible times for " .
			    $sub->label . ": " . $self_t->[1] . " != " .
			    $other_t->[1] . "\n";
			if ($self_t->[1] < $other_t->[1]) {
			    warn "Using bigger one...\n";
			    $sub->{'times'}[$self_i] = $other_t;
			    $modified++;
			    $changed_p{$other_sub_path} = $other_sub;
			}
		    }
		    $self_i++;
		    $other_i++;
		} else { # $self_t > $other_t
		    splice @{$sub->{'times'}}, $self_i, 0, $other_t;
		    $self_i++;
		    if ($self_t->[0] == $other_t->[0]) { # duplicate
			$self_i++;
		    }
		    $other_i++;
		    $modified++;
		    $changed_p{$other_sub_path} = $other_sub;
		}
	    }
	    if ($other_i <= $#{$other_sub->{'times'}}) {
		push(@{$sub->{'times'}},
		     @{$other_sub->{'times'}}[$other_i ..
					      $#{$other_sub->{'times'}}]);
		$modified += $#{$other_sub->{'times'}} - $other_i + 1;
		$changed_p{$other_sub_path} = $other_sub;
	    }
	    my($mod2, $new_p2_ref, $changed_p2_ref) = $sub->merge($other_sub);
	    $modified += $mod2;
	    push @new_p, @$new_p2_ref;
	    push @changed_p, @$changed_p2_ref;
	} else {
	    my $new_p = $self->subproject($other_sub);
	    $modified++;
	    push @new_p, $new_p;
	}
    }

    if ($modified) {
	$self->modified(1);
    }

    push @changed_p, values %changed_p;

    ($modified, \@new_p, \@changed_p);
}

# XXX need work...
# =head2 diff

#     $diff_project = $project->diff($other_project);

# Create a pseudo-project containing the differences between $project
# and $other_project (more exact: the additions in $other_project in
# respect of $project).

# =cut
 
# sub diff {
#     my($self, $other, %args) = @_;
#     my $diff_project = new Project;

#     # XXX duplicate code with merge!!!
#     my %self_label;
#     my $sub;
#     foreach $sub ($self->subproject) {
# 	$self_label{$sub->label} = $sub;
#     }

#     my $other_sub;
#     foreach $other_sub ($other->subproject) {
# 	if (exists $self_label{$other_sub->label}) {
# 	    my $sub = $self_label{$other_sub->label};
# 	    my $self_i = 0;
# 	    my $other_i = 0;
# 	    while($self_i <= $#{$sub->{'times'}} &&
# 		  $other_i <= $#{$other_sub->{'times'}}) {
# 		my $self_t  = $sub->{'times'}[$self_i];
# 		my $other_t = $other_sub->{'times'}[$other_i];
# 		if ($self_t->[0] < $other_t->[0]) {
# 		    $self_i++;
# 		} elsif ($self_t->[0] == $other_t->[0]) {
# 		    if ($self_t->[1] != $other_t->[1]) {
# 			warn "Warning: incompatible times for " .
# 			  $sub->label . ": " . $self_t->[1] . " != " .
# 			    $other_t->[1];
# 		    }
# 		    $self_i++;
# 		    $other_i++;
# 		} else { # $self_t > $other_t
# 		    splice @{$sub->{'times'}}, $self_i, 0, $other_t;
# 		    $self_i++;
# 		    $other_i++;
# 		    $modified++;
# 		}
# 	    }
# 	    if ($other_i <= $#{$other_sub->{'times'}}) {
# 		push(@{$sub->{'times'}},
# 		     @{$other_sub->{'times'}}[$other_i ..
# 					      $#{$other_sub->{'times'}}]);
# 		$modified += $#{$other_sub->{'times'}} - $other_i + 1;
# 	    }
# 	    $modified += $sub->merge($other_sub);
# 	} else {
# 	    $self->subproject($other_sub);
# 	    $modified++;
# 	}
#     }

# }

######################################################################

1;
