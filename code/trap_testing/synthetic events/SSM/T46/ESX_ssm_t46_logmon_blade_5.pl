#!/sbcimp/run/pd/perl/5.8.7/bin/perl -w

use Net::SNMP qw(:ALL);
use Time::HiRes qw(gettimeofday);
use strict;

my $trap_community = 'ESX';


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
		'.1.3.6.1.4.1.1977.30.1.1.3.28.1.1', OCTET_STRING, '/var/log/messages', 
		'.1.3.6.1.4.1.1977.30.3.1.3.28.1.2', OCTET_STRING, '[2008/03/24 21:35:00.000] dldn0075psp.ldn.swissbank.com: ERROR BLADE 6 Sun May 22 10:30:34 BST 2005 Internal Error CPU', 
#		'.1.3.6.1.4.1.1977.30.3.1.3.28.1.2', OCTET_STRING, '[2008/03/24 21:35:00.000] AlertGroup FIX:SIGNAL:CRITICAL:/sbcimp/run/tp/sun/jre/v1.4.2/bin/java -server -DRMIHost=ln16p1655cmp.ldn.swissbank.com -Xmx1764m -Xms256m -Dsun.rmi.dgc.client.gcInterval=900000 -Dsun.rmi.dgc.server.gcInterval=900000 -DORBsyncGC=false -verbose:gc -Xloggc:/sbcimp/dyn/logfiles/EQY_Fix/prod/GCKYLIE.log -XX:+PrintGCDetails -XX:+PrintTenuringDistribution -XX:MaxNewSize=256m -XX:NewSize=128m -XX:MaxPermSize=32m -classpath /home/fixprd/bin/FixJava.jar:/', 
		'.1.3.6.1.4.1.1977.30.3.1.3.28.1.3', OCTET_STRING, '[2008/03/24 21:35:00.000]xldn0138pap:FIX:SIGNAL:CRITICAL:/sbcimp/run/tp/sun/jre/v1:.chris', 
		'.1.3.6.1.4.1.1977.30.3.1.3.28.1.4', OCTET_STRING, 'ibm_blade_chassis_5'
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
	do_trap("xstm5257dap.stm.swissbank.com", "50162");
#	sleep 10;
#}


exit 0;
