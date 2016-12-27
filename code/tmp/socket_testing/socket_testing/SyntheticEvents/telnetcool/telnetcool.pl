#!/sbcimp/run/pd/perl/5.8.7/bin/perl -w
use IO::Socket;
#use strict;
use Getopt::Std;
use Socket;



sub usage()
{
#############################################################################
#
#	This sub shows usage when invokes by -h or incorrect usage
#
#############################################################################
	print "	This program does...\n";
	print "	\n";
	print "	usage: $0 [-t time] [-f host]\n";
	print "	\n";
	print "	-h          	: this (help) message\n";
	print "	-n NodeAlias	: set NodeAlias\n";
	print "	-c Class        : set Class\n";
	print "	-g Group        : set OwnerGID\n";
	print "	-d Domain       : set Domain\n";
	print "	\n";
	print "	example: $0 -t 999 -n xldn1052dap.ldn.swissbank.com\n";
}

sub GetHostName
{
#############################################################################
#
#	This sub returns the FQDN of the host on which this script is running
#
#############################################################################
	system("uname -n | cut -f1 -d. > /tmp/tmppdhhostname");
	open (HOST,"/tmp/tmppdhhostname")|| die "cannot open /tmp/tmppdhhostname file";
	my @HostName = <HOST>;	
	close (HOST);
	unlink "/tmp/tmppdhhostname" or die "Cannot delete tmppdhhostname\n";
	my $Host =  (substr($HostName[0], 0,length($HostName[0])-1));
	
	system("domainname > /tmp/domainname");
	open (HOST,"/tmp/domainname")|| die "cannot open /tmp/domainname file";
	@HostName = <HOST>;	
	close (HOST);
	unlink "/tmp/domainname" or die "Cannot delete domainname\n";
	my $Domain =  substr($HostName[0], 0,length($HostName[0])-1);
	my $Return = $Host ."." . $Domain;
	return  $Return;

}

sub GetUserName
{
############################################################################
#
#	This sub returns the name of the user running this script
#
#############################################################################
	system("who am i > /tmp/tmppdhusername");
	open (USER,"/tmp/tmppdhusername")|| die "cannot open /tmp/tmppdhusername file";
	my @Username = <USER>;	
	close (USER);
	unlink "/tmp/tmppdhusername" or die "Cannot delete tmppdhusername\n";
	my @UserArray = split/ /,$Username[0];
	return $UserArray[0];
}


sub SendEvent
{
	### Here we create all relevant variables ###
	# Dev 9839
	my $remote_host = "xstm5257dap.stm.swissbank.com" ;
#	my $remote_host = "xldn1014pap.ldn.swissbank.com" ;
	##LDN ENG 1052
	#my $remote_host = "139.149.52.156" ;
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
	#	print $socket "'Transport' 'SocketTestScript'\n";
	#	print $socket "'Severity' 'DEBUG'\n";
	#	print $socket "'Severity' 'INFO'\n";
	#	print $socket "'Severity' 'WARN'\n";
	#	print $socket "'Severity' 'ERROR'\n";
	#	print $socket "'Severity' 'FATAL'\n";
#		print $socket "'Nodealias' 'xldn1052dap.ldn.swissbank.com'\n";
		print $socket "'Nodealias' '$nodealias'\n";
		print $socket "'OwnerGID' '$group'\n";
		print $socket "'Class' '$class'\n";
	#	print $socket "'Subclass' '#default:SubClass'\n";
		print $socket "'ClassID' '2300007'\n";
	#	print $socket "'MessageText' 'AEN Test Event Sev 4'\n"; 
	#	print $socket "'EventType' '1'\n";
	#	print $socket "'EventTime' '$time'\n";
	#	print $socket "'Component' 'Component'\n";
	#	print $socket "'Stream' 'Stream'\n";
	#	print $socket "'Resolution' 'False'\n";
	#	print $socket "'Location' 'Location'\n";
	#	print $socket "'Userdata' 'Userdata'\n";
	#	print $socket "'Acknowledged' '0'\n";
	#	print $socket "'Region' 'EMEA'\n";
		print $socket "'Profile' 'Test'\n";
		print $socket "'AlertKey' '\\\\DSTMC023PN1\\NY_EQRES_03\$'\n";
		print $socket "\n";
	        $counter++;
	}
	#print $socket "\n";
	close($socket);
}
# get any command line arguements
getopts( "n:c:g:h", \%opt ) or usage();


if ($opt{n})
{
	$nodealias = $opt{n};
}
else
{
	$nodealias =  GetHostName;
}

if ($opt{d})
{
	$Domain = $opt{d};
}
else
{
	$Domain =  "Domain not Set";
}

if ($opt{g})
{
	$group = $opt{g};
}
else
{
	$group =  591;
}

if ($opt{c})
{
	$class = $opt{c};
}
else
{
	$class =  999999;
}

if ($opt{h})
{
	usage;
}
else
{
	print "nodealias = $nodealias  group = $group  class = $class\n";
	SendEvent;
}




exit 0;

