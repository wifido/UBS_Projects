#!/sbcimp/run/pd/perl/prod/bin/perl -w

####!/sbclocal/netcool/omnibus/utils/perllib/MUSE_PERL_PROD/bin/perl -w

#############################################################################
#
#	LicAudit.pl
#
#	Initial		8th April 2008		Chris Janes
#
#############################################################################

BEGIN  {
    use Net::Domain qw(hostname hostfqdn);
    $ENV{ ORACLE_HOME } = "/sbcimp/run/tp/oracle/client/v9.2.0.4.0-32bit";
    $ENV{ TNS_ADMIN   } = "/sbcimp/run/pkgs/oracle/config";
    $ENV{LANG} = "C";
    $ENV{OMNIHOME} = qw(/sbclocal/netcool/omnibus);
    $ENV{SYBASE} = "$ENV{OMNIHOME}/platform/solaris2" if $^O eq "solaris";
    $ENV{SYBASE} = qw(/sbcimp/run/tp/sybase/OpenClientServer/v12.5) if $^O eq "linux";
    $ENV{SYBASE_OCS} = q(OCS-12_5) if $^O eq "linux";
}

#############################################################################
#
#	Here we declare pragma
#
#############################################################################

#use strict;


#############################################################################
#
#	Here we declare Librarys we need
#
#############################################################################

use lib "/sbcimp/run/pd/cpan/5.8.5-2004.09/lib";

use Getopt::Std;
use IO::Socket;
use Socket;
use Time::Local;
use Proc::ProcessTable;
use DBI;
use DBD::Sybase;

#############################################################################
#
#	Here we declare the Global Variables
#
#############################################################################

use vars qw/ %opt /;
our $Host;
our $LogDir = "/sbclocal/netcool/omnibus/log/";
our @NotRecognised;
our @Lookup;

our %ProdLicence;
our %DevLicence;
our %LicUsed;
our %ProdLicUsed;
our %DevLicUsed;
our $dbh;


my $LenString;
my $Process;
my $Hostname;
my @tempArray;
my $LicCount;
#my $ReportTime = localtime time;
my $ReportTime = gmtime time;
my $time = time();

my $CreateHTML = 1;
my $CreateOracle = 1;
my $CreateEvent = 1;

my @ErrorArray = ();
my @TimeArray =();


#############################################################################
#
#	Here we load the Chris's Library of sub routines
#
#############################################################################

sub GetLibs
{
	if ( -r $ChrisLib ) 
	{ 
		do "$ChrisLib"; 
	} 
	else 
	{ 
		print "Unable to read $ChrisLib\n"; 
	}
} 



#############################################################################
#
#	Here we put the sub routines
#
#############################################################################


sub ProdVars
{
	if ($Verbose){print "Picking up Prod Vars\n";}
	our $ChrisLib = "/sbclocal/netcool/omnibus/utils/LicAudit2/Library.plinc";
	our $DataFile = "/sbclocal/netcool/omnibus/utils/LicAudit2/LicAudit2.data";
	our $ProdLicFile = "/sbclocal/netcool/omnibus/utils/LicAudit2/lics.data";
	our $DevLicFile = "/sbclocal/netcool/omnibus/utils/LicAudit2/lics.data";
	our $TargetPage = "/sbclocal/apache/muse/htdocs/janesch/licaudit.html";
	our $LogDir = "/sbclocal/netcool/omnibus/log/";
	our $ShellScript = "/sbclocal/netcool/omnibus/utils/LicAudit2/LicAudit2.ksh";
	our $LIB_Socket_Probe = "xldn1014pap.ldn.swissbank.com";
	our $ConnectString = "dbi:Oracle:database=MMLDNP1;HOST=139.149.33.108;PORT=1525;SID=MMLDNP1";
#	our $ConnectString = "dbi:Oracle:database=MMLDNP2;HOST=14.64.43.42;PORT=1522;SID=MMLDNP2";
}

sub DevVars
{
	if ($Verbose){print "Picking up Dev Vars\n";}
	our $ChrisLib = "/home/janesch/perl/Library/Library.plinc";
	our $DataFile = "/home/janesch/perl/LicAudit2/LicAudit2.data";
	our $ProdLicFile = "/home/janesch/perl/LicAudit2/lics.data";
	our $DevLicFile = "/home/janesch/perl/LicAudit2/lics.data";
	our $TargetPage = "/home/janesch/perl/LicAudit2/licaudit.html";
	our $LogDir = "/home/janesch/perl/LicAudit2/";
	our $ShellScript = "/home/janesch/perl/LicAudit2/LicAudit2.ksh";
	our $LIB_Socket_Probe = "xstm5257dap.stm.swissbank.com";
	our $ConnectString = "dbi:Oracle:database=MMLDNP2;HOST=14.64.43.42;PORT=1522;SID=MMLDNP2";
}

sub usage()
{
#############################################################################
#
#	This sub shows usage when invokes by -h or incorrect usage
#
#############################################################################
	print "	This program does...\n";
	print "	\n";
	print "	usage: $0 Dvd [-f host]\n";
	print "	\n";
	print "	-h          : this (help) message\n";
	print "	-d          : Runs in a development environment\n";
	print "	-v          : verbode Mode\n";
	print "	-D          : Debug Mode\n";
	print "	\n";
	print "	example: $0 \n";
}

sub OracleWrite
{
	my $Process = $_[0];
	my $LicOwned = $_[1];
	my $LicUsed = $_[2];
	my $Environment = $_[3];
	
	
	$dbh = DBI->connect( "$ConnectString",
                        "reporter",
                        "reporter",
                        {
                            RaiseError => 1,
                            AutoCommit => 1
                        }
                       ) || die "Database connection not made: $DBI::errstr";
                       
	my $sthOracle = $dbh->prepare("insert into reporter.netcool_lic_audit (autoinc, process, lic_owned, lic_used, audit_date, environment) values (reporter.licaudit.nextval, '$Process', $LicOwned, $LicUsed, to_date('$ReportTime','DY MON DD HH24:MI:SS YYYY'), '$Environment') ") || die $dbh->errstr;

	$sthOracle->execute() || die $sthOracle->errstr;
              
	$sthOracle->finish;
	$dbh->disconnect();
}
	
sub ReadData
{
	#
	#	Read in the Data file
	#
	open (LOOKUP,"$LookupFile")|| die "cannot open $LookupFile file";
	my @ReadIn = <LOOKUP>;	
	close (LOOKUP);
	
	foreach my $Line (@ReadIn)
	{
		$LenString = length ($Line);
		if(($Line =~ m/^-------/) or ($Line =~ m/DEAD/) or ($Line =~ m/^=========/) or ($Line =~ 	m/^Service Name/) or ($LenString <= 2))
		{
			# Do nothing
		}
		else
		{
			$Process = uc(substr($Line, 21,21));
			$Hostname = substr($Line, 42,11);
			if ($Process =~ m/^...OBJ/)
			{
				if (exists($LicUsed{OBJECTSERVERS}))
				{
					$LicUsed{OBJECTSERVERS} = $LicUsed{OBJECTSERVERS} + 1;
				}
				else
				{
					$LicUsed{OBJECTSERVERS} = 1;
				}
			}
			elsif (($Process =~ m/^BG/) or ($Process =~ m/^FG/) or ($Process =~ m/^NG/) or (	$Process =~ m/^HG/))
			{
				if (exists($LicUsed{BIGATE}))
				{
					$LicUsed{BIGATE} = $LicUsed{BIGATE} + 1;
				}
				else
				{
					$LicUsed{BIGATE} = 1;
				}
			}
			elsif (($Process =~ m/^UG/) or ($Process =~ m/^UNI/) )
			{
				if (exists($LicUsed{UNIGATE}))
				{
					$LicUsed{UNIGATE} = $LicUsed{UNIGATE} + 1;
				}
				else
				{
					$LicUsed{UNIGATE} = 1;
				}
			}
			elsif (($Process =~ m/^PROCMON/) )
			{
				if (exists($LicUsed{PROCMON}))
				{
					$LicUsed{PROCMON} = $LicUsed{PROCMON} + 1;
				}
				else
				{
					$LicUsed{PROCMON} = 1;
				}
			}
			elsif (($Process =~ m/^SSM_MTTRAPD/) or ($Process =~ m/^MTTRAPD/) or ($Process =~ 	m/^SSM_Mttrapd/ ))
			{
				if (exists($LicUsed{MTTRAPD}))
				{
					$LicUsed{MTTRAPD} = $LicUsed{MTTRAPD} + 1;
				}
				else
				{
					$LicUsed{MTTRAPD} = 1;
				}
			}
			elsif (($Process =~ m/^SOCKET/) )
			{
				if (exists($LicUsed{SOCKET}))
				{
					$LicUsed{SOCKET} = $LicUsed{SOCKET} + 1;
				}
				else
				{
					$LicUsed{SOCKET} = 1;
				}
			}
			elsif (($Process =~ m/^WEBTOP/) or ($Process =~ m/^Webtop/) or ($Process =~ 	m	/^...WEBTOP/) )
			{
				if (exists($LicUsed{WEBTOP}))
				{
					$LicUsed{WEBTOP} = $LicUsed{WEBTOP} + 1;
				}
				else
				{
					$LicUsed{WEBTOP} = 1;
				}
			}
			elsif (($Process =~ m/^SNMP_M/) or ($Process =~ m/^HTTP_M/) or ($Process =~ m/^HTTPS_M/) or ($Process =~ m/^TCPPORT_M/) or ($Process =~ m/^TRANSX_M/))
			{
				if (exists($LicUsed{ISM_MONITOR}))
				{
					$LicUsed{ISM_MONITOR} = $LicUsed{ISM_MONITOR} + 1;
				}
				else
				{
					$LicUsed{ISM_MONITOR} = 1;
				}
			}
			elsif (($Process =~ m/^DATA_BRIDGE/) )
			{
				if (exists($LicUsed{DATA_BRIDGE}))
				{
					$LicUsed{DATA_BRIDGE} = $LicUsed{DATA_BRIDGE} + 1;
				}
				else
				{
					$LicUsed{DATA_BRIDGE} = 1;
				}
			}
			elsif (($Process =~ m/^ISM_S/) )
			{
				if (exists($LicUsed{ISM_SERVER}))
				{
					$LicUsed{ISM_SERVER} = $LicUsed{ISM_SERVER} + 1;
				}
				else
				{
					$LicUsed{ISM_SERVER} = 1;
				}
			}
			elsif (($Process =~ m/^IMPACT/) )
			{
				if (exists($LicUsed{IMPACT}))
				{
					$LicUsed{IMPACT} = $LicUsed{IMPACT} + 1;
				}
				else
				{
					$LicUsed{IMPACT} = 1;
				}
			}
			elsif (($Process =~ m/^JREXEC/))
			{
				if (exists($LicUsed{JREXEC}))
				{
					$LicUsed{JREXEC} = $LicUsed{JREXEC} + 1;
				}
				else
				{
					$LicUsed{JREXEC} = 1;
				}
			}
			elsif (($Process =~ m/^SECURITY/) )
			{
				if (exists($LicUsed{SECURITY}))
				{
					$LicUsed{SECURITY} = $LicUsed{SECURITY} + 1;
				}
				else
				{
					$LicUsed{SECURITY} = 1;
				}
			}
			elsif (($Process =~ m/^CLUSTER_SYNC/) )
			{
				if (exists($LicUsed{CLUSTER_SYNC}))
				{
					$LicUsed{CLUSTER_SYNC} = $LicUsed{CLUSTER_SYNC} + 1;
				}
				else
				{
					$LicUsed{CLUSTER_SYNC} = 1;
				}
			}
			elsif (($Process =~ m/^DECOUPLER/) )
			{
				if (exists($LicUsed{DECOUPLER}))
				{
					$LicUsed{DECOUPLER} = $LicUsed{DECOUPLER} + 1;
				}
				else
				{
					$LicUsed{DECOUPLER} = 1;
				}
			}
			elsif (($Process =~ m/^MONITOR_BOT/) )
			{
				if (exists($LicUsed{MONITOR_BOT}))
				{
					$LicUsed{MONITOR_BOT} = $LicUsed{MONITOR_BOT} + 1;
				}
				else
				{
					$LicUsed{MONITOR_BOT} = 1;
				}
			}
			elsif (($Process =~ m/^MUSEBOT/) )
			{
				if (exists($LicUsed{MUSEBOT}))
				{
					$LicUsed{MUSEBOT} = $LicUsed{MUSEBOT} + 1;
				}
				else
				{
					$LicUsed{MUSEBOT} = 1;
				}
			}
			elsif (($Process =~ m/^ORACLE_GATE/) )
			{
				if (exists($LicUsed{ORACLE_GATE}))
				{
					$LicUsed{ORACLE_GATE} = $LicUsed{ORACLE_GATE} + 1;
				}
				else
				{
					$LicUsed{ORACLE_GATE} = 1;
				}
			}
			elsif (($Process =~ m/^G_REM_/) )
			{
				if (exists($LicUsed{REMEDY_GATE}))
				{
				$LicUsed{REMEDY_GATE} = $LicUsed{REMEDY_GATE} + 1;
				}
				else
				{
					$LicUsed{REMEDY_GATE} = 1;
				}
			}
			elsif (($Process =~ m/^PEM/) )
			{
				if ($Verbose){print "Discarding $Process $Hostname \n";}
			}
			else
			{
				if ($Verbose){print "$Process being included\n";}
				if (exists($LicUsed{$Process}))
				{
					$LicUsed{$Process} = $LicUsed{$Process} + 1;
				}
				else
				{
					$LicUsed{$Process} = 1;
				}
			}
		}
	}
}	


#############################################################################
#############################################################################
#
#	This is where the code 'proper' starts 
#
#############################################################################
#############################################################################


# get any command line arguements
getopts( "vdDh", \%opt ) or usage();

# App started with -h
if ($opt{h})
{
	usage();
	exit;
}

# are we in verbose mode
if ($opt{v})
{
	$Verbose = 1 ;
}
# do we want this to go to netcool dev for testing
if ($opt{d})
{
	$IsDev = 1 ;
	DevVars();
}
else
{
	$IsDev = 0 ;
	ProdVars();
}

# are we in debug mode
if ($opt{D})
{
	$Debug = 1 ;
}
else
{
	$Debug = 0 ;
}


#	Load Chris's Lib
GetLibs();

logit("$0 Starting");



#	Get Prod Licence Usage

##	Initialise Hash
%LicUsed = ();

##	Get PA Data
if  ($Debug =~ m/0/){system("$ShellScript -p");}
$LookupFile = "LicAudit2Prod.data";

##	Read the data into Hash
ReadData();
%ProdLicUsed = %LicUsed;


#	Get Dev Licence Usage

##	Initialise Hash
%LicUsed = ();

##	Get PA Data
if  ($Debug =~ m/0/){system("$ShellScript -d");}
$LookupFile = "LicAudit2Dev.data";

##	Read the data into Hash
ReadData();
%DevLicUsed = %LicUsed;


# Get Licence numbers - Prod
open (LIC,"$ProdLicFile")|| die "cannot open $ProdLicFile file";
@ReadIn = <LIC>;	
close (LIC);
foreach $Line (@ReadIn)
{
	@tempArray = split(/,/, $Line);
	$ProdLicence{$tempArray[0]} = $tempArray[1];
}

# Get Licence numbers - Dev
open (LIC,"$DevLicFile")|| die "cannot open $LookupFile file";
@ReadIn = <LIC>;	
close (LIC);
foreach $Line (@ReadIn)
{
	@tempArray = split(/,/, $Line);
	$DevLicence{$tempArray[0]} = $tempArray[1];
}

# 	If verbose print results to screen
if ($Verbose)
{
	print "Prod Licence Data\n\n";
	foreach $key (sort keys %ProdLicUsed)
	{
		if (exists($ProdLicence{$key}))
		{
			$LicCount = $ProdLicence{$key};
		}
		else
		{
			$LicCount = 0;
		}
		if (exists($ProdLicUsed{$key}))
		{
			$LicCountUsed = $ProdLicUsed{$key};
		}
		else
		{
			$LicCountUsed = 0;
		}
		
		print "$LicCountUsed $key ($LicCount)\n";
	}


	print "\n\n\n Dev Licence Data\n\n";
	foreach $key (sort keys %DevLicUsed)
	{
		if (exists($DevLicence{$key}))
		{
			$LicCount = $DevLicence{$key};
		}
		else
		{
			$LicCount = 0;
		}
		if (exists($DevLicUsed{$key}))
		{
			$LicCountUsed = $DevLicUsed{$key};
		}
		else
		{
			$LicCountUsed = 0;
		}
		print "$LicCountUsed $key ($LicCount)\n";
	}

}

if($CreateHTML)
{
	# This is where we create the main html page

	##	Open form
	$PCOUNT_FORM=$TargetPage;
	open (PFORM, ">$PCOUNT_FORM");
	
	##	Header Info
	print PFORM "<html lang=\"en\">\n";
	print PFORM "<head>\n";
	print PFORM "<title>Monitoring | Netcool Licences</title>\n";
	print PFORM "<LINK REL=\"stylesheet\" HREF=\"../css/mm.css\" TYPE=\"text/css\">";
	print PFORM "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=iso-8859-1\">\n";
	print PFORM "<link REL=\"stylesheet\" HREF=\"/gemm.css\" TYPE=\"text/css\">\n";
	print PFORM "</head>\n";
	
	##	Body info
	print PFORM "<body><small>\n";
	print PFORM "<h1><center> Netcool Licence Monitoring </center></H1>";
	print PFORM "<table width=\"100%\"> <tr> <td width=\"45%\">\n";
	
	##	Create Table for Prod details
	print PFORM "<table border=\"1\" >\n";
	print PFORM "<CAPTION>Production</CAPTION>\n";
	###	Header for table
	print PFORM "<TR><td> Process </td><td> Instances </td><td> Licences </td><td> Status </td>\n";
	###	Body for table create each Line
		foreach $key (sort keys %ProdLicUsed)
		{
	####	Get no of Lic owned
			if (exists($ProdLicence{$key}))
			{
				$LicCount = $ProdLicence{$key};
			}
			else
			{
				$LicCount = 0;
			}
	####	Get No Lics used
			if (exists($ProdLicUsed{$key}))
			{
				$LicCountUsed = $ProdLicUsed{$key};
			}
			else
			{
				$LicCountUsed = 0;
			}
	
	####	Create Status of Line
			if ($LicCount == "0")
			{
				$Status = "Not Licenced";
				$BGColour = "yellow";
			}
			elsif ( $LicCountUsed > $LicCount)
			{
				$Status = "Licence Exceded";
				$BGColour = "red";
			}
			else
			{
				$Status = "Licence OK";
				$BGColour = "chartreuse";
			}
			print PFORM "<TR><td>$key</td><td>$LicCountUsed</td><td>$LicCount</td><td bgcolor=\"$BGColour\">$Status</td></TR>\n";		
		}
	
	print PFORM "</table>\n";
	
	print PFORM "</td><td></td><td width=\"45%\">\n";
	
	
	# Dev table
	print PFORM "<table border=\"1\" >\n";
	print PFORM "<CAPTION>Development</CAPTION>\n";
	print PFORM "<TR><td> Process </td><td> Instances </td><td> Licences </td><td> Status </td>\n";
	
		foreach $key (sort keys %DevLicUsed)
		{
	####	Get no of Lic owned
			if (exists($DevLicence{$key}))
			{
				$LicCount = $DevLicence{$key};
			}
			else
			{
				$LicCount = 0;
			}
	####	Get No Lics used
			if (exists($DevLicUsed{$key}))
			{
				$LicCountUsed = $DevLicUsed{$key};
			}
			else
			{
				$LicCountUsed = 0;
			}
	
	####	Create Status of Line
			if ($LicCount == "0")
			{
				$Status = "Not Licenced";
				$BGColour = "yellow";
			}
			elsif ( $LicCountUsed > $LicCount)
			{
				$Status = "Licence Exceded";
				$BGColour = "red";
			}
			else
			{
				$Status = "Licence OK";
				$BGColour = "chartreuse";
			}
			print PFORM "<TR><td>$key</td><td>$LicCountUsed</td><td>$LicCount</td><td bgcolor=\"$BGColour\">$Status</td></TR>\n";		
		}
	
	print PFORM "</table>\n";
	
	print PFORM "</td></tr>\n";
	print PFORM "<tr><td> <small>Time Report Generated $ReportTime UTC</small></td></tr>";
	
	print PFORM "</table>\n";
	
	
	print PFORM "</body>\n";
	close  PFORM; 
}	
	

if ($CreateOracle)
{
	if ($Verbose){print "Creating Record in Oracle\n";}
	foreach $key (sort keys %ProdLicUsed)
	{
		if (exists($ProdLicUsed{$key}))
		{
			$LicCountUsed = $ProdLicUsed{$key};
		}
		else
		{
			$LicCountUsed = 0;
		}
		if (exists($ProdLicence{$key}))
		{
			$LicCount = $ProdLicence{$key};
		}
		else
		{
			$LicCount = 0;
		}
		if (( $LicCountUsed > $LicCount) && ($LicCount != 0))
		{
			OracleWrite($key, $LicCount, $LicCountUsed, "Prod");
			logit("Write to Oracle ");
			logit("      $key, $LicCount, $LicCountUsed, Prod");
		}
	}

	foreach $key (sort keys %DevLicUsed)
	{
		if (exists($DevLicUsed{$key}))
		{
			$LicCountUsed = $DevLicUsed{$key};
		}
		else
		{
			$LicCountUsed = 0;
		}
		if (exists($ProdLicence{$key}))
		{
			$LicCount = $DevLicence{$key};
		}
		else
		{
			$LicCount = 0;
		}
		if (( $LicCountUsed > $LicCount) && ($LicCount != 0))
		{
			OracleWrite($key, $LicCount, $LicCountUsed, "Dev");
			logit("Write to Oracle ");
			logit("      $key, $LicCount, $LicCountUsed, Dev");
		}
	}

}
if ($CreateEvent)
{
	if ($Verbose){print "Create Netcool Events\n";}
	foreach $key (sort keys %ProdLicUsed)
		{
			if (exists($ProdLicUsed{$key}))
			{
				$LicCountUsed = $ProdLicUsed{$key};
			}
			else
			{
				$LicCountUsed = 0;
			}
			if (exists($ProdLicence{$key}))
			{
				$LicCount = $ProdLicence{$key};
			}
			else
			{
				$LicCount = 0;
			}
			if (( $LicCountUsed > $LicCount) && ($LicCount != 0))
			{
				if ($Verbose){print "Sending Netcool Event for $key to $LIB_Socket_Probe \n";}
				$LIB_Socket_Message{"Transport"} = "LicenceAuditScript";
				$LIB_Socket_Message{"Severity"} = "INFO";
				$LIB_Socket_Message{"Nodealias"} = "xldn0028pap.ldn.swissbank.com";
				$LIB_Socket_Message{"EventIdentifier"} = "LicenceWatch";
				$LIB_Socket_Message{"SAPname"} = "LicenceAudit";
				$LIB_Socket_Message{"ClassID"} = "999998";
				$LIB_Socket_Message{"MessageText"} = "$ReportTime Netcool Licence Issue $key(Prod) Licenced $LicCount Using $LicCountUsed";
				$LIB_Socket_Message{"EventType"} = "1";
				$LIB_Socket_Message{"EventTime"} = "$time";
				$LIB_Socket_Message{"Component"} = "$key";
				$LIB_Socket_Message{"Region"} = "EMEA";
				$LIB_Socket_Message{"Transport"} = "LicenceAuditScript";
				$LIB_Socket_Message{"Acknowledged"} = "0";
				SendSocketEvent();
				logit ("Netcool Event Generated");
				logit ("    $ReportTime Netcool Licence Issue $key(Prod) Licenced $LicCount Using $LicCountUsed");
			}
	}
foreach $key (sort keys %DevLicUsed)
	{
		if (exists($DevLicUsed{$key}))
		{
			$LicCountUsed = $DevLicUsed{$key};
		}
		else
		{
			$LicCountUsed = 0;
		}
		if (exists($DevLicence{$key}))
		{
			$LicCount = $DevLicence{$key};
		}
		else
		{
			$LicCount = 0;
		}
		if (( $LicCountUsed > $LicCount) && ($LicCount != 0))
		{
			if ($Verbose){print "Sending Netcool Event for $key to $LIB_Socket_Probe \n";}
			$LIB_Socket_Message{"Transport"} = "LicenceAuditScript";
			$LIB_Socket_Message{"Severity"} = "INFO";
			$LIB_Socket_Message{"Nodealias"} = "xldn0028pap.ldn.swissbank.com";
			$LIB_Socket_Message{"EventIdentifier"} = "LicenceWatch";
			$LIB_Socket_Message{"SAPname"} = "LicenceAudit";
			$LIB_Socket_Message{"ClassID"} = "999998";
			$LIB_Socket_Message{"MessageText"} = "$ReportTime Netcool Licence Issue $key(Dev) Licenced $LicCount Using $LicCountUsed";
			$LIB_Socket_Message{"EventType"} = "1";
			$LIB_Socket_Message{"EventTime"} = "$time";
			$LIB_Socket_Message{"Component"} = "$key";
			$LIB_Socket_Message{"Region"} = "EMEA";
			$LIB_Socket_Message{"Transport"} = "LicenceAuditScript";
			$LIB_Socket_Message{"Acknowledged"} = "0";
			SendSocketEvent();
			logit ("Netcool Event Generated");
			logit ("    $ReportTime Netcool Licence Issue $key(Dev) Licenced $LicCount Using $LicCountUsed");
		}
	}
}


# Done now so say goodbye nicely
exit 0;



