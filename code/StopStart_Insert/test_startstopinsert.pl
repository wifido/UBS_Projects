#!/usr/bin/perl
#or #!/sbclocal/bin/perl
#or #!/sbcimp/run/pd/perl

#############################################################################
#
#	stopstartinsert.pl
#
#	Initial		16th May 2007		Chris Janes
#	Release 1	29th May 2007		Chris Janes
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
	
#	USE THIS BIT FOR DEV
#	# Discover Which probe we can reach
	if (inet_aton("stmsktdev1.stm.swissbank.com")) 
	{
		if($Debug) {print "stmsktdev1\n";}
		$internet_addr = inet_aton("stmsktdev1.stm.swissbank.com");
		$remote_host = "stmsktdev1";
	}

#	# Discover Which probe we can reach
#	if (inet_aton("ldnsktprod1.ldn.swissbank.com")) 
#	{
#		if($Debug) {print "ldnsktprod1\n";}
#		$internet_addr = inet_aton("ldnsktprod1.ldn.swissbank.com");
#		$remote_host = "ldnsktprod1";
#	}
#	elsif(inet_aton("zursktprod1.zur.swissbank.com"))
#	{
#		if($Debug) {print "zursktprod1\n";}
#		$internet_addr = inet_aton("zursktprod1.zur.swissbank.com");
#		$remote_host = "zursktprod1";
#	}
#	elsif(inet_aton("stmsktprod1.stm.swissbank.com"))
#	{
#		if($Debug) {print "stmsktprod1\n";}
#		$internet_addr = inet_aton("stmsktprod1.stm.swissbank.com");
#		$remote_host = "stmsktprod1";
#	}
#	elsif(inet_aton("sngsktprod1.sng.swissbank.com"))
#	{
#		if($Debug) {print "sngsktprod1\n";}
#		$internet_addr = inet_aton("sngsktprod1.sng.swissbank.com");
#		$remote_host = "sngsktprod1";
#	}
#	else
#	{
#		print "Unable to Connect to a Netcool Socket Probe\n";
#		print "Please contact sh-monitoring-support for assistance\n\n";
#		return;
#	}
#

	my $paddr = sockaddr_in(2004, $internet_addr);
        $EventTime = time();

        # connect
	connect(TO_SERVER, $paddr) or die "could not connect to $remote_host:remote_port : $!\n";
	
	# while we are connected send event	
	print TO_SERVER "'Transport' 'TestStartStopinsertScript'\n";
	print TO_SERVER "'Severity' 'INFO'\n";
	print TO_SERVER "'Nodealias' '$Host'\n";
	print TO_SERVER "'EventIdentifier' 'Agent'\n";
	print TO_SERVER "'ClassID' '999991'\n";
	print TO_SERVER "'MessageText' 'Test event for StartStop'\n"; 
	print TO_SERVER "'EventType' '2'\n";
	print TO_SERVER "'EventTime' '$EventTime'\n";
	print TO_SERVER "'Component' 'StartStop'\n";
	print TO_SERVER "'Resolution' 'True'\n";
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
getopts( "hD", \%opt ) or usage();


# are we in debug mode
if ($opt{D})
{
	$Debug = 1 ;
}

	$Host = GetHostName();



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



