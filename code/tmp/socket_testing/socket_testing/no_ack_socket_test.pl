#!/sbcimp/run/pd/perl/5.8.0/bin/perl -w
use IO::Socket;
#use strict;
use Getopt::Std;
use Socket

getopts('I:');

### Here we create all relevant variables ###

my $remote_host = "151.191.98.138" ;
#my $remote_host = "151.191.119.183" ;
#my $remote_host = "165.222.100.32" ;
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
$counter = 0;

#while ($counter < 10 ) {
        #my $socket = $sock.$counter;
my $socket = $sock;
my $time = time();
socket($socket, PF_INET, SOCK_STREAM,getprotobyname('tcp'));


        # build the address of the remote machine
$internet_addr = inet_aton($remote_host) or die "no convert $remote_host  $!\n";
$paddr = sockaddr_in($remote_port, $internet_addr);

        # connect
connect($socket, $paddr) or die "could not connect to $remote_host:remote_port : $!\n";

	# while we are connected send 9 events	
while ($counter < 1 ) {
	#print $socket "\n";
	print $socket "'Transport' 'SocketTestScript'\n";
	print $socket "'Severity' 'DEBUG'\n";
#	print $socket "'Severity' 'INFO'\n";
#	print $socket "'Severity' 'WARN'\n";
#	print $socket "'Severity' 'ERROR'\n";
#	print $socket "'Severity' 'FATAL'\n";
	print $socket "'Nodealias' 'WLDN0144847.develop.ubsw.net'\n";
	print $socket "'EventIdentifier' 'janesch'\n";
	print $socket "'SAPname' 'Socket_test'\n";
	print $socket "'Subclass' '20050816'\n";
	print $socket "'ClassID' '1057337'\n";
	print $socket "'MessageText' '12345 : Janesch Testing\n'\n"; 
	print $socket "'EventType' '1'\n";
	print $socket "'EventTime' '$time'\n";
	print $socket "'Component' 'MOM.AlertGroup'\n";
	print $socket "'Stream' 'a small river'\n";
	print $socket "'Location' 'Halkidiki'\n";
	print $socket "'Acknowledged' '0'\n";
	print $socket "'Owner' 'owensjo'\n";
#	print $socket "'Owner' 'brennara'\n";
	print $socket "'Chris' 'brennara'\n";
	print $socket "'Region' 'EMEA'\n";
	print $socket "\n";
        $counter++;
}
#print $socket "\n";
close($socket);
exit 0;

