#!/sbcimp/run/pd/perl/5.8.7/bin/perl -w

use Net::SNMP qw(:ALL);
use Time::HiRes qw(gettimeofday);
use strict;

my $trap_community = '999999';


# Here we start the loop. The logic will be a bit ovelry complicated as we need to create new sessions for each trap.

sub do_trap 
{
	my $trap_dest = $_[0];
	my $trap_port = $_[1];
	my ($session, $error) = Net::SNMP->session(
		-version	=>	'1',
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
	my $result = $session->snmpv2_trap(
		-varbindlist	=>	[
		'1.3.6.1.2.1.1.3.0', TIMETICKS, '1',
		'1.3.6.1.6.3.1.1.4.1.0', OBJECT_IDENTIFIER, '.1.3.6.1.4.1.12925.1.8',
		'.1.3.6.1.4.1.12925.1.8.1', OCTET_STRING, 'Component', #OID1
		'.1.3.6.1.4.1.12925.1.8.2', OCTET_STRING, 'Component', #OID2
		'.1.3.6.1.4.1.12925.1.8.3', OCTET_STRING, 'Details', #OID3
		'.1.3.6.1.4.1.12925.1.8.4', OCTET_STRING, '31', #OID4 NodeID but not as we know it
		'.1.3.6.1.4.1.12925.1.8.5', OCTET_STRING, '1', #OID5 Severity
		'.1.3.6.1.4.1.12925.1.8.6', OCTET_STRING, 'time', #OID6
		'.1.3.6.1.4.1.12925.1.8.7', OCTET_STRING, '1', #OID7 unique ID
		'.1.3.6.1.4.1.12925.1.8.8', OCTET_STRING, '2', #OID8 Message code
		'.1.3.6.1.4.1.12925.1.8.9', OCTET_STRING, '1' #OID9 state
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
