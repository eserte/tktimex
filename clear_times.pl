#!/usr/local/bin/perl -w
# -*- perl -*-

#
# $Id: clear_times.pl,v 1.1 1999/04/07 19:33:11 eserte Exp $
#
# Author: Slaven Rezic
#
# Mail: mailto:eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

use FindBin;
use lib "$FindBin::RealBin";
use Timex::Project;

my($infile, $outfile);
if ($^O ne 'MSWin32') { # XXX - stdin/out does not work with win32
    $infile  = shift || "-";
    $outfile = shift || "-";
} else {
    $infile  = shift || die "input file missing";
    $outfile = shift || die "output file missing";
    if ($infile eq $outfile) {
	print STDERR
	    "Warning: input and output file are identical.\n",
	    "Do you really want to continue? (y/N) ";
	my($yn) = scalar <STDIN>;
	if ($yn !~ /^y/) {
	    print STDERR "Exiting...\n";
	    exit 1;
	}
    }
}

my $root = new Timex::Project;
$root->load($infile);
foreach my $p ($root->all_subprojects) {
    $p->delete_times("all");
}
$root->save($outfile);
