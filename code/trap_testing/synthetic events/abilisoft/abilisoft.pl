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
		
	my $notify = '.1.3.6.1.4.1.26788.100.1';

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
		$notify .'.1', OCTET_STRING, 'CRITICAL', # not used?
		$notify .'.2', OCTET_STRING, '14.64.15.242', # Node
		$notify .'.3', OCTET_STRING, 'wldn0189500', # NodeAlias
		$notify .'.4', OCTET_STRING, 'Disk usage on sda1 above 75% threshold', # Summary
		$notify .'.5', OCTET_STRING, 'Disk usage', # AlertGroup
		$notify .'.6', OCTET_STRING, '76', # UserInt
		$notify .'.7', OCTET_STRING, 'sda1' # AlertKey
		]
	);

	if (!defined($result)) 
	{
		printf("ERROR: %s.\n", $session->error());

	}

	$session->close();
	print "Trap Dest > $trap_dest    Port > $trap_port \n";
}

#do_trap("xldn2929dap.ldn.swissbank.com", "162");
#do_trap("xstm5257dap.stm.swissbank.com", "162");
do_trap("xsng1283pap.sng.swissbank.com", "162");


exit 0;
