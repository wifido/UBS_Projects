#!/sbcimp/run/pd/perl/5.8.3/bin/perl -w

use Net::SNMP qw(:ALL);
use Time::HiRes qw(gettimeofday);
use strict;

my $counter = 0;
#my $trap_dest = "151.191.119.235";	# xstm1935dap
my $trap_dest = "151.191.98.138";	# xstm9838dap
#my $trap_dest = "151.191.119.183";	# xstm1953dap
my $trap_community = 'probetest';
#my $trap_port = 162;
my $trap_port = 50162;

my $t0 = gettimeofday;

print STDOUT "Traps being transmitted at $t0\n";

# Here we start the loop. The logic will be a bit ovelry complicated as we need to create new sessions for each trap.

sub do_trap 
{
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
		-enterprise	=>	'1.3.6.1.4.1.19945.998.1',
		-generictrap	=>	'6',
		-specifictrap	=>	'1',
		-timestamp	=>	$time,
		-varbindlist	=>	[
		'1.3.6.1.4.1.19945.998.1.1.0', OCTET_STRING, 'varbind1',
		'1.3.6.1.4.1.19945.998.1.2.0', OCTET_STRING, 'varbind2',
		'1.3.6.1.4.1.19945.998.1.3.0', OCTET_STRING, 'varbind3',
		'1.3.6.1.4.1.19945.998.1.4.0', OCTET_STRING, 'varbind4',
		'1.3.6.1.4.1.19945.998.1.5.0', OCTET_STRING, 'varbind5',
		'1.3.6.1.4.1.19945.998.1.6.0', OCTET_STRING, 'varbind6',
		'1.3.6.1.4.1.19945.998.1.7.0', INTEGER, '4',
		'1.3.6.1.4.1.19945.998.1.8.0', OCTET_STRING, "varbind8"
		]
	);
	if (!defined($result)) 
	{
		printf("ERROR: %s.\n", $session->error());

	}

	$session->close();
	$counter++;
	print "Trap Dest > $trap_dest    Port > $trap_port \n";
}

$trap_dest = "151.191.98.138";	# xstm9838dap
$trap_port = 50162;
do_trap;
$trap_dest = "151.191.98.138";	# xstm9838dap
$trap_port = 162;
do_trap;

my $t1 = gettimeofday;
my $elapsed =$t1 - $t0;

print STDOUT "Traps all sent by $t1\n";
print STDOUT "$counter traps tooks $elapsed Seconds\n";
exit 0;
