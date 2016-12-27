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
		-specifictrap	=>	'34',
		-timestamp	=>	$time,
		-varbindlist	=>	[
		'.1.3.6.1.4.1.1977.30.1.1.3.28.1.1', OCTET_STRING, '',	# genAlarmControlVariable
		'.1.3.6.1.4.1.1977.30.3.1.3.28.1.2', OCTET_STRING, 'ssm_fsmon:123000:SubClass:9:AlertKey', 	# genAlarmControlVariableDescription
		'.1.3.6.1.4.1.1977.30.3.1.3.28.1.3', OCTET_STRING, '12345678901234567890123456789012345678901234567890', 	# genAlarmDataInstance	
		'.1.3.6.1.4.1.1977.30.3.1.3.28.1.4', OCTET_STRING, '', 	# genAlarmControlSampleType
		'.1.3.6.1.4.1.1977.30.3.1.3.28.1.5', OCTET_STRING, '', 	# genAlarmControlAlarmMode
		'.1.3.6.1.4.1.1977.30.3.1.3.28.1.6', OCTET_STRING, '', 	# genAlarmDataValue
		'.1.3.6.1.4.1.1977.30.3.1.3.28.1.7', OCTET_STRING, '', 	# genAlarmControlRisingThreshold
		'.1.3.6.1.4.1.1977.30.3.1.3.28.1.8', OCTET_STRING, '', 	# genAlarmControlRisingDuration
		'.1.3.6.1.4.1.1977.30.3.1.3.28.1.9', OCTET_STRING, '',	# genAlarmControlRisingSeverity
		'.1.3.6.1.4.1.1977.30.3.1.3.28.1.10', OCTET_STRING, 'Summary t34_premiumload',	# genAlarmControlRisingDescription
		'.1.3.6.1.4.1.1977.30.3.1.3.28.1.11', OCTET_STRING, 'Temp Summary ',	# genAlarmControlRisingDescription
		'.1.3.6.1.4.1.1977.30.3.1.3.28.1.12', OCTET_STRING, 'configstartup'	# genAlarmControlRisingDescription
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
