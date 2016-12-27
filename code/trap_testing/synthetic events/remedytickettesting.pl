#!/sbcimp/run/pd/perl/5.8.7/bin/perl -w

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
		-enterprise	=>	'.1.3.6.1.2.1.1.3.6.1.4.1.4320.1',
		-generictrap	=>	'6',
		-specifictrap	=>	'1',
		-timestamp	=>	$time,
		-varbindlist	=>	[
		'.1.3.6.1.2.1.1.0', OCTET_STRING, 'Warning', #OID1
		'.1.3.6.1.2.1.1.3.6.1.4.1.4320.1.1', OCTET_STRING, 'Janesch', #OID2
		'.1.3.6.1.2.1.1.3.6.1.4.1.4320.1.2', OCTET_STRING, 'Testing', #OID3
		'.1.3.6.1.2.1.1.3.6.1.4.1.4320.1.3', OCTET_STRING, '11871', #OID4
		'.1.3.6.1.2.1.1.1.3.6.1.4.1.4320.1.4', OCTET_STRING, 'Testing', #OID5
		'.1.3.6.1.2.1.1.3.6.1.4.1.4320.1.5', OCTET_STRING, 'Testing', #OID6
#		'.1.3.6.1.2.1.1.3.6.1.4.1.4320.1.5', OCTET_STRING, 'Testing', #OID6
		'.1.3.6.1.2.1.1.3.6.1.4.1.4320.1.6', OCTET_STRING, 'Testing', #OID7
		'.1.3.6.1.2.1.1.3.6.1.4.1.4320.1.7', OCTET_STRING, 'Testing', #OID8
		'.1.3.6.1.2.1.1.3.6.1.4.1.4320.1.8', OCTET_STRING, 'Testing', #OID9
		'.1.3.6.1.2.1.1.3.6.1.4.1.4320.1.9', OCTET_STRING, 'Testing', #OID10
		'.1.3.6.1.2.1.1.3.6.1.4.1.4320.1.10', OCTET_STRING, '1', #OID11
		'.1.3.6.1.2.1.1.3.6.1.4.1.4320.1.11', OCTET_STRING, '', #OID12
		'.1.3.6.1.2.1.1.3.6.1.4.1.4320.1.12', OCTET_STRING, 'Testing', #OID13
		'.1.3.6.1.2.1.1.3.6.1.4.1.4320.1.13', OCTET_STRING, 'Testing', #OID14
		'.1.3.6.1.2.1.1.3.6.1.4.1.4320.1.14', OCTET_STRING, 'Testing', #OID15
		'.1.3.6.1.2.1.1.3.6.1.4.1.4320.1.15', OCTET_STRING, 'Testing', #OID16
		'.1.3.6.1.2.1.1.3.6.1.4.1.4320.1.16', OCTET_STRING, 'Testing' #OID17
		]
	);
	if (!defined($result)) 
	{
		printf("ERROR: %s.\n", $session->error());

	}

	$session->close();
	print "Trap Dest > $trap_dest    Port > $trap_port \n";
}

do_trap("139.149.32.210", "162");


exit 0;
