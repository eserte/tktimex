#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: 80heavy.t,v 1.1 2006/01/09 21:08:26 eserte Exp $
# Author: Slaven Rezic
#

use strict;
use FindBin;

BEGIN {
    if (!eval q{
	use Test::More;
	use File::Spec::Functions qw(catfile updir);
	use File::Temp qw(tempfile);
	use File::Copy qw(cp);
	use Data::Dumper qw();
	1;
    }) {
	print "1..0 # skip: no Test::More and/or some File::* modules\n";
	exit;
    }
}

if ($^O eq 'MSWin32') {
    plan skip_all => "Test not running nicely on Windows";
    exit;
}

$ENV{TKTIMEX_GUI_TESTING} = 1;

my @test_args = (
		 [],
		 ["-sessioncol"],
		 ["-notree", "-nolock", "-noautosave", "-iconified",
		  "-username", "USER", "-realname", "REAL NAME"],
		 ["-update", 1],
		 ["-dateformat", "frac d", "-noday8", "-archived"],
		 ["-onlytop", "-sort", "time"],
		 ["-projectlabelformat", "%n %j %J %y %Y %p"],
		 ["-maxlastprojects", 4],
		);

plan tests => scalar(@test_args);

my $tktimex_exe = catfile($FindBin::RealBin, updir, "tktimex");

my($tempfh,$tempfile) = tempfile(SUFFIX => ".pj1",
				 CLEANUP => 1);
cp catfile($FindBin::RealBin, "test.pj1"), $tempfile
    or die "Can't copy: $!";
close $tempfh;

my($rcfh, $rcfile) = tempfile(SUFFIX => ".tktimexrc",
			      CLEANUP => 1);
$ENV{TKTIMEXRC} = $rcfile;

my @stdargs = ($tktimex_exe, "-geometry", "500x300+10+10", "-f", $tempfile);

for my $cmdadd (@test_args) {
    my @cmd = (@stdargs, @$cmdadd);
    system @cmd;
    is($?, 0, "Called with @cmd");
}

__END__
