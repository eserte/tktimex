#!/usr/local/bin/perl -w
# -*- perl -*-

#
# $Id: timexserver.cgi,v 1.3 1999/10/26 00:28:17 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 1999 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

# XXX FCGI verwenden

use FindBin;
use lib ("$FindBin::RealBin");

use Event;
#use Storable qw(nstore freeze);
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
    # XXX quote
    my $auth_hidden =
      '<input type=hidden name=user value="' . $q->param("user") . '">' .
      '<input type=hidden name=pw value="' . $q->param("pw") . '">';

    my $list_sub = sub {
	print <<EOF;
<html><head><script>
function startit(pn) {
    document.forms[0].elements["args"].value = pn;
    document.forms[0].submit();
    return false;
}

function stopit(pn) {
    document.forms[0].elements["args"].value = pn;
    document.forms[0].elements["cmd"].value = "stop";
    document.forms[0].submit();
    return false;
}

</script></head>
<body>
EOF
	print "<h1>Timex for " . $q->param('user') . "</h1>";
	print "<form method=post>";
	print $auth_hidden;
	print "<input type=hidden name=cmd value=start>";
	print "<input type=hidden name=args value=''>";
	print "<table>\n";
	my $has_current = 0;
	foreach (split("\0\1", $_[1])) {
	    print "<tr>";
	    my($pn, $c, $t) = split("\0", $_);
	    print "<td><a href='" . $q->script_name . "?cmd=start&args=" .
	      CGI::escape($pn) . "&$auth' onclick='return startit(\"$pn\")'>$_</a></td> ";
	    print "<td>";
	    if ($c) {
		print " (<a name=current href='" . $q->script_name . "?cmd=stop&args=" . CGI::escape($pn) . "&$auth' onclick='return stopit(\"$pn\")'>current</a>) ";
		$has_current = 1;
	    }
	    print "</td><td>";
	    print sec2time($t) . "</td></tr>\n";
	}
	print <<EOF;
</table>
</form>
EOF
        if ($has_current) {
	    print <<EOF;
<script>
window.location.hash = "current";
</script>
EOF
        }
	print <<EOF;
</body>
</html>
EOF
	Event::unloop()
      };
    
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
	 code => $list_sub
       },

       { name => 'stop', req => 'a*',
	 code =>
	 sub {
	     print "<form method=post>";
	     print $auth_hidden;
	     print "<input type=hidden name=cmd value=stop>";
	     print "<input type=submit value='";
	     print "Stop current $_[1]";
	     print "'>";
	     print "</form>";
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
<form method=post>
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
