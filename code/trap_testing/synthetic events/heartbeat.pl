#!/sbcimp/run/pd/perl/5.8.7/bin/perl -w

use Net::SNMP qw(:ALL);
use Time::HiRes qw(gettimeofday);
#use strict;

my $trap_community = 'SSMAGET_HB';


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
		-enterprise	=>	'.1.3.6.1.4.1.1977.0.22',
		-generictrap	=>	'6',
		-specifictrap	=>	'1',
		-timestamp	=>	$time,
		-varbindlist	=>	[
		'.1.3.6.1.4.1.20371.3.1.1.1.0', OCTET_STRING, '"1"', 
		'.1.3.6.1.4.1.20371.3.1.1.2.0', OCTET_STRING, '"WLDN144847"', 
		'.1.3.6.1.4.1.20371.3.1.1.3.0', OCTET_STRING, '"synthetic_events\vhayu.pl"', 
		'.1.3.6.1.4.1.20371.3.1.1.4.0', OCTET_STRING, '"20060410,00:00:00:00,WLDN144847,9999,VBS,HIGH,000000,This, is a test event for testing with"', 
		]
	);
	if (!defined($result)) 
	{
		printf("ERROR: %s.\n", $session->error());

	}

	$session->close();
	#print "Trap Dest > $trap_dest    Port > $trap_port \n";
}
$oldtime = time;
$count = 0;
for ($i = 0; $i < 20000; $i++)
{
	# this sends a trap to xldn1054dap to it's Heartbeat Probe
	do_trap("139.149.52.158", "51162");
	$newtime = time;
	$count++;
	if ($oldtime == $newtime)
	{
	}
	else
	{
		print " Time $newtime Count $count\n";
		$count = 0;
		$oldtime = $newtime;
	}
}

exit 0;
