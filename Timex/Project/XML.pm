# -*- perl -*-

#
# $Id: XML.pm,v 1.2 1999/09/18 17:44:59 eserte Exp $
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

*convert1 = \&escape_special;
*convert2 = \&utf8_latin1;

sub load {
    my($self, $file) = @_;
    $self->_common_load(File => $file);
}

sub interpret_data {
    my($self, $data) = @_;
    $self->_common_load(Data => $data);
}

sub _common_load { # XXX error handling
    my($self, %args) = @_;
    my $p1 = new XML::Parser(Style => 'Tree');
    my $tree;
    if (exists $args{Data}) {
	$tree = $p1->parse(join("\n", @{ $args{Data} }),
			   ProtocolEncoding => 'ISO-8859-1');
    } elsif (exists $args{File}) {
	$tree = $p1->parsefile($args{File});
    } else {
	die "Neither Data nor File fiven in _common_load";
    }
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

sub dump_data_subproject { # XXX note is missing...
    my($p, %args) = @_;
    my $res = "";
    my $is = " " x ($args{Indent} || 0);
    $res .= $is."<project name='" . convert1($p->label) . "'";
    $res .=     " archived='" . $p->archived . "'";
    $res .=     " rcsfile='" . convert1($p->rcsfile) . "'" 
      if defined $p->rcsfile;
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
    $self->label(convert2(delete $attributes->{'name'}));
    $self->{'archived'} = delete $attributes->{'archived'};
    $self->{'rcsfile'}  = convert2(delete $attributes->{'rcsfile'});
    if (defined $attributes->{'note'}) {
	$self->note(convert2(delete $attributes->{'note'}));
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
    1;
}

# XXX only german latin1 characters are translated with these functions

sub latin1_utf8 {
    my $s = shift;
    return "" unless defined $s;
    $s =~ s/�/\xc3\xa4/g;
    $s =~ s/�/\xc3\xb6/g;
    $s =~ s/�/\xc3\xbc/g;
    $s =~ s/�/\xc3\x84/g;
    $s =~ s/�/\xc3\x96/g;
    $s =~ s/�/\xc3\x9c/g;
    $s =~ s/�/\xc3\x9f/g;
    $s;
}

sub escape_special {
    my $s = shift;
    return "" unless defined $s;
    $s =~ s/&/&amp;/g;
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;
    $s =~ s/\'/&apos;/g;
    $s;
}

sub utf8_latin1 {
    my $s = shift;
    return "" unless defined $s;
    $s =~ s/\xc3\xa4/�/g;
    $s =~ s/\xc3\xb6/�/g;
    $s =~ s/\xc3\xbc/�/g;
    $s =~ s/\xc3\x84/�/g;
    $s =~ s/\xc3\x96/�/g;
    $s =~ s/\xc3\x9c/�/g;
    $s =~ s/\xc3\x9f/�/g;
    $s;
}

sub nil { $_[0] }

1;

__END__