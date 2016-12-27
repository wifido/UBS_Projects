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
	my $socket = $sock;
	my $time = time();
	socket($socket, PF_INET, SOCK_STREAM,getprotobyname('tcp'));
	

        # build the address of the remote machine
	$internet_addr = inet_aton($remote_host) or die "no convert $remote_host  $!\n";
	$paddr = sockaddr_in($remote_port, $internet_addr);

        # connect
	connect($socket, $paddr) or die "could not connect to $remote_host:remote_port : $!\n";

	# while we are connected send 9 events	
	#print $socket "\n";
	print $socket "'Transport' 'Transport'\n";
#	print $socket "'Severity' 'DEBUG'\n";
#	print $socket "'Severity' 'INFO'\n";
#	print $socket "'Severity' 'WARN'\n";
#	print $socket "'Severity' 'ERROR'\n";
	print $socket "'Severity' 'FATAL'\n";
	print $socket "'Nodealias' 'wldn0189500.develop.ubsw.net'\n";
	print $socket "'EventIdentifier' 'Event Identifier'\n";
	print $socket "'SAPname' 'SAPname'\n";
	print $socket "'Subclass' 'SubClass'\n";
	print $socket "'ClassID' '999999'\n";
	print $socket "'MessageText' 'Message text'\n"; 
	print $socket "'EventType' '1'\n";
	print $socket "'EventTime' '$time'\n";
	print $socket "'Component' 'Component'\n";
	print $socket "'Stream' 'Stream'\n";
	print $socket "'Resolution' 'False'\n";
	print $socket "'Location' 'Location'\n";
	print $socket "'Userdata' 'Userdata'\n";
	print $socket "'Acknowledged' '0'\n";
	print $socket "'SystolicHeartbeat' '1'\n";
#	print $socket "'DiastolicHeartbeat' '1'\n";
	print $socket "'Region' 'EMEA'\n";
	print $socket "\n";
	close($socket);
}
# Send to the old dev box
#do_send ("151.191.98.138");
# Send to the dev box
#do_send ("161.239.152.57");
do_send ("xstm5257dap.stm.swissbank.com");
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
	exit 0;


