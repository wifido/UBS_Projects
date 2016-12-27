#!/sbcimp/run/pd/perl/5.8.7/bin/perl -w

use Net::SNMP qw(:ALL);
use Time::HiRes qw(gettimeofday);
# use strict;
use IO::Socket;
use Getopt::Std;
use Socket;

my $trap_community = 'probetest';
my $remote_port = 2004 ;
#my $sock = "TO_SERVER";


sub do_sock
{
	my $remote_host = $_[0];
	print "  $_[0]\n";
#	my $socket = $sock;
	$socket = "TO_SERVER";
	my $time = time();
	socket($socket, PF_INET, SOCK_STREAM,getprotobyname('tcp'));
	

        # build the address of the remote machine
	my $internet_addr = inet_aton($remote_host) or die "no convert $remote_host  $!\n";
	my $paddr = sockaddr_in($remote_port, $internet_addr);

        # connect
	connect($socket, $paddr) or die "could not connect to $remote_host:remote_port : $!\n";

	# while we are connected send 9 events	
	#print $socket "\n";
	print $socket "'Transport' 'SocketTestScript'\n";
	print $socket "'Severity' 'INFO'\n";
	print $socket "'Nodealias' 'xstm8027pap.stm.swissbank.com'\n";
	print $socket "'EventIdentifier' 'Probe Test Event'\n";
	print $socket "'SAPname' 'SAPname'\n";
	print $socket "'Subclass' 'SubClass'\n";
	print $socket "'ClassID' '999999'\n";
	print $socket "'MessageText' 'Testing Probe Date Please Ignore\n'\n"; 
	print $socket "'EventType' '1'\n";
	print $socket "'EventTime' '$time'\n";
	print $socket "'Component' '$remote_host'\n";
	print $socket "'Stream' 'Stream'\n";
	print $socket "'Resolution' 'False'\n";
	print $socket "'Location' 'Location'\n";
	print $socket "'Userdata' ''\n";
	print $socket "'Acknowledged' '0'\n";
	print $socket "'Region' 'EMEA'\n";
	print $socket "\n";
	close($socket);
}

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
	#print "Trap Dest > $trap_dest    Port > $trap_port \n";
}




$oldtime = time;
$count = 0;
for ($i = 0; $i < 800000; $i++)
{
	# this sends a trap to xldn1054dap to it's Heartbeat Probe
	do_trap("139.149.52.158", "51162");
	$newtime = time;
	$count++;
	if ($oldtime == $newtime)
	{
		for ($delay=0;$delay<50000;$delay++)
		{
			#do nothing
			$newDelay = 0;
			$newDelay++;
		}
	}
	else
	{
		print " Time $newtime Count $count\n";
		$count = 0;
		$oldtime = $newtime;
	}
}
