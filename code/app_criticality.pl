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
use Proc::ProcessTable;



##############################################################################################
#
#	Set the Variables that we need to
#
##############################################################################################

sub ProdVars
{
	if ($Verbose){print "Picking up Prod Vars\n";}
	our $ChrisLib = "/sbclocal/netcool/omnibus/utils/cmdb/Library.plinc";
	our $LIB_AppLogFileName="CMDB_Update";
	our $LIB_PathAppLogFile="/sbclocal/netcool/omnibus/log/";
	our $LIB_MaxLogFileSize=1000000;
	#	$DoLogging set to 1 f you want this app to log or 0 if you don't
	$DoLogging = 1;
	$Verbose = 0;
	$Testing = 0;
}

sub DevVars
{
	if ($Verbose){print "Picking up Dev Vars\n";}
	our $ChrisLib = "/home/janesch/perl/Library/Library.plinc";
	our $LIB_AppLogFileName="CMDB_Update";
	our $LIB_PathAppLogFile="/home/janesch/perl/cmdb/DataVerification/";
	our $LIB_MaxLogFileSize=1000000;
	#	$DoLogging set to 1 f you want this app to log or 0 if you don't
	$DoLogging = 1;
	$Verbose = 1;
	$Testing = 0;
}


$IsDev = 0;
$Error = 0;
%CMDB_Hash = ();
%Adopt_Hash = ();


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
sub GetAdoptData
{

	my $dbh;
	$dbh = DBI->connect( "dbi:Oracle:database=MMSTMP1;HOST=sstm8958por.stm.swissbank.com;PORT=1525;SID=MMSTMP1",
	                        "MMADOPT",
	                        "mmadopt123",
#	$dbh = DBI->connect( "dbi:Oracle:database=MMSTMP2;HOST=sstm5314por.stm.swissbank.com;PORT=1525;SID=MMSTMP2",
#	                        "reporter",
#	                        "reporter",
	                        {
	                            RaiseError => 1,
	                            AutoCommit => 1
	                        }
	                       ) || die "Database connection not made: $DBI::errstr";
	
	my $sthOracle = $dbh->prepare("SELECT CMDB_APP_ID, APP_CRITICALITY, Class FROM managed_app where CMDB_APP_ID is not NULL") || die $dbh->errstr;
	
	$sthOracle->execute() || die $sthOracle->errstr;
	while (my (@nodeOracle) = $sthOracle->fetchrow_array) 
	{
			$CMDB_ID = $nodeOracle[0];
			if (defined($nodeOracle[1]))
			{
				$AppCrit = $nodeOracle[1];
			}
			else 
			{
				$AppCrit = "";
			}

			$LenAppCrit = length($AppCrit);
			$CLASS_ID = $nodeOracle[2];
			if (exists($CMDB_Hash{$CMDB_ID}))
			{
				$CMDB_APP_Crit = $CMDB_Hash{$CMDB_ID};
				if($AppCrit ne $CMDB_APP_Crit)
				{
					print "CMDB_ID = $CMDB_ID   AppCrit = \'$AppCrit\' CMDB_APP_Crit = $CMDB_APP_Crit   $LenAppCrit\n";
					logit ("APP_CRITICALITY changed for Class $CLASS_ID from $AppCrit to $CMDB_APP_Crit \n");
					if($Testing != 1)
					{
						my $sthOracle = $dbh->prepare("update managed_app set APP_CRITICALITY = '$CMDB_APP_Crit' where CMDB_APP_ID = $CMDB_ID") || die $dbh->errstr;
						$sthOracle->execute() || die $sthOracle->errstr;
					}
				}
			}
			
			

	}
	$sthOracle->finish;
	$dbh->disconnect();
	
}

sub GetCmdbData
{
	my $dbh;
	my $SAP_ID;
	my $CMDB_ID;
	
	
#	$dbh = DBI->connect( "dbi:Oracle:database=DCMDBV2;HOST=sldn1339dor.ldn.swissbank.com;PORT=1524;SID=DCMDBV2",
	$dbh = DBI->connect( "dbi:Oracle:database=CMDBP2;HOST=sldn2485por.ldn.swissbank.com;PORT=1530;SID=CMDBP2",
                        "NETCOOL_CMDB",
	                        "Orange18",
	                        {
	                            RaiseError => 1,
	                            AutoCommit => 0
	                        }
	                       ) || die "Database connection not made: $DBI::errstr";
	
	my $sthOracle = $dbh->prepare("SELECT Application_id, UBS_BUSINESSCRITICALITY FROM aradmin.ubs_esm_cmdb_appsys ") || die $dbh->errstr;
	
	$sthOracle->execute() || die $sthOracle->errstr;
	while (my (@nodeOracle) = $sthOracle->fetchrow_array) 
	{
		if(exists($nodeOracle[0]))
		{
			$CMDB_ID = $nodeOracle[0];
			$BUS_CRIT = $nodeOracle[1];
			$CMDB_Hash{$CMDB_ID} = $BUS_CRIT;
		}
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

sub CheckIfAlreadyRunning 
{
#################################################################################
#
#	This sub checks to see if an instance is already running
#	usage:	
#	Required Global Variables
#		
#		
#		
#
#################################################################################

    my $fullprocname = $0;
    my $pidnum = $$;
    my ($t, $p, $procrun, $pidrun);
    my @ProcArray;
    
    @ProcArray = split(/\//, $fullprocname);
    my $Arraylength = @ProcArray;
    my $procname = $ProcArray[$Arraylength -1];
    $t = new Proc::ProcessTable;
    foreach $p (@{$t->table}) 
    {
        $procrun = $p->fname;
        $pidrun = $p->pid;
        if ($procrun eq $procname && $pidrun != $pidnum ) 
        {
			logit("Application " . $0 . " Exiting as it has detected that another instance is running with pid " . $pidrun);
           	exit;
        }
    }
}


sub CheckIfAlreadyRunning1 
{
#################################################################################
#
#	This sub checks to see if an instance is already running
#	usage:	
#	Required Global Variables
#		
#		
#		
#
#################################################################################

    my $fullprocname = $0;
    my $pidnum = $$;
    my ($t, $p, $procrun, $pidrun);
    my @ProcArray;
    
    @ProcArray = split(/\//, $fullprocname);
    my $Arraylength = @ProcArray;
    my $procname = $ProcArray[$Arraylength -1];
print "procname = $procname\n";
    $t = new Proc::ProcessTable;
    foreach $p (@{$t->table}) 
    {
        $procrun = $p->fname;
        $pidrun = $p->pid;
print "procrun = $procrun procname = $procname  = $pidrun pidnum = $pidnum\n";
        if ($procrun eq $procname ) 
        {
	        print "procrun = $procrun procname = $procname  = $pidrun pidnum = $pidnum\n";
        }
        if ($procrun eq $procname && $pidrun != $pidnum ) 
        {
			print "procrun = $procrun procname = $procname  = $pidrun pidnum = $pidnum\n";
           	exit;
        }
    }

}

##############################################################################################
#
#	This is where the code Starts
#
##############################################################################################

if ($Verbose){print "Starting Applicaton\n";}
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
CheckIfAlreadyRunning1;

logit("Application " . $0 . " Starting" or DieHere "Cannot write to Log file");

sleep 10;


GetCmdbData;
GetAdoptData;

logit("Application " . $0 . " Completed" or DieHere "Cannot write to Log file");

if ($Verbose){print "Application Exiting\n";}
exit;
