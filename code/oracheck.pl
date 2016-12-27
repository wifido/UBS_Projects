#!/sbcimp/run/pd/perl/5.8.7/bin/perl -w
   
##############################################################################################
#
# This Script Converts ClassStream.csv (file derived by oracle from the adoption daatabase) and
# creates ClassStream.lookup for use in the Netcool probe rules
#
#	Original	Chris Janes	20080318
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


#############################################################################
#
#	Here we declare pragma
#
#############################################################################

use strict;
   
   

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
use Scalar::Util qw(looks_like_number);
use File::Path;



##############################################################################################
#
#	Set the Variables that we need to
#
##############################################################################################

#	$TargetFileName	The name ot the file used as the target for this script
my $TargetFileName = "oracheck.txt";
#	$TargetDir	the directory that has the target file in it
my $TargetPath = "/home/janesch/perl/OraCheck/";
#$TargetPath = "/home/netcool/scripts/OraCheck/";
#	$TargetFile if file to be used a the target for this scripts output
my $TargetFile = $TargetPath . $TargetFileName;


#	$LogDir	the directory that has the archive in it
my $AppLogPath = "/home/wallersi/Log/";
#my $AppLogPath = "/home/janesch/perl/OraCheck/Log/";
#$AppLogPath = "/sbclocal/netcool/omnibus/log/";
#	$AppLogFileName the directory that has the log file in it
my $AppLogFileName = "oracheck.log";
#	$AppLogFile if the file to be used for logging by this scripts 
my $AppLogFile = $AppLogPath . $AppLogFileName;
#	$MaxLogFileSize Max sizze of this apps log file
my $MaxLogFileSize = 200000;
#	$DoLogging set to 1 f you want this app to log or 0 if you don't
my $DoLogging = 1;

my $Verbose = 0;

my $Error = 0;

my $SQLStatement;
my $SQLConnect;
my @data;
my $Line;


##############################################################################################
#
#	This is where the Functions Go
#
##############################################################################################


sub GetData
{

	my $dbh;
	my $info;
	my $tmp;
	
	if ($Verbose){print " Connect to DB\n";}
	$dbh = DBI->connect($SQLConnect ,
	                        "mm_rouser",
	                        "mm_rouser02",
	                        {
	                            RaiseError => 1,
	                            AutoCommit => 0
	                        }
	                       ) || die "Database connection not made: $DBI::errstr";
	
#	my $sthOracle = $dbh->prepare("SELECT CLASS, STREAM FROM MMADOPT.MANAGED_APP ORDER BY CLASS") || die $dbh->errstr;
#	my $sthOracle = $dbh->prepare("SELECT COUNT(*) FROM REPORTER_STATUS") || die $dbh->errstr;
#	$SQLStatement = "SELECT COUNT(*) FROM REPORTER_STATUS";
	my $sthOracle = $dbh->prepare($SQLStatement) || die $dbh->errstr;


	if ($Verbose){print " Execute call to DB\n";}
	
	$sthOracle->execute() || die $sthOracle->errstr;
	
		if ($Verbose){print " extract returned Data\n";}

	while (my (@nodeOracle) = $sthOracle->fetchrow_array) 
	{
		if (defined $nodeOracle[1])
		{
#			$info = $nodeOracle[0] . "," . $nodeOracle[1] ."\n";
			$info = $nodeOracle[0] ."\n";
			$tmp = $nodeOracle[0];
			push @data, $info;
		}
		else
		{
			$info = $nodeOracle[0];
			push @data, $info;
		}
		
	}
	if ($Verbose){print " Finish call to DB\n";}
	$sthOracle->finish;
	if ($Verbose){print " Disconnect from DB\n";}
	$dbh->disconnect();
	return $tmp;
	
	
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
	
	if ($DoLogging)
	{
		my $str = $_[0];
		chomp $str;
		#print $str;
		my $error_str = $str . " " . localtime(time) . "\n";
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
my @logfilestat;
my $AppLogFileBackup;

	if(-d $AppLogPath)
	{
		#The Dir $ArchiveDir exists
	}
	else
	{
		#The Dir $ArchiveDir does NOT Exist
		mkpath $AppLogPath or DieHere " cannot create dir $AppLogPath\n";
	}
	
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


sub CheckDataAvailable
{
my $DataSource;

	if (-e $DataSource)
	{
		# The DataSource existst
		print "DataSource Exists\n";
	}
	else
	{
		logit " Cant find the Data Source $DataSource \n";
		print " Cant find the Data Source $DataSource \n";
		exit;
	}
}

sub asknice
{
my $thisdata;
	if ($Verbose){print " Reading Source data\n";}
	GetData;
	if ($Verbose){print " Completed Reading Source Data\n";}


	foreach $Line (@data)
	{
		$thisdata = $Line
	}

	return $thisdata

}
##############################################################################################
#
#	This is where the code Starts
#
##############################################################################################


if ($Verbose){print "Starting Applicaton\n";}


Set_up_logit;

$SQLConnect = "dbi:Oracle:database=MMSTMP1;HOST=151.191.229.147;PORT=1525;SID=MMSTMP1";

$SQLStatement = "SELECT COUNT(*) FROM REPORTER_STATUS where lastmodified < sysdate - 185 ";
my $STM_ToOld = asknice;

$SQLStatement = "SELECT COUNT(*) FROM REPORTER_STATUS where lastmodified BETWEEN TRUNC(SYSDATE)-30 AND TRUNC(SYSDATE) ";
my $STM_ToOld_1 = asknice;
$SQLStatement = "SELECT COUNT(*) FROM REPORTER_STATUS where lastmodified BETWEEN TRUNC(SYSDATE)-60 AND TRUNC(SYSDATE)-30 ";
my $STM_ToOld_2 = asknice;
$SQLStatement = "SELECT COUNT(*) FROM REPORTER_STATUS where lastmodified BETWEEN TRUNC(SYSDATE)-90 AND TRUNC(SYSDATE)-60 ";
my $STM_ToOld_3 = asknice;
$SQLStatement = "SELECT COUNT(*) FROM REPORTER_STATUS where lastmodified BETWEEN TRUNC(SYSDATE)-120 AND TRUNC(SYSDATE)-90 ";
my $STM_ToOld_4 = asknice;
$SQLStatement = "SELECT COUNT(*) FROM REPORTER_STATUS where lastmodified BETWEEN TRUNC(SYSDATE)-150 AND TRUNC(SYSDATE)-120 ";
my $STM_ToOld_5 = asknice;
$SQLStatement = "SELECT COUNT(*) FROM REPORTER_STATUS where lastmodified BETWEEN TRUNC(SYSDATE)-180 AND TRUNC(SYSDATE)-150 ";
my $STM_ToOld_6 = asknice;


$SQLStatement = "SELECT COUNT(*) FROM REPORTER_STATUS ";
my $STM_Total = asknice;



$SQLConnect = "dbi:Oracle:database=MMLDNP1;HOST=139.149.33.108;PORT=1525;SID=MMLDNP1";

$SQLStatement = "SELECT COUNT(*) FROM REPORTER_STATUS where lastmodified < sysdate - 185 ";
my $LDN_ToOld = asknice;

$SQLStatement = "SELECT COUNT(*) FROM REPORTER_STATUS ";
my $LDN_Total = asknice;

$SQLStatement = "SELECT COUNT(*) FROM REPORTER_STATUS where lastmodified BETWEEN TRUNC(SYSDATE)-30 AND TRUNC(SYSDATE) ";
my $LDN_ToOld_1 = asknice;
$SQLStatement = "SELECT COUNT(*) FROM REPORTER_STATUS where lastmodified BETWEEN TRUNC(SYSDATE)-60 AND TRUNC(SYSDATE)-30 ";
my $LDN_ToOld_2 = asknice;
$SQLStatement = "SELECT COUNT(*) FROM REPORTER_STATUS where lastmodified BETWEEN TRUNC(SYSDATE)-90 AND TRUNC(SYSDATE)-60 ";
my $LDN_ToOld_3 = asknice;
$SQLStatement = "SELECT COUNT(*) FROM REPORTER_STATUS where lastmodified BETWEEN TRUNC(SYSDATE)-120 AND TRUNC(SYSDATE)-90 ";
my $LDN_ToOld_4 = asknice;
$SQLStatement = "SELECT COUNT(*) FROM REPORTER_STATUS where lastmodified BETWEEN TRUNC(SYSDATE)-150 AND TRUNC(SYSDATE)-120 ";
my $LDN_ToOld_5 = asknice;
$SQLStatement = "SELECT COUNT(*) FROM REPORTER_STATUS where lastmodified BETWEEN TRUNC(SYSDATE)-180 AND TRUNC(SYSDATE)-150 ";
my $LDN_ToOld_6 = asknice;





my $Diff_Total = $STM_Total - $LDN_Total;
my $Diff_ToOld = $STM_ToOld - $LDN_ToOld;

print "		STM		LDN		DIFF\n";
print "Total Events	$STM_Total	$LDN_Total  	$Diff_Total \n";
print "To Old Events	$STM_ToOld 		$LDN_ToOld		$Diff_ToOld \n";
print "\n";
print "$STM_ToOld_1	$STM_ToOld_2	$STM_ToOld_3	$STM_ToOld_4	$STM_ToOld_5	$STM_ToOld_6\n";
print "$LDN_ToOld_1	$LDN_ToOld_2	$LDN_ToOld_3	$LDN_ToOld_4	$LDN_ToOld_5	$LDN_ToOld_6\n";
if ($Error)
{
	if ($Verbose){print "Errors Generated Please see log file ( $AppLogFile ) for further details\n";}
}
if ($Verbose){print "Application Exiting\n";}
exit;
