#!/usr/local/bin/perl -w
# -*- perl -*-

#
# $Id: timexserver.cgi,v 1.2 1999/10/25 23:54:00 eserte Exp $
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
use lib ("$FindBin::RealBin");

use Event;
use Timex::Server;
use CGI;
use strict;

my $q = new CGI;
my @cmd = (['start', 1],
	   ['stop'],
	   ['list'],
	  );
my %valid_cmd = map { ($_->[0] => 1) } @cmd;

my @no_cache = ('-expires' => 'now',
		'-pragma' => 'no-cache',
		'-cache-control' => 'no-cache',
               );
print $q->header(@no_cache);

if (exists $valid_cmd{$q->param('cmd')}) {
    my $auth =  "user=" . CGI::escape($q->param('user')) .
               "&pw="   . CGI::escape($q->param('pw'));

    my $api = 
      [{ name => 'ok', req => 'a*',
	 code => sub {
	     if ($_[1] eq 'OK') {
		 print "OK!\n";
	     } else {
		 print "Not OK: $_[1]\n";
	     }
	     Event::unloop()
	 } 
       },
       
       { name => 'list', req => 'a*',
	 code => sub {
	     print "<table>\n";
	     foreach (split("\0\1", $_[1])) {
		 print "<tr>";
		 my($pn, $c, $t) = split("\0", $_);
		 print "<td><a href='" . $q->script_name . "?cmd=start&args=" .
		   CGI::escape($pn) . "&$auth'>$_</a></td> ";
		 print "<td>";
		 if ($c) {
		     print " (current) ";
		 }
		 print "</td><td>";
		 print sec2time($t) . "</td></tr>\n";
	     }
	     print "</table>\n";
	     Event::unloop()
	 } 
       },

       { name => 'stop', req => 'a*',
	 code => sub {
	     print "<a href='" . $q->script_name . "?cmd=stop&$auth'>Stop current $_[1]</a>\n";
	     Event::unloop()
	 } 
       },

      ];

    my $c;
    $c = Event->tcpsession
      (port => $Timex::Server::port,
       api  => $api,
       cb   => sub {
	   my($c, $conn) = @_;
	   exit if ($conn eq 'disconnect');
	   $c->rpc($q->param('cmd'),
		   join("\0", 
			'-user', $q->param('user'),
			'-pw',   $q->param('pw'),
			'-args', $q->param('args')),
		  );
       });
    warn $c;
    if ($@) {
	print "Can't connect to server";
    }

    Event::loop();
} else {

    print <<EOF;
<body>
<form>
Username: <input type=text name=user><br>
Password: <input type=password name=pw><br>
<input type=hidden name=cmd value=list>
<input type=hidden name=args value=''><br>
<input type=submit>
</form>
</body>
EOF
}

# partly stolen from tktimex
sub sec2time {
    my($sec) = @_;
    my($day, $hour, $min);
    $hour = int($sec / 3600);
    $sec  = $sec % 3600;
    $min  = int($sec / 60);
    sprintf("%02d:%02d:%02d", $hour, $min, $sec % 60);
}

__END__
