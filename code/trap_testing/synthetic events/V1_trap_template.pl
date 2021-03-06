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
		-hostname 	=>  $trap_dest,
		-community 	=> $trap_community,
		-port		=> $trap_port,);
		
	my $enterprise = '.1.3.6.1.2.1.88.2';

	if (!defined($session)) 
	{
		printf("ERROR: %s.\n", $error);
		exit 1;
	}

	# Here we build the trap properly for UBS standard.
 
	my $time = time();
	my $result = $session->trap(
		-enterprise	=>	$enterprise,
		-generictrap	=>	'6',
		-specifictrap	=>	'1',
		-timestamp	=>	$time,
		-varbindlist	=>	[
		$enterprise .'.1', OCTET_STRING, '', #$sunHwTrapSystemIdentifier
		$enterprise .'.2', OCTET_STRING, 'BEL07451AT', #sunHwTrapChassisId
		$enterprise .'.3', OCTET_STRING, '', #sunHwTrapProductName
		$enterprise .'.4', OCTET_STRING, '/SYS/PS0/DC_POK', #sunHwTrapComponentName
		$enterprise .'.5', OCTET_STRING, 'State Asserted', #sunHwTrapThresholdType
		$enterprise .'.6', OCTET_STRING, '.1.3.6.1.2.1.47.1.1.1.1.2.313', #sunHwTrapThresholdValue
		$enterprise .'.7', OCTET_STRING, '', #sunHwTrapSensorValue
		$enterprise .'.8', OCTET_STRING, '', #sunHwTrapAdditionalInfo
		$enterprise .'.9', OCTET_STRING, '', #sunHwTrapAssocObjectId
		$enterprise .'.10', OCTET_STRING, '' #sunHwTrapSeverity
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
