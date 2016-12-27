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
		-specifictrap	=>	'46',
		-timestamp	=>	$time,
		-varbindlist	=>	[
		'.1.3.6.1.4.1.1977.30.1.1.3.28', OCTET_STRING, '/var/log/messages', 
		'.1.3.6.1.4.1.1977.30.3.1.3.28.1.2', OCTET_STRING, '12:01 17:12:2007 szur8019bap     Fault_PC 0x100260f0 Esynd 0x01e8 C2/P0/B0/D0: B0/D0 ', 
		'.1.3.6.1.4.1.1977.30.3.1.4.28.1.2', OCTET_STRING, '4', 
		'.1.3.6.1.4.1.1977.30.1.1.14.28', OCTET_STRING, 'ssm_logmon_syslog_sunfire_5' 
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
