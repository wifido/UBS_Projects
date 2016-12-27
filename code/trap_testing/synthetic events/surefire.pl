#!/sbcimp/run/pd/perl/5.8.7/bin/perl -w

use Net::SNMP qw(:ALL);
use Time::HiRes qw(gettimeofday);
use strict;

my $trap_community = 'PRI_PROBEAPP_DEV';


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
		'.1.3.6.1.4.1.1977.30.1.1.14.27', OCTET_STRING, '/var/log/sunfire/0messages.dldn0018dsp.ldn.swissbank.com', 
		'.1.3.6.1.4.1.1977.30.1.1.3.27', OCTET_STRING, 'May 3 12:22:13 dldn0018dsp.ldn.swissbank.comdldn0018dsp Platform.SC:1Fault detected, removing power from PS2 ',
		'.1.3.6.1.4.1.1977.30.3.1.3.27.4.1', OCTET_STRING, '4', 
		'.1.3.6.1.4.1.1977.30.3.1.4.27.4.1', OCTET_STRING, 'ssm_logmon_syslog_surefire_5' 
		]
	);
	if (!defined($result)) 
	{
		printf("ERROR: %s.\n", $session->error());

	}

	$session->close();
	print "Trap Dest > $trap_dest    Port > $trap_port \n";
}

do_trap("151.191.98.138", "50162");


exit 0;
