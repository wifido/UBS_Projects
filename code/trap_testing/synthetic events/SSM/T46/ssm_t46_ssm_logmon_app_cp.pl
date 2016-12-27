#!/sbcimp/run/pd/perl/5.8.7/bin/perl -w

use Net::SNMP qw(:ALL);
use Time::HiRes qw(gettimeofday);
use strict;

my $trap_community = 'OSXAGENT_HB';


# Here we start the loop. The logic will be a bit ovelry complicated as we need to create new sessions for each trap.

sub do_trap 
{
	my $trap_dest = $_[0];
	my $trap_port = $_[1];
	my ($session, $error) = Net::SNMP->session(
		-hostname 	=>  $trap_dest,
		-community 	=> $trap_community,
		-port		=> $trap_port,);

	if (!defined($session)) 
	{
		printf("ERROR: %s.\n", $error);
		exit 1;
	}

	# Here we build the trap properly for UBS standard.
 
	my $time = time();
	my $result = $session->trap(
		-enterprise	=>	'.1.3.6.1.4.1.1977',
		-generictrap	=>	'6',
		-specifictrap	=>	'46',
		-timestamp	=>	$time,
		-varbindlist	=>	[
		'.1.3.6.1.4.1.1977.30.1.1.3.28', OCTET_STRING, '/var/log/messages', 
#		'.1.3.6.1.4.1.1977.30.3.1.3.28.1.2', OCTET_STRING, '[2008/03/24 21:35:00.000]xldn0138pap:FIX:SIGNAL:CRITICAL:/sbcimp/run/tp/sun/jre/v1.4.2/bin/java -server -DRMIHost=ln16p1655cmp.ldn.swissbank.com -Xmx1764m -Xms256m -Dsun.rmi.dgc.client.gcInterval=900000 -Dsun.rmi.dgc.server.gcInterval=900000 -DORBsyncGC=false -verbose:gc -Xloggc:/sbcimp/dyn/logfiles/EQY_Fix/prod/GCKYLIE.log -XX:+PrintGCDetails -XX:+PrintTenuringDistribution -XX:MaxNewSize=256m -XX:NewSize=128m -XX:MaxPermSize=32m -classpath /home/fixprd/bin/FixJava.jar:/sbcimp/run/pkgs/EQY_CashExec/v1.7.3/gma.jar:/sbcimp/run/pkgs/EQY_CashExec/v1.7.3/names.jar:/sbcimp/run/pkgs/EQY_CashExec/v1.7.3/sesame.jar:/sbcimp/run/pkgs/EQY_CashExec/v1.7.3/uap.jar:/sbcimp/run/pkgs/EQY_CashExec/v1.7.3/util.jar:/sbcimp/run/pkgs/EQY_CashExec/v1.7.3/ues.jar:/sbcimp/run/pkgs/EQY_CashExec/v1.9.1/uap.jar:/sbcimp/run/pkgs/EQY_CashExec/v1.9.1/names.jar:/sbcimp/run/pkgs/EQY_CashExec/v1.9.1/util.jar:/sbcimp/run/pkgs/EQY_CashExec/v1.9.1/sesame.jar:/sbcimp/run/pkgs/EQY_CashExec/v1.9.1/gma.jar:/sbcimp/run/pkgs/EQY_CashExec/v1.9.1/tombase.jar:/sbcimp/run/pkgs/EQY_FixJava/v3.2.1/lib/FixJava.jar:/sbcimp/run/pkgs/EQY_FixUtils/v1.0.3/lib/fixutils.jar:/sbcimp/run/pkgs/', 
		'.1.3.6.1.4.1.1977.30.3.1.3.28.1.2', OCTET_STRING, '[2008/03/24 21:35:00.000]xldn0138pap:FIX:SIGNAL:CRITICAL:/sbcimp/run/tp/sun/jre/v1:.chris', 
#		'.1.3.6.1.4.1.1977.30.3.1.3.28.1.2', OCTET_STRING,'[2008/04/01 17:08:54.160 HOG_ActiveWorksPinger.cc:119(27)]sldn0471pap:HOG_ActiveWorksPinger:ERROR:MAJOR:Listener::onEventReceived - ignoring out of sequence event - Prod-Prod/CM/1-1206918256',
#		'.1.3.6.1.4.1.1977.30.3.1.3.28.1.2', OCTET_STRING,'',
#		'.1.3.6.1.4.1.1977.30.3.1.3.28.1.2', OCTET_STRING,'[2008/04/06 12:03:31 #1] ssng1071pap:WISPALINK:START:INFORMATION:Process wispalink  started [pid:16949]',
#		'.1.3.6.1.4.1.1977.30.3.1.3.28.1.2', OCTET_STRING,'[2008/04/02 23:02:03 #1] ssng1071pap:OASIS_IDP_WATCHER:START:INFORMATION:Process oasis_idp_watcher  started [pid:17036]',
		'.1.3.6.1.4.1.1977.30.3.1.4.28.1.2', OCTET_STRING, '4', 
		'.1.3.6.1.4.1.1977.30.1.1.14.28', OCTET_STRING, 'ssm_logmon_app_cp:999999:Opera:1:P1hog9CP.log' 
		]
	);
	if (!defined($result)) 
	{
		printf("ERROR: %s.\n", $session->error());

	}

	$session->close();
	print "Trap Dest > $trap_dest    Port > $trap_port \n";
}

my $loop = 0;

#while (1)
#{
#	$loop = $loop +1;
#	print "Loop > $loop   ";
	do_trap("161.239.152.57", "50162");
#	sleep 10;
#}


exit 0;
