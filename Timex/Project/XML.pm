# -*- perl -*-

#
# $Id: XML.pm,v 1.1 1999/09/18 13:36:41 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 1999 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

package Timex::Project::XML;
use base qw(Timex::Project);
use XML::Parser;

sub load { # XXX error handling
    my($self, $file) = @_;
    my $p1 = new XML::Parser(Style => 'Tree');
    my $tree = $p1->parsefile($file);
    if ($tree->[0] ne 'timexdata') {
	die "This is not timexdata";
    }
    $tree = $tree->[1];
    $self->interpret_tree($tree);

}

sub dump_data {
    my $self = shift;
    my $res = "<?xml version='1.0' encoding='ISO-8859-1' standalone='yes'?>\n";
    $res   .= "<timexdata>\n";
    foreach my $p ($self->subproject) {
	$res .= $p->dump_data_subproject(Indent => 1);
    }
    $res   .= "</timexdata>\n";
    $res;
}

sub dump_data_subproject {
    my($p, %args) = @_;
    my $res = "";
    my $is = " " x ($args{Indent} || 0);
    $res .= $is."<project name='" . $p->label . "'";
    $res .=     " archived='" . $p->archived . "'";
    $res .=     " rcsfile='" . $p->rcsfile . "'" if defined $p->rcsfile;
    $res .=     ">\n";
    $res .= $is." <times>\n";
    foreach my $ts (@{ $p->{'times'} }) {
	$res .= $is."  <timeslice from='" . $ts->[0] .
	  "' to='" . $ts->[1] . "' />\n";
    }
    $res .= $is." </times>\n";
    foreach my $subp ($p->subproject) {
	$res .= $subp->dump_data_subproject(Indent => $args{Indent}+1);
    }
    $res .= $is."</project>\n";
    $res;
}

sub interpret_tree {
    my($self, $tree) = @_;

    my $attributes = $tree->[0];
    $self->label(delete $attributes->{'name'});
    $self->{'archived'} = delete $attributes->{'archived'};
    $self->{'rcsfile'}  = delete $attributes->{'rcsfile'};
    if (defined $attributes->{'note'}) {
	$self->note($attributes->{'note'});
	delete $attributes->{'note'};
    }
    warn "Unknown attributes: " . join(" ", %$attributes)
      if %$attributes;
    
    for(my $i = 1; $i<=$#$tree; $i+=2) {
	if ($tree->[$i] eq 'project') {
	    my $new_sub = new Timex::Project::XML;
	    $new_sub->interpret_tree($tree->[$i+1]);
	    $self->subproject($new_sub);
	} elsif ($tree->[$i] eq 'times') {
	    my $slices = $tree->[$i+1];
	    my @times;
	    for(my $j = 1; $j<=$#$slices; $j+=2) {
		if ($slices->[$j] eq 'timeslice') {
		    push @times, [$slices->[$j+1][0]{'from'},
				  $slices->[$j+1][0]{'to'},
				 ];
		}
	    }
	    $self->{'times'} = \@times;
	} elsif ($tree->[$i] == 0) {
	    # ignore
	} else {
	    die "Invalid tag in timexdata file: got " . $tree->[$i] . "\n" .
	      "Next tag: " . $tree->[$i+1];
	}
    }
}

1;

__END__
