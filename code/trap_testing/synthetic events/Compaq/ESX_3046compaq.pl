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
		-enterprise	=>	'.1.3.6.1.4.1.232',
		-generictrap	=>	'6',
		-specifictrap	=>	'3046',
		-timestamp	=>	$time,
		-varbindlist	=>	[
		'.1.3.6.1.4.1.232.1.1', OCTET_STRING, 'xstm9174dap',
		'.1.3.6.1.4.1.232.1.2', OCTET_STRING, '"cpqHoTrapFlags"',
		'.1.3.6.1.4.1.232.1.3', OCTET_STRING, '"cpqDaCntlrHwLocation"',
		'.1.3.6.1.4.1.232.1.4', OCTET_STRING, '"cpqDaPhyDrvCntlrIndex"',
		'.1.3.6.1.4.1.232.1.5', OCTET_STRING, '"cpqDaPhyDrvIndex"',
		'.1.3.6.1.4.1.232.1.6', OCTET_STRING, '"cpqDaPhyDrvLocationString"',
		'.1.3.6.1.4.1.232.1.7', OCTET_STRING, '"cpqDaPhyDrvType"',
		'.1.3.6.1.4.1.232.1.8', OCTET_STRING, '"cpqDaPhyDrvModel"',
		'.1.3.6.1.4.1.232.1.9', OCTET_STRING, '"cpqDaPhyDrvFWRev"',
		'.1.3.6.1.4.1.232.1.10', OCTET_STRING, '"cpqDaPhyDrvSerialNum"',
		'.1.3.6.1.4.1.232.1.11', OCTET_STRING, '"cpqDaPhyDrvFailureCode"',
		'.1.3.6.1.4.1.232.1.12', OCTET_STRING, '3',
		'.1.3.6.1.4.1.232.1.13', OCTET_STRING, '"cpqDaPhyDrvBusNumber"'
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
