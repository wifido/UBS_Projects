#!/sbcimp/run/pd/perl/5.8.7/bin/perl -w
use IO::Socket;
#use strict;
use Getopt::Std;
use Socket

getopts('I:');

### Here we create all relevant variables ###
# Dev 9839
#my $remote_host = "151.191.98.138" ;
# Eng
#my $remote_host = "151.191.119.183" ;
#my $remote_host = "165.222.100.32" ;
# xldn0065pap
#my $remote_host = "139.149.42.166" ;
#my $remote_host = "151.191.229.167" ;
#my $remote_host = "151.191.119.235";
#my $remote_port = 2004 ;
my $remote_port = 2004 ;
my $sock = "TO_SERVER";
### Here are all the TCP related sub routines ###
#
#
#

sub do_send
{
	my $remote_host = $_[0];
print "  $_[0]\n";
	for($Count = 0; $Count <101; $Count = $Count +1)
	{
		my $socket = $sock;
		my $time = time();
		socket($socket, PF_INET, SOCK_STREAM,getprotobyname('tcp'));
	

        	# build the address of the remote machine
		$internet_addr = inet_aton($remote_host) or die "no convert $remote_host  $!\n";
		$paddr = sockaddr_in($remote_port, $internet_addr);
		print "$Count\n";


        	# connect
		connect($socket, $paddr) or die "could not connect to $remote_host:remote_port : $!\n";
for($ci = 0;$ci <26;$ci=$ci + 1)
	{
		# while we are connected send 9 events	
		#print $socket "\n";
		print $socket "'Transport' 'SocketTestScript'\n";
#		print $socket "'Severity' 'DEBUG'\n";
		print $socket "'Severity' 'INFO'\n";
#		print $socket "'Severity' 'WARN'\n";
#		print $socket "'Severity' 'ERROR'\n";
#		print $socket "'Severity' 'FATAL'\n";
		print $socket "'Nodealias' 'WLDN0144847.develop.ubsw.net'\n";
		print $socket "'EventIdentifier' 'Probe Test Event $Count'\n";
		print $socket "'ClassID' '999999'\n";
		print $socket "'MessageText' 'Testing Probe Date Please Ignore\n'\n"; 
		print $socket "'EventTime' '$time'\n";
		print $socket "'Component' '$remote_host'\n";
		print $socket "\n";

	}
		close($socket);
	}
}

for (;;)
{
	# Send to the eng box
	do_send ("139.149.52.156");
	
	#Send Events to the STM ENG
	#do_send ("151.191.119.183");
	
	# Send to the dev box
	#do_send ("151.191.98.138");
	# xstm8951pap
	#do_send ("151.191.229.167");
	# xldn0065pap
	#do_send ("139.149.42.166");
	# xopf0101
	#do_send ("165.222.100.32");
	# xsng1001pap
	#do_send ("147.60.8.174");
	# xldn1014pap
	#do_send ("139.149.32.210");
	# test
	#do_send ("151.191.119.183");
	# xldn0065pap
	#do_send ("139.149.42.166");

	sleep 5;
}
	exit 0;


