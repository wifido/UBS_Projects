#!/sbcimp/run/pd/perl/5.8.7/bin/perl -w
   
##############################################################################################
#
# This Script extract data from cmdb
#
#	Original	Chris Janes	20080925
#
#
##############################################################################################


   
   
   BEGIN {


      $ENV{ ORACLE_HOME } = "/sbcimp/run/tp/oracle/client/v9.2.0.4.0-32bit";
      $ENV{ TNS_ADMIN   } = "/sbcimp/run/pkgs/oracle/config";
      $ENV{LANG} = "C";
      $ENV{OMNIHOME} = qw(/sbclocal/netcool/omnibus);
      $ENV{SYBASE} = qw(/sbcimp/run/tp/sybase/OpenClientServer/v12.5);
      $ENV{SYBASE_OCS} = q(OCS-12_5);
      $ENV{PERL5LIB} = "";

   }


##############################################################################################
#
#	Get the Modules we are using
#
##############################################################################################

use lib "/sbcimp/run/pd/cpan/5.8.5-2004.09/lib";


use DBI;
use DBD::Sybase;
use DateTime;
use Switch;
#use strict;
use Scalar::Util qw(looks_like_number);
use File::Path;

my $SQL;
my @Data;
my $NewStream;
our @StreamsArray = ();

##############################################################################################
#
#	Set the Variables that we need to
#
##############################################################################################

sub ProdVars
{
	if ($Verbose){print "Picking up Prod Vars\n";}
	our $ChrisLib = "/sbclocal/netcool/omnibus/utils/cmdb/Library.plinc";
	our $LIB_AppLogFileName="MMADOPT_Update";
	our $LIB_PathAppLogFile="/sbclocal/netcool/omnibus/log/";
	our $LIB_MaxLogFileSize=1000000;
	#	$DoLogging set to 1 f you want this app to log or 0 if you don't
	$DoLogging = 1;
	$Verbose = 1;
	$Testing = 0;
}

sub DevVars
{
	if ($Verbose){print "Picking up Dev Vars\n";}
	our $ChrisLib = "/home/janesch/perl/cmdb/mmadopt/Library.plinc";
	our $LIB_AppLogFileName="MMADOPT_Update";
	our $LIB_PathAppLogFile="/home/janesch/perl/cmdb/mmadopt/";
	our $LIB_MaxLogFileSize=1000000;
	#	$DoLogging set to 1 f you want this app to log or 0 if you don't
	$DoLogging = 1;
	$Verbose = 1;
	$Testing = 1;
}


$IsDev = 0;
$Error = 0;


#############################################################################
#
#	Here we load the Chris's Library of sub routines
#
#############################################################################

sub GetLibs
{
	
	if ( -r $ChrisLib ) 
	{ 
		if ($Verbose){print "Libraries are $ChrisLib\n";}		
		do "$ChrisLib"; 
	} 
	else 
	{ 
		print "Unable to read $ChrisLib\n"; 
	}
} 

##############################################################################################
#
#	This is where the Functions Go
#
##############################################################################################
sub SetFlag
{
	if  (defined ($LIB_Flag)){} else {$LIB_Flag = "LibraryPlinc.flag";}
	if ($Verbose){print "LIBMESS LIB_Flag = $LIB_Flag\n";}
	system ("touch $LIB_Flag");
}

sub TestFlag
{
	if  (defined ($LIB_Flag)){} else {$LIB_Flag = "LibraryPlinc.flag";}
	my $Return;
	if (-e $LIB_Flag)
	{
		$Return = 0;
	}
	else
	{
		SetFlag;
		$Return = 1;
	}
	return $Return;
}

sub ClearFlag
{
	if (defined ($LIB_Flag)){} else {$LIB_Flag = "LibraryPlinc.flag";}
	if (-e $LIB_Flag)
	{
		unlink $LIB_Flag or die "Cannot delete $LIB_Flag\n";
	}
}


sub PutAdoptData
{

	my $dbh;
	$dbh = DBI->connect( "dbi:Oracle:database=MMSTMP1;HOST=sstm8958por.stm.swissbank.com;PORT=1525;SID=MMSTMP1",
	                        "MMADOPT",
	                        "mmadopt123",
	                        {
	                            RaiseError => 1,
	                            AutoCommit => 1
	                        }
	                       ) || die "Database connection not made: $DBI::errstr";
	my $sthOracle = $dbh->prepare($SQL) || die $dbh->errstr;
	
	$sthOracle->execute() || die $sthOracle->errstr;
	$sthOracle->finish;
	$dbh->disconnect();
	
}


sub GetAdoptData
{
	if ($Verbose){print "	GetAdoptData \n";}
	my $dbh;
	$dbh = DBI->connect( "dbi:Oracle:database=MMSTMP1;HOST=sstm8958por.stm.swissbank.com;PORT=1525;SID=MMSTMP1",
	                        "MMADOPT",
	                        "mmadopt123",
	                        {
	                            RaiseError => 1,
	                            AutoCommit => 1
	                        }
	                       ) || die "Database connection not made: $DBI::errstr";
	if ($Verbose){print "	SQL = $SQL \n";}
	my $sthOracle = $dbh->prepare($SQL) || die $dbh->errstr;
	$sthOracle->execute() || die $sthOracle->errstr;
	while (my (@NewnodeOracle) = $sthOracle->fetchrow_array) 
	{
			print "       $NewnodeOracle[0]  $NewnodeOracle[1]\n";
			$SQL = "update managed_app set streamid = " . $NewStream . ", stream = '" . $Streams_Hash{$NewStream} . "' where class = " . $NewnodeOracle[0];
			logit("streamid changed to $NewStream ($Streams_Hash{$NewStream}) for Class $NewnodeOracle[0]");
			if ($Verbose){print "SQL = $SQL\n";}
			PutAdoptData;
	}
	$sthOracle->finish;
	$dbh->disconnect();
}

sub GetCMDBStreamData
{
	my $dbh;
	$dbh = DBI->connect( "dbi:Oracle:database=MMSTMP1;HOST=sstm8958por.stm.swissbank.com;PORT=1525;SID=MMSTMP1",
	                        "MMADOPT",
	                        "mmadopt123",
	                        {
	                            RaiseError => 1,
	                            AutoCommit => 1
	                        }
	                       ) || die "Database connection not made: $DBI::errstr";
	$SQL = "select * from CMDB_STREAM_LOOKUP";
	my $sthOracle = $dbh->prepare($SQL) || die $dbh->errstr;
	$sthOracle->execute() || die $sthOracle->errstr;
	while (my (@nodeOracle) = $sthOracle->fetchrow_array) 
	{
			if ($Verbose){print "GetCMDB  $nodeOracle[0] $nodeOracle[1] $nodeOracle[2] \n";}
			$NewStream = $nodeOracle[2];
			$SQL = "select Class, STREAMID from managed_app where op_com = '" . $nodeOracle[0] ."' and SUB_OP_COM = '" . $nodeOracle[1] ."' and STREAMID != " . $nodeOracle[2] ;
			GetAdoptData;
	}
	$sthOracle->finish;
	$dbh->disconnect();
}

sub GetStreamLookup
{
	my $dbh;
	$dbh = DBI->connect( "dbi:Oracle:database=MMSTMP1;HOST=sstm8958por.stm.swissbank.com;PORT=1525;SID=MMSTMP1",
	                        "MMADOPT",
	                        "mmadopt123",
	                        {
	                            RaiseError => 1,
	                            AutoCommit => 1
	                        }
	                       ) || die "Database connection not made: $DBI::errstr";
	$SQL = "select * from STREAMS";
	my $sthOracle = $dbh->prepare($SQL) || die $dbh->errstr;
	$sthOracle->execute() || die $sthOracle->errstr;
	while (my (@nodeOracle) = $sthOracle->fetchrow_array) 
	{
#			if ($Verbose){print " $nodeOracle[0] $nodeOracle[1] $nodeOracle[2] \n";}
			if ($Verbose){print " $nodeOracle[0] $nodeOracle[1]  \n";}
			$STREAMID = $nodeOracle[0];
			$STREAMNAME = $nodeOracle[1];
			$Streams_Hash{$STREAMID} = $STREAMNAME;
	}
	$sthOracle->finish;
	$dbh->disconnect();
}

sub CheckForMissingStreams
{
	if ($Verbose){print "	CheckForMissingStreams \n";}
	my $dbh;
	$dbh = DBI->connect( "dbi:Oracle:database=MMSTMP1;HOST=sstm8958por.stm.swissbank.com;PORT=1525;SID=MMSTMP1",
	                        "MMADOPT",
	                        "mmadopt123",
	                        {
	                            RaiseError => 1,
	                            AutoCommit => 1
	                        }
	                       ) || die "Database connection not made: $DBI::errstr";
	$SQL = "select Class, op_com, SUB_OP_COM, STREAMID from managed_app where STREAMID = 999 and source = 1";
	my $sthOracle = $dbh->prepare($SQL) || die $dbh->errstr;
	$sthOracle->execute() || die $sthOracle->errstr;
	while (my (@nodeOracle) = $sthOracle->fetchrow_array) 
	{
			if ($Verbose){print "		Check		@nodeOracle \n";}
#			if ($Verbose){print "Check		$nodeOracle[0] $nodeOracle[1] $nodeOracle[2] $nodeOracle[3] \n";}
#			if ($Verbose){print " $nodeOracle[0] $nodeOracle[1]  \n";}
	}
	$sthOracle->finish;
	$dbh->disconnect();

}

sub DieHere
{
#################################################################################
#
#	This sub takes a message, logs it and then dies (in the perl sense of the
#	word)
#	usage:	DieHere(<Message>)
#	Required Global Variables
#		$AppLogFile	logfile including path
#
#################################################################################

	my $str = $_[0];
	chomp $str;
	my $error_str = $str . " " . localtime(time) . "\n";
	open (APPLOG,">>$AppLogFile")|| die "cannot open $AppLogFile file";
	print APPLOG $error_str;
	close (APPLOG);
	die $str;
}



##############################################################################################
#
#	This is where the code Starts
#
##############################################################################################

if ($Verbose){print "Starting Applicaton $0\n";}
if ($Verbose){print "Got Libraries\n";}

# do we want this to go to netcool dev for testing
if ($IsDev == 1)
{
	DevVars();
	if ($Verbose){print "Got Dev Vars\n";}
}
else
{
	ProdVars();
	if ($Verbose){print "Got Prod Vars\n";}
}

GetLibs;

logit("Application ($0) Starting" or DieHere "Cannot write to Log file");
if ( TestFlag == 0)
{
	print "Exiting due to existance of flag $LIB_Flag\n";
	logit("Exiting due to existance of flag $LIB_Flag" );
	exit;
}
if ($Verbose) {print "LIB_Flag = $LIB_Flag\n";}

GetStreamLookup;
GetCMDBStreamData;

#GetAdoptData;
$Verbose = 1;
# CheckForMissingStreams;
$Verbose = 0;

ClearFlag;

if ($Error)
{
	if ($Verbose){print "Errors Generated Please see log file ( $AppLogFile ) for further details\n";}
}


if ($Verbose){print "Application Exiting\n";}
logit("Application ($0) Exiting" or DieHere "Cannot write to Log file");

exit;
