#!/sbcimp/run/pd/perl/5.8.0/bin/perl -w
use IO::Socket;
#use strict;
use Getopt::Std;
use Socket

getopts('I:');
sub doit{
### Here we create all relevant variables ###
#V7testing
#my $remote_host = "151.191.119.183" ;
my $remote_host = "139.149.52.156" ;
# Dev 9839
#my $remote_host = "151.191.98.138" ;
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
while ($counter < 5) {
	#print $socket "\n";
	print $socket "'Transport' 'SocketTestScript'\n";
#	print $socket "'Severity' 'DEBUG'\n";
	print $socket "'Severity' 'INFO'\n";
#	print $socket "'Severity' 'WARN'\n";
#	print $socket "'Severity' 'ERROR'\n";
#	print $socket "'Severity' 'FATAL'\n";
	print $socket "'Nodealias' 'WLDN0144847.develop.ubsw.net'\n";
	print $socket "'EventIdentifier' 'janesch$gcount'\n";
	print $socket "'SAPname' 'Socket_test'\n";
	print $socket "'Subclass' '20050916'\n";
	print $socket "'ClassID' '999991'\n";
	print $socket "'MessageText'MessageText this goes into Summary '\n'\n"; 
	print $socket "'EventType' '1'\n";
	print $socket "'EventTime' '$time'\n";
	print $socket "'Component' 'V7testing.AlertGroup'\n";
	print $socket "'Stream' 'a small river'\n";
	print $socket "'Location' 'Halkidiki'\n";
	print $socket "'ExpireTime' '55'\n";
	print $socket "'Acknowledged' '1'\n";
	print $socket "'Region' 'EMEA'\n";
	print $socket "\n";
        $counter++;
	$gcount++;
	}
#print $socket "\n";
close($socket);
}
$gcount = 0;

my $i = 0;
for (;;)
{
	$i = $i + 1;
	print "loop $i\n";
#	for ($count=0; $count < 10; $count = $count +1)
#	{
		doit;
#	}
	sleep 1;

}



