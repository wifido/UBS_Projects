#!/sbcimp/run/pd/perl/5.8.7/bin/perl -w
   
##############################################################################################
#
# This Script extract data from the autosys lookup and populates the adoption db table
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



##############################################################################################
#
#	Set the Variables that we need to
#
##############################################################################################


#	$LogDir	the directory that has the archive in it
#$AppLogPath = "/home/janesch/perl/ClassStream/Log/";
#$AppLogPath = "/sbclocal/netcool/omnibus/log/";
#	$AppLogFileName the directory that has the log file in it
$AppLogFileName = "Autosys_lookup.log";
#	$AppLogFile if the file to be used for logging by this scripts 
#$AppLogFile = $AppLogPath . $AppLogFileName;
$AppLogFile = $AppLogFileName;

#$LookupPath Path Where lookup can be found
$LookupPath = "/sbclocal/netcool/omnibus/all_rules/ubsw/lookuptables/";

#	$LookupFileName the directory that has the log file in it
$LookupFileName = "Chris.Autosys_ClassGroup.lookup";
$LookupFile = $LookupPath . $LookupFileName;


#	$MaxLogFileSize Max sizze of this apps log file
$MaxLogFileSize = 200000;
#	$DoLogging set to 1 f you want this app to log or 0 if you don't
$DoLogging = 1;
#	$DoMailing set to 1 f you want this app to Mail the logging or 0 if you don't
$DoMailing = 0;

$Verbose = 1;

$Error = 0;
$Testing = 0;

%CMDB_Hash = ();
%Adopt_Hash = ();
my @Lookup =();
our $SQL;


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
	
	my $sthOracle = $dbh->prepare("SELECT SAPNUMBER, CMDB_APP_ID, Class FROM managed_app where SAPNUMBER is not NULL") || die $dbh->errstr;
	
	$sthOracle->execute() || die $sthOracle->errstr;
	while (my (@nodeOracle) = $sthOracle->fetchrow_array) 
	{
			$SAP_ID = $nodeOracle[0];
			$CMDB_ID = $nodeOracle[1];
			if(defined($CMDB_ID))
			{
				# so it's OK
			}
			else
			{
				$CMDB_ID = 0;
			}
			$CLASS_ID = $nodeOracle[2];
			if (exists($CMDB_Hash{$SAP_ID}))
			{
				$CMDB_APP_ID = $CMDB_Hash{$SAP_ID};
				if($CMDB_ID != $CMDB_APP_ID)
				{
					print "SAP_ID = $SAP_ID   CMDB_ID = $CMDB_ID CMDB_APP_ID = $CMDB_APP_ID\n";
					logit ("CMDB_APP_ID changed for Class $CLASS_ID from $CMDB_ID to $CMDB_APP_ID \n");
					if ($Testing != 1)
					{
						print "Writing data\n";
						my $sthOracle = $dbh->prepare("update managed_app set CMDB_APP_ID = $CMDB_APP_ID where SAPNUMBER = $SAP_ID") || die $dbh->errstr;
						$sthOracle->execute() || die $sthOracle->errstr;
					}
				}
			}
			
			

	}
	$sthOracle->finish;
	$dbh->disconnect();
	
}

sub PutMMAdoptData
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


sub logit
{
#################################################################################
#
#	This sub reads the config file and calls the archive subs as appropriate
#	usage:	logit(<Log file entry>)
#	Required Global Variables
#		$AppLogFile	logfile including path
#
#################################################################################
	
	my $str = $_[0];
	chomp $str;
	#print $str;
	my $error_str = $str . " " . localtime(time) . "\n";

	if ($DoLogging)
	{
		chmod 0666, $AppLogFile;
		open (APPLOG,">>$AppLogFile")|| DieHere "cannot open $AppLogFile file";
		print APPLOG $error_str;
		close (APPLOG);
	}
}

sub Set_up_logit
{
#################################################################################
#
#	This sub reads the config file and calls the archive subs as appropriate
#	usage:	Set_up_logit
#	Required Global Variables
#		$AppLogFile	logfile including path
#		$AppLogPath	logfile  path
#		$AppLogName	logfile  name
#
#################################################################################

#	if(-d $AppLogPath)
#	{
#		#The Dir $ArchiveDir exists
#	}
#	else
#	{
#		#The Dir $ArchiveDir does NOT Exist
#		mkpath $AppLogPath or DieHere " cannot create dir $AppLogPath\n";
#	}
	
	# write to log file
	logit("Application Starting" or DieHere "Cannot write to Log file");
	
	# Make sure the log file is an acceptable size
			
	@logfilestat  = stat($AppLogFile);
	if ($logfilestat[7] > $MaxLogFileSize)
	{
		$AppLogFileBackup = $AppLogFile."old";
		if (-e $AppLogFileBackup)
		{
			unlink $AppLogFileBackup or DieHere "Cannot delete $AppLogFileBackup\n";
		}
		system("mv $AppLogFile $AppLogFileBackup");
	}

}

sub GetLookupData
{
	if ($Verbose){print "GetLookupData\n";}
	open (LOOKUP,"$LookupFile")|| die "cannot open $LookupFile file";
	@Lookup = <LOOKUP>;
	close (LOOKUP);


}


##############################################################################################
#
#	This is where the code Starts
#
##############################################################################################
my $LineType;
if ($Verbose){print "Starting Applicaton\n";}


Set_up_logit;

if ($Verbose){print " Reading Source data\n";}
GetLookupData;

if ($Verbose){print " Clear out DB table\n";}

if ($Verbose){print " Write data data\n";}
my $count = 0;
foreach $Line (@Lookup)
{
	if ($Line =~ m/autosysJobClassGID =/)
	{
		$LineType = 1;
		if ($Verbose){print "LineType = 1 (regmatch)\n";}
	}
	elsif ($Line =~ m/autosysInstanceClass =/)
	{
		$LineType = 2;
		if ($Verbose){print "LineType = 2 (Instance)\n";}
	}
	elsif ($Line =~ m/autosysJobClassGIDSysDesig =/)
	{
		$LineType = 3;
		if ($Verbose){print "LineType = 3 (Exact)\n";}
	}
	elsif ($Line =~ m/default/)
	{
		#do nothing
	}
	elsif ($Line =~ m/{\"/)
	{
		$count = $count + 1;
		my $TmpLine = $Line;
		$TmpLine =~ s/{//;
		$TmpLine =~ s/}/,,/;
		$TmpLine =~ s/\"//g;
		$TmpLine =~ s/\s//g;
		my @SplitArray = split (/,/, $TmpLine);
		if (defined($SplitArray[3])){}else {$SplitArray[3]=0;}
		
		print "		>>>>> $SplitArray[0],$SplitArray[1],$SplitArray[2],$SplitArray[3],\n"; 
		$SQL = "insert into mmadopt.managed_autosys_job 
	}


}
print"Count = $count\n";
if ($Verbose){print "Application Exiting\n";}
exit;
