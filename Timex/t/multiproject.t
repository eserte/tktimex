#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: multiproject.t,v 1.3 2001/04/04 22:39:51 eserte Exp $
# Author: Slaven Rezic
#

use strict;
use vars qw($first_project_text $second_project_text);

use lib qw(.. ../..);
use Timex::MultiProject;
use File::Compare;

do "testprojects.pl";

BEGIN {
    if (!eval q{
	use Test;
	1;
    }) {
	print "# tests only work with installed Test module\n";
	print "1..1\n";
	print "ok 1\n";
	exit;
    }
}

BEGIN { plan tests => 24 }

# write sample projects
open(W1, ">/tmp/t1.pj1") or die $!;
print W1 $first_project_text;
close W1;

open(W2, ">/tmp/t2.pj1") or die $!;
print W2 $second_project_text;
close W2;

# setup MultiProject
my $mpj = new Timex::MultiProject;
ok(!!$mpj->isa("Timex::MultiProject"), 1);
$mpj->master("/tmp/t1.pj1");
ok($mpj->master, "/tmp/t1.pj1");
$mpj->backups("/nonexistent/t3.pj1", "/tmp/t2.pj1", "/nonexistent/t4.pj1");
ok(join(",",$mpj->backups),
   join(",","/nonexistent/t3.pj1", "/tmp/t2.pj1", "/nonexistent/t4.pj1"));

# load (and implicit merge) of MultiProject
$mpj->load("dummy");
ok(!!$mpj->master_project, 1);
ok(ref $mpj->master_project, "Timex::Project");

# create clones of MultiProject
my $clone = $mpj->clone;
ok(ref $clone, "Timex::Project");
my $clone2 = $mpj->master_project->clone;
ok(ref $clone2, "Timex::Project");

ok($clone->save("/tmp/clone1.pj1"), 1);
ok($clone2->save("/tmp/clone2.pj1"), 1);
ok(compare("/tmp/clone1.pj1","/tmp/clone2.pj1"), 0);

# do manual merge of sample projects
my $first = new Timex::Project;
ok($first->load("/tmp/t1.pj1"), 1);
my $second = new Timex::Project;
ok($second->load("/tmp/t2.pj1"), 1);
$first->merge($second);
ok($first->save("/tmp/merged.pj1"), 1);

# save Multiproject and compare files
$mpj->save("dummy");
ok(compare("/tmp/t1.pj1","/tmp/t2.pj1"), 0);
ok(compare("/tmp/t1.pj1", "/tmp/merged.pj1"), 0);
ok(compare("/tmp/t1.pj1", "/tmp/clone1.pj1"), 0);

my $mpj2 = new Timex::MultiProject;
$mpj2->master("/nonexisting/bla.pj1");
$mpj2->backups("/nonexisting/bla2.pj1");
ok(!!$mpj2->isa("Timex::MultiProject"), 1);

$mpj2->load;
ok($mpj2->save, 0);

my $mpj3 = new Timex::MultiProject;
$mpj3->master("/nonexisting/bla.pj1");
$mpj3->backups("/tmp/t1.pj1");
ok(!!$mpj3->isa("Timex::MultiProject"), 1);

ok($mpj3->load, 1);
unlink "/tmp/t1.pj1";
ok($mpj3->save, 1);
ok(compare("/tmp/t1.pj1", "/tmp/t2.pj1"), 0);

my $mpj4 = new Timex::MultiProject;
$mpj4->set(-masterproject => $first,
	   -master => "/nonexisting/bla.pj1",
	   -backups => ["/nonexisting/bla2.pj1",
			"/nonexisting/bla3.pj1"]);
ok(1,1);

eval {
    $mpj4->set(-masterprojectXXX => $first);
};
ok($@ ne "", 1);

__END__
