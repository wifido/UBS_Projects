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
		-enterprise	=>	'.1.3.6.1.2.1.1.3.6.1.4.1.4320.1',
		-generictrap	=>	'6',
		-specifictrap	=>	'1',
		-timestamp	=>	$time,
		-varbindlist	=>	[
		'.1.3.6.1.2.1.1.0', OCTET_STRING, 'Warning', #OID1
		'.1.3.6.1.2.1.1.3.6.1.4.1.4320.1.1', OCTET_STRING, 'Janesch', #OID2
		'.1.3.6.1.2.1.1.3.6.1.4.1.4320.1.2', OCTET_STRING, 'XP:RADAR:ILDN:DB:Request Stuck', #OID3
		'.1.3.6.1.2.1.1.3.6.1.4.1.4320.1.3', OCTET_STRING, '11871', #OID4
		'.1.3.6.1.2.1.1.1.3.6.1.4.1.4320.1.4', OCTET_STRING, 'http://151.191.113.192:8888/SiteScope16:23hawthomiEA385399, schneit1, 2005-09-26 09:38:37.0, Portfolio Analysis 
      Tool, IMPLEMENTATION PENDING 16:23hawthomiEA398878, chirocr, 2005-10-28 09:59:14.0, FI CreditDelta012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789', #OID5
		'.1.3.6.1.2.1.1.3.6.1.4.1.4320.1.5', OCTET_STRING, '1.27 sec, 1 steps 1K total', #OID6
#		'.1.3.6.1.2.1.1.3.6.1.4.1.4320.1.5', OCTET_STRING, '1.27 sec, 1 steps 1K total01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789', #OID6
		'.1.3.6.1.2.1.1.3.6.1.4.1.4320.1.6', OCTET_STRING, 'XP:RADAR', #OID7
		'.1.3.6.1.2.1.1.3.6.1.4.1.4320.1.7', OCTET_STRING, '1054388', #OID8
		'.1.3.6.1.2.1.1.3.6.1.4.1.4320.1.8', OCTET_STRING, '636', #OID9
		'.1.3.6.1.2.1.1.3.6.1.4.1.4320.1.9', OCTET_STRING, 'IMS-eHelp', #OID10
		'.1.3.6.1.2.1.1.3.6.1.4.1.4320.1.10', OCTET_STRING, '1', #OID11
		'.1.3.6.1.2.1.1.3.6.1.4.1.4320.1.11', OCTET_STRING, '', #OID12
		'.1.3.6.1.2.1.1.3.6.1.4.1.4320.1.12', OCTET_STRING, 'Please go to http://sm0d1177www.stm.swissbank.com:8350/www/html/supportInfos/documents/Sitescoop/Sitescoop_Monitoring.htm#Request_Stuck for further instructions.', #OID13
		'.1.3.6.1.2.1.1.3.6.1.4.1.4320.1.13', OCTET_STRING, 'dnjeep1.ldn.swissbank.com', #OID14
		'.1.3.6.1.2.1.1.3.6.1.4.1.4320.1.14', OCTET_STRING, 'RADAR eACCESS Request Stuck', #OID15
		'.1.3.6.1.2.1.1.3.6.1.4.1.4320.1.15', OCTET_STRING, 'XSTM1SEH', #OID16
		'.1.3.6.1.2.1.1.3.6.1.4.1.4320.1.16', OCTET_STRING, 'RADAR eACCESS Request Stuck' #OID17
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
