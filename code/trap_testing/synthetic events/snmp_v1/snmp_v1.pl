#!/sbcimp/run/pd/perl/5.8.7/bin/perl -w

use Net::SNMP qw(:ALL);
use Time::HiRes qw(gettimeofday);
use strict;

my $trap_community = '2217101:T24_CUSTODY_PR';


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
 	my $Enterprise = ".1.3.6.1.4.1.8072.4";
	my $time = time();
	my $result = $session->trap(
		-enterprise	=>	$Enterprise,
		-generictrap	=>	'6',
		-specifictrap	=>	'1',
		-timestamp	=>	$time,
		-varbindlist	=>	[
		$Enterprise . '.1', OCTET_STRING, '"1"', 
		$Enterprise . '.2', OCTET_STRING, '"WLDN144847"', 
		$Enterprise . '.3', OCTET_STRING, '"synthetic_events\vhayu.pl"', 
		$Enterprise . '.4', OCTET_STRING, '"20060410,00:00:00:00,WLDN144847,9998,VBS,HIGH,000000,This, is a test event for testing with"', 
		]
	);
	if (!defined($result)) 
	{
		printf("ERROR: %s.\n", $session->error());

	}

	$session->close();
	print "Trap Dest > $trap_dest    Port > $trap_port \n";
}

do_trap("xstm5257dap.stm.swissbank.com", "162");


exit 0;
