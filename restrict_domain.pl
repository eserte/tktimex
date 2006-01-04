#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: restrict_domain.pl,v 1.1 2006/01/04 01:04:32 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 2000 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

use FindBin;
use lib "$FindBin::RealBin";
use Timex::Project;

use strict;

my $infile = shift || die "File?";
my $domain = shift || die "Domain?"

my $root = new Timex::Project;
$root->load($infile);

my @projects;

# XXXX weiter implementieren

__END__
