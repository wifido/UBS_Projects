#!/usr/bin/perl
#or #!/sbclocal/bin/perl
#or #!/sbcimp/run/pd/perl

#############################################################################
#
#	pdhinsert.pl
#
#	Initial		24th April 2007		Chris Janes
#	Beta 1		26th April 2007		Chris Janes
#	Beta 2		3rd May 2007		Chris Janes
#			Modified to use various versions of perl and to work under 
#			Solaris (V8 and V10)
#	Beta 3		10th May 2007		Chris Janes
#			Modified to use Prod probes and to 'hunt to find a probe
#			Verbose operation implimented
#	Release 1	15th May 2007		Chris Janes
#	Release 1.1	29th May 2007		Chris Janes
#						Probe order changed
#	Release	1.2	13th March 2008		Chris Janes
#						-c option added for comments
#						-u option added to send insert to dev
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
my $NullUser;
my $Comment;
my $IsDev;

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
	print "	This program does...\n";
	print "	\n";
	print "	usage: $0 [-t time] [-f host]\n";
	print "	\n";
	print "	-h          : this (help) message\n";
	print "	-v          : verbose output\n";
	print "	-d          : Put into PDH as a De-commissioned  host\n";
	print "             :	this overrides any other switches\n";
	print "	-s date     : the time the host will be put into PDH (yyyy:mm:dd:hh:mm)\n";
	print "	            : if this option is omitted then it is assumes to be now \n";
	print "	-t time     : the time the host is left in PDH in minutes\n";
	print "	            : if this option is omitted then it is assumes to be 0 \n";
	print "	            : this will effectivly take the host out of PDH \n";
	print "	-n host     : the FQDN of the host to be put into PDH\n";
	print "	            : if this option is omitted then the host name of the host running this script is used\n";
	print "	-D          : Puts the script into debug mode\n";
	print " -c comment  : Adds a connent to the PDH Table\n";
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

sub ParseDateTimeString
{
#############################################################################
#
#	This sub returns the epock if date time string is valid 0 otherwise
#
#############################################################################
	my $TestString = $_[0];
	my $return = 0;
	my $ParseFail = 0;
	if ($TestString =~ m/[0-9]+:[0-9]+:[0-9]+:[0-9]+:[0-9]+/)
	{
		if($Debug) {print "Doing ParseDateTimeString TestString is $TestString\n";}
		my @DateArray = split/:/,$TestString;
		if (($DateArray[0] < 2007)||($DateArray[0] >2020))
		{
			$ParseFail = 1;
			if($Debug) {print "ParseDateTimeString failed on Year\n";}
		}
		if (($DateArray[1] < 1)||($DateArray[1] >12))
		{
			$ParseFail = 1;
			if($Debug) {print "ParseDateTimeString failed on Month\n";}
		}
		if (($DateArray[2] < 1)||($DateArray[2] >31))
		{
			$ParseFail = 1;
			if($Debug) {print "ParseDateTimeString failed on Day\n";}
		}
		if (($DateArray[3] < 0)||($DateArray[3] >23))
		{
			$ParseFail = 1;
			if($Debug) {print "ParseDateTimeString failed on Hour\n";}
		}
		if (($DateArray[4] < 0)||($DateArray[4] >59))
		{
			$ParseFail = 1;
			if($Debug) {print "ParseDateTimeString failed on Min\n";}
		}
		
		if ($ParseFail == 0)
		{
#			$return = 2;
			$return = timegm(0,$DateArray[4],$DateArray[3],$DateArray[2],$DateArray[1] - 1,$DateArray[0] - 1900);
		}
		else
		{
			$return = 0;
		}
	}
	else
	{
		$return = 0;
	}
}

sub SendSocketEvent
{
#############################################################################
#
#	This sub send a netcool event to socket 2004 on host defined 
#	in $remote_host.
#	the following global variable are required to be set
#		my $Host;		defines the host to be put into PDH
#		my $EventTime;		the time the event is sent
#		my $User;		the user who is making this request
#		my $StartTime;		the time that the host is put into pdh 
#		my $EndTime;		the time that the host is teken out of pdh
#		my $Comment		comment for this pdh entry
#
#############################################################################

	socket('TO_SERVER', PF_INET, SOCK_STREAM,getprotobyname('tcp'));
        # build the address of the remote machine
	my $internet_addr;
	my $remote_host;
	
	#Do we want the insert to go to netcool dev
	if($IsDev)
	{
		# Discover Which DEV probe we can reach
		if (inet_aton("stmsktdev1.stm.swissbank.com")) 
		{
			if($Debug) {print "stmsktdev1\n";}
			$internet_addr = inet_aton("stmsktdev1.stm.swissbank.com");
			$remote_host = "stmsktdev1";
			if($Verbose) {print "Micromuse Event sent to $remote_host\n\n";}
		}
		else
		{
			print "Unable to Connect to a Netcool Socket Probe\n";
			print "Please contact sh-monitoring-support for assistance\n\n";
			return;
		}
	}
	else
	{
		# Discover Which Prod probe we can reach
		if (inet_aton("zursktprod1.zur.swissbank.com")) 
		{
			if($Debug) {print "zursktprod1\n";}
			$internet_addr = inet_aton("zursktprod1.zur.swissbank.com");
			$remote_host = "zursktprod1";
			if($Verbose) {print "Micromuse Event sent to $remote_host\n\n";}
		}
		elsif(inet_aton("sngsktprod1.sng.swissbank.com"))
		{
			if($Debug) {print "sngsktprod1\n";}
			$internet_addr = inet_aton("sngsktprod1.sng.swissbank.com");
			$remote_host = "sngsktprod1";
			if($Verbose) {print "Micromuse Event sent to $remote_host\n\n";}
		}
		elsif(inet_aton("stmsktprod1.stm.swissbank.com"))
		{
			if($Debug) {print "stmsktprod1\n";}
			$internet_addr = inet_aton("stmsktprod1.stm.swissbank.com");
			$remote_host = "stmsktprod1";
			if($Verbose) {print "Micromuse Event sent to $remote_host\n\n";}
		}
		elsif(inet_aton("ldnsktprod1.ldn.swissbank.com"))
		{
			if($Debug) {print "ldnsktprod1\n";}
			$internet_addr = inet_aton("ldnsktprod1.ldn.swissbank.com");
			$remote_host = "ldnsktprod1";
			if($Verbose) {print "Micromuse Event sent to $remote_host\n\n";}
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
	print TO_SERVER "'Transport' 'PDHinsertScript'\n";
	print TO_SERVER "'Severity' 'INFO'\n";
	print TO_SERVER "'Nodealias' '$Host'\n";
	print TO_SERVER "'EventIdentifier' 'EventID'\n";
	print TO_SERVER "'ClassID' '1640'\n";
	print TO_SERVER "'MessageText' 'PDH Insert Event'\n"; 
	print TO_SERVER "'EventType' '1'\n";
	print TO_SERVER "'EventTime' '$EventTime'\n";
	print TO_SERVER "'Component' 'Socket'\n";
	print TO_SERVER "'Resolution' 'False'\n";
	print TO_SERVER "'Location' 'Location'\n";
	print TO_SERVER "'Userdata' '$User'\n";
	print TO_SERVER "'Userdata2' '$Comment'\n";
	print TO_SERVER "'Userint1' '$Method'\n";
	print TO_SERVER "'Acknowledged' '0'\n";
	print TO_SERVER "'Region' 'EMEA'\n";
	print TO_SERVER "'StartTime' '$StartTime'\n";
	print TO_SERVER "'EndTime' '$EndTime'\n";
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
getopts( "hvudn:t:s:DZc:", \%opt ) or usage();

# are we in verbose mode
if ($opt{v})
{
	$Verbose = 1 ;
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



if($Verbose) {print "\npdhinsert.pl running in Verbose Mode\n\n";}
if ($opt{Z})
{
	$NullUser = 1 ;
}
if($Verbose) {print "\nUser to ne nulled\n\n";}

# are we in debug mode
if ($opt{D})
{
	$Debug = 1 ;
}

#If a comment is supplied as an arguement use it if not use local host
if ($opt{c})
{
	# Use comment supplied
	$Comment = $opt{c};
	if($Verbose) {print "Using Comment Supplied\n";}
	if($Verbose) {print "Comment             $Comment\n";}
}
else
{
	$Comment = "UBS_PDH_Insert trigger";
}

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


# is a start time supplied if not use 'now'
if ($opt{s})
{
	# Use StartTime supplied
	my $STime = $opt{s};
	$StartTime = ParseDateTimeString($STime);
	if($Debug) {print "Start Time = $StartTime\n";}
	if ($StartTime)
	{
		if($Debug) {print "Start Time is Good\n";}
	}
	else
	{
		if($Debug) {print "Start Time is BAD using current time\n";}
		if($Verbose) {print "The supplied Start Time did not parse fall back to usin 'now' as Start Time\n";}
		$StartTime = time();
	}
		
}
else
{
	# else use time of machine running this script (in utc)
	$StartTime = time();
}

$User = GetUserName();
if($NullUser){$User = "";}
if($Verbose) {print "Username             $User\n";}

# if -h option used show usage
if ($opt{h})
{
	usage();
	exit 1;
}
elsif ($opt{d})
{
	#	The host is to be Decom'd
	$Method = 201;
	$EndTime = 1735254000;
	SendSocketEvent ;
	if($Verbose) {print "This Host is to be entered into PDH as Decom'd\n";}
}
else
{
	$Method = 101;
	# if arguement for time is passed
	if ($opt{t})
	{
		# Convert to seconds
		$PdhTime = $opt{t} * 60;
	}
	else
	{
		# if no arguement for time set it to 0 - this will take the host out of PDH
		$PdhTime = 0;
	}
	
	#starttime is now in utc for this application
	my $StartTm = gmtime($StartTime);
	if($Verbose) {print "Start Time           $StartTm\n";}
	# endtime is now + the supplied interval
	$EndTime = $StartTime + $PdhTime;
	my $EndTm = gmtime($EndTime);
	if($Verbose) {print "End Time             $EndTm\n";}
	
	if($Debug) {print "StartTime = $StartTime ($StartTm UTC) \nEndTime   = $EndTime ($EndTm UTC)  \nUser      = $User   \nHost      = $Host\n";}
	 
	SendSocketEvent ;
}

# Done now so say goodbye nicely
exit 0;



