# -*- perl -*-

#
# $Id: PHPGroupware.pm,v 1.2 2003/03/28 16:52:40 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 2001 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

package Timex::Project::PHPGroupware;

use strict;
use vars qw($VERSION $tablename);
$VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);

use DBI;

$tablename = 'phpgw_categories' unless defined $tablename;

my $cat_owner = 2; # XXX

sub new {
    my($class, %args) = @_;
    my $self = {};
    while(my($k,$v) = each %args) {
	if ($k =~ /^-(.*)/) {
	    $self->{ucfirst($1)} = $v;
	} else {
	    die "Unrecognized argument $k";
	}
    }
    bless $self, $class;
    $self->init;
    $self;
}

sub init {
    my $self = shift;
    my $dbh = DBI->connect("dbi:mysql:" . $self->{DBName},
			   $self->{DBUser}, $self->{DBPassword},
			   { RaiseError => 1});
    $self->{Dbh} = $dbh;
    $self->{Sth_Exists} = $dbh->prepare("SELECT COUNT(*) FROM $tablename WHERE cat_name = ? AND cat_parent = ?") or die $!;
    $self->{Sth_Search} = $dbh->prepare("SELECT cat_id FROM $tablename WHERE cat_name = ? AND cat_parent = ?") or die $!;
    $self->{Sth_Insert} = $dbh->prepare("INSERT INTO $tablename (cat_parent, cat_owner, cat_access, cat_appname, cat_name, cat_description, cat_data) VALUES (?, ?, ?, ?, ?, ?, ?)") or die $!;
    $self->{Sth_LastIndex} = $dbh->prepare("SELECT LAST_INSERT_ID()") or die $!;
}

sub add_to_phpgroupware {
    my($self, $root) = @_;
    foreach my $p ($root->subproject) {
	$self->_add_project($p);
    }
}

sub _add_project {
    my($self, $p) = @_;
    warn "add project " . $p->pathname;
    my $name = $self->_normalize_name($p->label);
    my $parent_id = 0;
    foreach my $path ($p->path) {
	next if !defined $path;
	my $name = $self->_normalize_name($path);
	warn "$path $name $parent_id";
	$self->{Sth_Exists}->execute($name, $parent_id) or die "Can't execute exists SQL: $!";
	unless (($self->{Sth_Exists}->fetchrow_array)[0]) {
	    $self->{Sth_Insert}->execute($parent_id, $cat_owner, 'public', 'phpgw', $name, '', '') or die $!;
	    $self->{Sth_LastIndex}->execute or die $!;
	    $parent_id = ($self->{Sth_LastIndex}->fetchrow_array)[0];
	    $self->{Sth_LastIndex}->finish;
	} else {
	    $self->{Sth_Search}->execute($name, $parent_id) or die $!;
	    $parent_id = ($self->{Sth_Search}->fetchrow_array)[0];
	    $self->{Sth_Search}->finish;
	}
	$self->{Sth_Exists}->finish;
    }

    foreach my $subp ($p->subproject) {
	$self->_add_project($subp);
    }
}

sub _normalize_name {
    my($self, $name) = @_;
    my $conv = {'ä' => 'ae', 'ö' => 'oe', 'ü' => 'ue', 'ß' => 'ss',
		'Ä' => 'Ae', 'Ö' => 'Oe', 'Ü' => 'Ue'};
    my $keys = join("", keys %$conv);
    $name =~ s/([$keys])/$conv->{$1}/g;
    $name =~ s/\W/_/g;
    $name;
}

sub DESTROY {
    my $self = shift;
    $self->{Dbh}->disconnect if $self->{Dbh};
}

return 1 if caller();

require Timex::Project;
require Getopt::Long;
my $dbname = 'phpgroupware';
my $dbuser = 'root';
my $dbpassword;
if (!Getopt::Long::GetOptions("dbname=s" => \$dbname,
			      "dbuser=s" => \$dbuser,
			      "dbpassword|dbpwd=s" => \$dbpassword)) {
    die "usage?";
}
if (!defined $dbpassword) {
    die "-dbpassword is missing";
}
my $root = Timex::Project->new;
my $filename = shift || die "Filename?";
$root->load($filename) or die "Can't load $filename";
my $converter = Timex::Project::PHPGroupware->new
    (-DBName => $dbname,
     -DBUser => $dbuser,
     -DBPassword => $dbpassword,
    );
$converter->add_to_phpgroupware($root),

__END__

=head1 NAME

Timex::Project::PHPGroupware - interface to phpgroupware

=head1 SYNOPSIS


=head1 DESCRIPTION

=head1 AUTHOR

Onlineoffice - slaven@rezic.de

=head1 SEE ALSO

=cut

