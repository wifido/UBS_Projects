#!/sbcimp/run/pd/perl/5.8.3/bin/perl -w

use Net::SNMP qw(:ALL);
use Time::HiRes qw(gettimeofday);
use strict;

my $trap_community = 'probetest';


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
		-enterprise	=>	'1.3.6.1.4.1.18876.1',
		-generictrap	=>	'6',
		-specifictrap	=>	'1',
		-timestamp	=>	$time,
		-varbindlist	=>	[
		'1.3.6.1.4.1.18876.1.1.0', OCTET_STRING, 'Remedy Login LDN1',
		'1.3.6.1.4.1.18876.1.2.0', OCTET_STRING, 'Stop Timer',
		'1.3.6.1.4.1.18876.1.3.0', OCTET_STRING, 'varbind3',
		'1.3.6.1.4.1.18876.1.4.0', OCTET_STRING, 'varbind4',
		'1.3.6.1.4.1.18876.1.5.0', OCTET_STRING, '6',
		'1.3.6.1.4.1.18876.1.6.0', OCTET_STRING, 'Remedy_Experience_RaiseTickets',
		'1.3.6.1.4.1.18876.1.7.0', INTEGER, '4',
		'1.3.6.1.4.1.18876.1.8.0', OCTET_STRING, "Workstation"
		]
	);
	if (!defined($result)) 
	{
		printf("ERROR: %s.\n", $session->error());

	}

	$session->close();
	print "Trap Dest > $trap_dest    Port > $trap_port \n";
}

do_trap("xldn1052dap.ldn.swissbank.com", "162");


exit 0;
