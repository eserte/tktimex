# -*- perl -*-

#
# $Id: Server.pm,v 1.1 1999/10/25 23:33:52 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 1999 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

package Timex::Server;

use Event;

use strict;
use vars qw($port);

$port = 8463;

1;

__END__
