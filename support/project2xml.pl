#!/usr/local/bin/perl -w
# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 1999 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

use FindBin;
use lib "$FindBin::RealBin/..";

use Timex::Project;
use Timex::Project::XML;

my $infile = shift or die "Please specify in file";
my $outfile = shift or die "Please specify out file";

my $p = new Timex::Project;
$p->load($infile);
$p->rebless_subprojects('Timex::Project::XML');
$p->save($outfile);

__END__
