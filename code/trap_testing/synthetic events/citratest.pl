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
 
	my $time = time();
	my $result = $session->trap(
		-enterprise	=>	'.1.3.6.1.4.1.18876.1',
		-generictrap	=>	'6',
		-specifictrap	=>	'1',
		-timestamp	=>	$time,
		-varbindlist	=>	[
		'.1.3.6.1.4.1.18876.1.1', OCTET_STRING, '"Remedy_Experience_RaiseTickets', 
		'.1.3.6.1.4.1.18876.1.2', OCTET_STRING, 'StopTimerFail', 
		'.1.3.6.1.4.1.18876.1.3', OCTET_STRING, '2006-01-10 12:13:15', 
		'.1.3.6.1.4.1.18876.1.4', OCTET_STRING, '2006-01-10 12:13:16', 
		'.1.3.6.1.4.1.18876.1.5', OCTET_STRING, '5', 
		'.1.3.6.1.4.1.18876.1.6', OCTET_STRING, '"Remedy_Experience_RaiseTickets_cj_1057419', 
		'.1.3.6.1.4.1.18876.1.7', OCTET_STRING, '2006-01-10 12:13:17', 
		'.1.3.6.1.4.1.18876.1.8', OCTET_STRING, 'WLDN0144847', 
		'.1.3.6.1.4.1.18876.1.9', OCTET_STRING, '0', 
		'.1.3.6.1.4.1.18876.1.10', OCTET_STRING, '0', 
		'.1.3.6.1.4.1.18876.1.11', OCTET_STRING, '0' 
		]
	);
	if (!defined($result)) 
	{
		printf("ERROR: %s.\n", $session->error());

	}

	$session->close();
	print "Trap Dest > $trap_dest    Port > $trap_port \n";
}

do_trap("151.191.98.138", "162");


exit 0;
