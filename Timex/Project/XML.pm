# -*- perl -*-

#
# $Id: XML.pm,v 1.8 2003/03/28 16:52:51 eserte Exp $
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

# XXX noch nicht getestet
# XXX code aus Tk::XMLViewer verwenden (repository?)
eval q{
    use utf8;
    sub convert2 {
	my $s = shift;
	return "" unless defined $s;
	$s =~ tr/\0-\x{ff}//UC;
	$s;
    }
    sub convert3 {
	my $s = shift;
	return "" unless defined $s;
	$s =~ tr/\0-\xff//CU;
	$s;
    }
};
if ($@) {
    warn "Can't handle unicode in perl, using workaround...\n";
    *convert2 = \&utf8_latin1;
    *convert3 = \&latin1_utf8;
}

sub load {
    my($self, $file, %args) = @_;
    $self->_common_load(File => $file, %args);
}

sub interpret_data {
    my($self, $data, %args) = @_;
    $self->_common_load(Data => $data, %args);
}

sub _common_load { # XXX error handling
    my($self, %args) = @_;
    my $p1 = new XML::Parser(Style => 'Tree');
    my $tree;
    if (exists $args{Data}) {
	$tree = $p1->parse(join("\n", @{ $args{Data} }),
			   ProtocolEncoding => 'ISO-8859-1');
	delete $args{Data};
    } elsif (exists $args{File}) {
	$tree = $p1->parsefile($args{File});
	delete $args{File};
    } else {
	die "Neither Data nor File fiven in _common_load";
    }
    if ($tree->[0] ne 'timexdata') {
	die "This is not timexdata";
    }
    $tree = $tree->[1];
    $self->interpret_tree($tree, %args);
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
    foreach my $attr (@Timex::Project::attributes) {
	$res .= " $attr='" . convert1($p->{$attr}) . "'"
	    if defined $p->{$attr} and $p->{$attr} ne "";
    }
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
    my($self, $tree, %args) = @_;

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
	    $self->subproject($new_sub, -useid => 1);
	} elsif ($tree->[$i] eq 'times') {
	    my $slices = $tree->[$i+1];
	    my @times;
	    if (!$args{-skeleton}) {
		for(my $j = 1; $j<=$#$slices; $j+=2) {
		    if ($slices->[$j] eq 'timeslice') {
			push @times, [$slices->[$j+1][0]{'from'},
				      $slices->[$j+1][0]{'to'},
				      ];
		    }
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

# not yet used...
sub latin1_utf8 {
    my $s = shift;
    return "" unless defined $s;
    $s =~ s/ä/\xc3\xa4/g;
    $s =~ s/ö/\xc3\xb6/g;
    $s =~ s/ü/\xc3\xbc/g;
    $s =~ s/Ä/\xc3\x84/g;
    $s =~ s/Ö/\xc3\x96/g;
    $s =~ s/Ü/\xc3\x9c/g;
    $s =~ s/ß/\xc3\x9f/g;
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
    $s =~ s/\xc3\xa4/ä/g;
    $s =~ s/\xc3\xb6/ö/g;
    $s =~ s/\xc3\xbc/ü/g;
    $s =~ s/\xc3\x84/Ä/g;
    $s =~ s/\xc3\x96/Ö/g;
    $s =~ s/\xc3\x9c/Ü/g;
    $s =~ s/\xc3\x9f/ß/g;
    $s;
}

sub nil { $_[0] }

1;

__END__
