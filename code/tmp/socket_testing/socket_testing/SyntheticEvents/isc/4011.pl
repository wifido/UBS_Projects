#!/usr/bin/perl
#or #!/sbclocal/bin/perl
#or #!/sbcimp/run/pd/perl

#############################################################################
#
#	telnetcool.pl
#	This script is the property of the ITSM Monitoring Team
#	No Changes should be made directly to this script, should you require
#	please request this vi sh-monitoring-support
#
#	Initial		19th Oct 2007		Chris Janes
#	Beta 1		19th Oct 2007		Chris Janes
#	Beta 2		20th Dec 2007		Addin regional Probes
#						and Connection checking
#	Beta 2.0.1	21st Dec 2007		DMZ probes added
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

my $Debug;	# Flag to run in Debug mode
my $EventTime;	# Time of event
my $Host;	# Hostname of server running this script
my $Profile;	# Is used to select which probe rules to use
my $Verbose;	# Flag to run in Verbose mode - otherwise silent
my $UserData;	# Can be used to pass a string to the rules file
my $UserInt;	# Can be used to pass an Int to the rules file
my @ProbeOrder;	# The order that probes are tried



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
	print "	This program does inserts a MicroMuse Event dependent on Profile Parameter\n";
	print "	usage: $0 [-t time] [-f host]\n";
	print "	\n";
	print "	-h        	: this (help) message\n";
	print "	-V        	: verbose output\n";
	print "	-p profile   	: Determins the probe rules to be used\n";
	print "	-d data   	: Pass this data to the rules file\n";
	print "	-i int   	: Pass this int to the rules file\n";
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

sub SetProbeOrder
{
	my $Region = $_[0];
	$ProbeOrder[0] = "xstm5257dap.stm.swissbank.com";
	
	if($Debug) {print "ProbeOrder @ProbeOrder\n";}
}

sub GetRegion
{
	my $hostname = $_[0];
	my %RegionLookup;	# this is used to identify the region - it will default to being Switzerland

	%RegionLookup= (
	"chi" => "Americas",
	"ldn" => "EMEA",
	"mel" => "APAC",
	"nyc" => "Americas",
	"sng" => "APAC",
	"stm" => "Americas",
	"tky" => "APAC",
	);		
	my $Region = $RegionLookup{substr($hostname, 1, 3)};
	if(length($Region) == 0)
	{
		$Region = "Swiss"
	}
	if($Debug) {print "Region = $Region\n";}
	return ($Region);
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

	my $TargetProbe = $_[0];
	socket('TO_SERVER', PF_INET, SOCK_STREAM,getprotobyname('tcp'));
        # build the address of the remote machine
	my $internet_addr;
	my $remote_host;
	my $MessageConnected;
	
#	USE THIS BIT FOR DEV
#	# Discover Which probe we can reach
	if (inet_aton($TargetProbe)) 
	{
		if($Debug) {print "TargetProbe = $TargetProbe\n";}
		$internet_addr = inet_aton($TargetProbe);
#		$internet_addr = inet_aton("stmsktdev2.stm.swissbank.com");
		$remote_host = $TargetProbe;
	}

	if(length($internet_addr) > 0 )
	{
		my $paddr = sockaddr_in(2004, $internet_addr);
        	$EventTime = time();
		$MessageConnected = 1;
        	# connect
		connect(TO_SERVER, $paddr) or $MessageConnected = 0;
		if($MessageConnected == 1)
		{
			# while we are connected send event	
			print TO_SERVER "'Transport' 'Telnetcool'\n";
			print TO_SERVER "'Severity' 'INFO'\n";
			print TO_SERVER "'Nodealias' 'xzur1234dap.zur/swissbank.com'\n";
			print TO_SERVER "'Profile' '$Profile'\n";
			print TO_SERVER "'EventIdentifier' 'Agent'\n";
			print TO_SERVER "'ClassID' '2300007'\n";
			print TO_SERVER "'MessageText' 'This is a Test Event from a random zur DB Services box'\n"; 
			print TO_SERVER "'EventType' '1'\n";
			print TO_SERVER "'EventTime' '$EventTime'\n";
			print TO_SERVER "'Component' 'StartStop'\n";
			print TO_SERVER "'Resolution' 'False'\n";
			print TO_SERVER "'Acknowledged' '0'\n";
			print TO_SERVER "'UserData' '$UserData'\n";
			print TO_SERVER "'Class' '121000'\n";
			print TO_SERVER "'AlertKey' 'AlertKey'\n";
			print TO_SERVER "'AlertGroup' 'AlertGroup'\n";
			print TO_SERVER "'OwnerGID' '239'\n";
			print TO_SERVER "'Profile' 'Test'\n";
			print TO_SERVER "\n";
			print TO_SERVER "\n";
		
			# close socket
			close(TO_SERVER);
		}
	}
	else
	{
		$MessageConnected = 0;
		if($Debug) {print "Poor Address\n";}
	}
	return ($MessageConnected);
}


#############################################################################
#############################################################################
#
#	This is where the code 'proper' starts 
#
#############################################################################
#############################################################################



# get any command line arguements
getopts( "hDVp:d:i:", \%opt ) or usage();


# are we in debug mode
if ($opt{D})
{
	$Debug = 1 ;
}

if ($opt{V})
{
	$Verbose = 1 ;
}
if($Verbose) {print "\npdhinsert.pl running in Verbose Mode\n\n";}

	$Host = GetHostName();

#If a Profile is supplied as an arguement use it if not it will send NULL as $Profile
if ($opt{p})
{
	# Use Profile supplied
	$Profile = $opt{p};
	if($Verbose) {print "Using Profile Supplied\n";}
	if($Verbose) {print "Profile             $Profile\n";}
}


#If a UserInt is supplied as an arguement use it if not it will send NULL as $UserInt
if ($opt{i})
{
	# Use Profile supplied
	$UserInt = $opt{i};
	if($Verbose) {print "Using UserInt Supplied\n";}
	if($Verbose) {print "Profile             $UserInt\n";}
}

#If a UserData is supplied as an arguement use it if not it will send NULL as $UserDate
if ($opt{d})
{
	# Use UserData supplied
	$UserData = $opt{d};
	if($Verbose) {print "Using UserData Supplied\n";}
	if($Verbose) {print "UserData             $UserData\n";}
}


# if -h option used show usage
if ($opt{h})
{
	usage();
	exit 1;
}
else
{
	SetProbeOrder GetRegion $Host;
	if($Debug) {print "Host      = $Host\n";}
	my $MessageSent =0;
	foreach my $Probe (@ProbeOrder)
	{
		if($MessageSent == 0)
		{
			$MessageSent = SendSocketEvent ($Probe) ;
			print " Probe = $Probe    MessageSent = $MessageSent\n";
		}
	}
}

# Done now so say goodbye nicely
exit 0;



