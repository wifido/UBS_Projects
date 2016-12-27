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
		-version	=>	'2',
		-hostname 	=>  $trap_dest,
		-community 	=> $trap_community,
		-port		=> $trap_port,);
		
	my $notify = '.1.3.6.1.4.1.42.2.175.103.2';

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
		'1.3.6.1.6.3.1.1.4.1.0', OBJECT_IDENTIFIER, $notify,
		$notify .'.1', OCTET_STRING, 'sunHwTrapSystemIdentifier', #$sunHwTrapSystemIdentifier
		$notify .'.2', OCTET_STRING, 'sunHwTrapChassisId', #sunHwTrapChassisId
		$notify .'.3', OCTET_STRING, 'sunHwTrapProductName', #sunHwTrapProductName
		$notify .'.4', OCTET_STRING, 'sunHwTrapComponentName', #sunHwTrapComponentName
		$notify .'.5', OCTET_STRING, '1', #sunHwTrapThresholdType
		$notify .'.6', OCTET_STRING, '400', #sunHwTrapThresholdValue
		$notify .'.7', OCTET_STRING, '300', #sunHwTrapSensorValue
		$notify .'.8', OCTET_STRING, 'sunHwTrapAdditionalInfo', #sunHwTrapAdditionalInfo
		$notify .'.9', OCTET_STRING, 'sunHwTrapAssocObjectId', #sunHwTrapAssocObjectId
		$notify .'.10', OCTET_STRING, '5' #sunHwTrapSeverity
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
