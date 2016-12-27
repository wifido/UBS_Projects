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
		'.1.3.6.1.4.1.1977.30.1.1.3.28', OCTET_STRING, '/sbcimp/dyn/logfiles/Raptor/vwap/log/ss/ss.app.log', 
		'.1.3.6.1.4.1.1977.30.3.1.3.28.1.2', OCTET_STRING, '27-Apr 16:02:58.377 SEVERE [err] {DynamicThreadPool (1): Worker 69}:  at com.ubs.eq.tes.raptor.strategyserver.manager.ExceptionCatcher.handleEvent(ExceptionCatcher.java(Compiled Code))', 
		'.1.3.6.1.4.1.1977.30.3.1.4.28.1.2', OCTET_STRING, '4', 
		'.1.3.6.1.4.1.1977.30.1.1.14.28', OCTET_STRING, 'ssm_logmon_app_4:999999:Raptor:1:vwap.log' 
		]
	);
	if (!defined($result)) 
	{
		printf("ERROR: %s.\n", $session->error());

	}

	$session->close();
	print "Trap Dest > $trap_dest    Port > $trap_port \n";
}

do_trap("xstm5257dap.stm.swissbank.com", "50162");


exit 0;
