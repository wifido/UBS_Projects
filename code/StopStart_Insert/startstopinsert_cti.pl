#!/usr/bin/perl
#or #!/sbclocal/bin/perl
#or #!/sbcimp/run/pd/perl

#############################################################################
#
#	stopstartinsert.pl
#
#	Initial		16th May 2007		Chris Janes
#	Release 1	29th May 2007		Chris Janes
#	Release 1.1	sometime		CTI
#		Added option to pick up an argument and us it as Hostname
#	Release 1.2	20080624		Chris Janes
#		Error checking added for above as supplying an incorrect
#		hostname caused un repored issues, also added the ability to 
#		specify hostname with the other arguments
#
#############################################################################


#############################################################################
#
#	Here we declare pragma
#
#############################################################################

use strict;


#############################################################################
#
#	Here we declare Librarys we need
#
#############################################################################

use Getopt::Std;
use IO::Socket;
use Socket;
use Time::Local;


#############################################################################
#
#	Here we declare the Global Variables
#
#############################################################################

use vars qw/ %opt /;

my $Debug;
my $EventTime;
my $EndTime;
my $Host;
my $Method;
my $PdhTime;
my $StartTime;
my $User;
my $Verbose;


#############################################################################
#
#	Here we put the sub routines
#
#############################################################################


sub usage()
{
#############################################################################
#
#	This sub shows usage when invokes by -h or incorrect usage
#
#############################################################################
	print "	This program does inserts a MicroMuse Event prior to a SSM installation\n";
	print " so as the new agent comming up does not look like a server recovering from\n";
	print " crash\n";
	print "	\n";
	print "	usage: $0 [-n host]\n";
	print "	\n";
	print "	-h          : this (help) message\n";
	print "	-n host     : the FQDN of the host to be put into StartStop\n";
	print "	            : if this option is omitted then the host name of the host running this script is used\n";
	print "	-D          : Puts the script into debug mode\n";
	print "	\n";
	print "	example: $0 -n xldn1052dap.ldn.swissbank.com\n";

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
	my @Hostname = <HOST>;
	close (HOST);
	unlink "/tmp/tmppdhhostname" or die "Cannot delete tmppdhhostname\n";
	my $Host =  (substr($Hostname[0], 0,length($Hostname[0])-1));

	system("domainname > /tmp/domainname");
	open (HOST,"/tmp/domainname")|| die "cannot open /tmp/domainname file";
	my @Hostname = <HOST>;
	close (HOST);
	unlink "/tmp/domainname" or die "Cannot delete domainname\n";
	my $Domain =  substr($Hostname[0], 0,length($Hostname[0])-1);
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


sub SendSocketEvent
{
#############################################################################
#
#	This sub send a netcool event to socket 2004 on host defined
#	in $remote_host.
#	the following global variable are required to be set
#		my $Host;		defines the host to be put into PDH
#
#############################################################################

	socket('TO_SERVER', PF_INET, SOCK_STREAM,getprotobyname('tcp'));
        # build the address of the remote machine
	my $internet_addr;
	my $remote_host;
	if(inet_aton($Host)
	{
		my $IP = inet_ntoa(inet_aton($Host));
	}
	else
	{
		die "Unable to resolve Hostname $Host\n";
	}

	if($IsDev)
	{
	# USE THIS BIT FOR DEV
	# Discover Which probe we can reach
		if (inet_aton("ldnskteng1.ldn.swissbank.com"))
		{
			if($Debug) {print "ldnskteng1\n";}
			$internet_addr = inet_aton("ldnskteng1.ldn.swissbank.com");
			$remote_host = "ldnskteng1";
			if($Debug) { print "$Host ($IP)\n"; }
		}
		else
		{
			print "Unable to Connect to a Netcool Socket Probe\n";
			print "Please contact sh-monitoring-support for assistance\n\n";
			return;

		}
	}
	else # Send to Prod
	{
		# Discover Which probe we can reach
		if (inet_aton("ldnsktprod1.ldn.swissbank.com"))
		{
			if($Debug) {print "ldnsktprod1\n";}
			$internet_addr = inet_aton("ldnsktprod1.ldn.swissbank.com");
			$remote_host = "ldnsktprod1";
		}
		elsif(inet_aton("zursktprod1.zur.swissbank.com"))
		{
			if($Debug) {print "zursktprod1\n";}
			$internet_addr = inet_aton("zursktprod1.zur.swissbank.com");
			$remote_host = "zursktprod1";
		}
		elsif(inet_aton("stmsktprod1.stm.swissbank.com"))
		{
			if($Debug) {print "stmsktprod1\n";}
			$internet_addr = inet_aton("stmsktprod1.stm.swissbank.com");
			$remote_host = "stmsktprod1";
		}
		elsif(inet_aton("sngsktprod1.sng.swissbank.com"))
		{
			if($Debug) {print "sngsktprod1\n";}
			$internet_addr = inet_aton("sngsktprod1.sng.swissbank.com");
			$remote_host = "sngsktprod1";
		}
		else
		{
			print "Unable to Connect to a Netcool Socket Probe\n";
			print "Please contact sh-monitoring-support for assistance\n\n";
			return;
		}
	}

	my $paddr = sockaddr_in(2004, $internet_addr);
        $EventTime = time();

        # connect
	connect(TO_SERVER, $paddr) or die "could not connect to $remote_host:remote_port : $!\n";

	# while we are connected send event
	print TO_SERVER "'Transport' 'StartStopinsertScript'\n";
	print TO_SERVER "'Severity' 'INFO'\n";
	print TO_SERVER "'Nodealias' '$Host'\n";
	print TO_SERVER "'Node' '$IP'\n";
	print TO_SERVER "'EventIdentifier' 'Agent'\n";
	print TO_SERVER "'ClassID' '124021'\n";
	print TO_SERVER "'MessageText' 'Agent Terminating on $Host (Remote Coldboot)'\n";
	print TO_SERVER "'EventType' '1'\n";
	print TO_SERVER "'EventTime' '$EventTime'\n";
	print TO_SERVER "'Component' 'StartStop'\n";
	print TO_SERVER "'Resolution' 'False'\n";
	print TO_SERVER "'Acknowledged' '0'\n";
	print TO_SERVER "\n";
	print TO_SERVER "\n";

	# close socket
	close(TO_SERVER);
}


#############################################################################
#############################################################################
#
#	This is where the code 'proper' starts
#
#############################################################################
#############################################################################



# get any command line arguements
getopts( "hDun:", \%opt ) or usage();


# are we in debug mode
if ($opt{D})
{
	$Debug = 1 ;
}

# do we want this to go to netcool dev for testing
if ($opt{u})
{
	$IsDev = 1 ;
}
else
{
	$IsDev = 0 ;
}
#	This bit added by CTI
if (defined($ARGV[0])) {
	$Host = $ARGV[0];
} else {
#End of CTI addon
	$Host = GetHostName();

#If a hostname is supplied as an arguement use it if not use local host
if ($opt{n})
{
	# Use hostname supplied
	$Host = $opt{n};
	if($Verbose) {print "Using Hostname Supplied\n";}
	if($Verbose) {print "Hostname             $Host\n";}
}
else
{
	# else use hostname of machine running this script
	$Host = GetHostName();
	if($Verbose) {print "Using Local Hostname\n";}
	if($Verbose) {print "Hostname             $Host\n";}
}


#	This bit added by CTI
}
#End of CTI addon

# if -h option used show usage
if ($opt{h})
{
	usage();
	exit 1;
}
else
{
	if($Debug) {print "Host      = $Host\n";}
	SendSocketEvent ;
}

# Done now so say goodbye nicely
exit 0;


