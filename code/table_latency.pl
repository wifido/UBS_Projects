#!/sbcimp/run/pd/perl/5.8.7/bin/perl -w
   
##############################################################################################
#

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
my $AppLogPath = "/home/janesch/perl/OraCheck/Log/";
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
my $data;
my $Line;
my $StartPoint = "13-APR-08";
my $EndPoint = "14-APR-08";
my $Diff;
my $REMDiff;
my $DELDiff;
my $AckDiff;
my @ProbeList;
my @WebtopList;
my @Results;
my $ProbeCount;
my $WebtopCount;
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
	                        "reporter",
	                        "reporter",
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
	$data=();

	while (my (@nodeOracle) = $sthOracle->fetchrow_array) 
	{
		if (defined $nodeOracle[0])
		{
			$data = int($nodeOracle[0]) ;
#			push @data, $info;
		}
		else
		{
			$data = int($nodeOracle[0]);
#			push @data, $info;
		}
		
	}
	if ($Verbose){print " Finish call to DB\n";}
	$sthOracle->finish;
	if ($Verbose){print " Disconnect from DB\n";}
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


	$thisdata = $data;

	return $thisdata;

}
##############################################################################################
#
#	This is where the code Starts
#
##############################################################################################


if ($Verbose){print "Starting Applicaton\n";}


#Set_up_logit;
my $i;

$ProbeList[1] = 'LDNSKTPROD1';
$ProbeList[2] = 'LDNMTPPROD2';
$ProbeList[3] = 'ZURSKTPROD1';
$ProbeList[4] = 'ZURMTPPROD2';
$ProbeList[5] = 'STMSKTPROD1';
$ProbeList[6] = 'STMMTPPROD2';
$ProbeList[7] = 'SNGSKTPROD1';
$ProbeList[8] = 'SNGMTPPROD2';

$WebtopList[1] = 'xldn2892pap';
$WebtopList[2] = 'xldn2893pap';
$WebtopList[3] = 'xldn2376pap';
$WebtopList[4] = 'xstm1770pap';
$WebtopList[5] = 'xstm1771pap';
$WebtopList[6] = 'xsng1284pap';
$WebtopList[7] = 'xsng1285pap';
$WebtopList[8] = 'xsng1282pap';



$SQLConnect = "dbi:Oracle:database=MMSTMP1;HOST=151.191.229.147;PORT=1525;SID=MMSTMP1";


for($ProbeCount = 1 ; $ProbeCount <=8; $ProbeCount = $ProbeCount + 1)
{
	for($WebtopCount = 1 ; $WebtopCount <=8; $WebtopCount = $WebtopCount + 1)
	{
		$SQLStatement = "select (rtime - stime) *24*60*60 from MMLATENCY.latency_stats where probe = '$ProbeList[$ProbeCount]' and webtop = '$WebtopList[$WebtopCount]' and rownum <= 1 order by stime desc";
		asknice;
		$Results[$ProbeCount + ($WebtopCount *10)] = $data;
	}
}
system("clear");
printf ("%s		%s	%s	%s	%s	%s	%s	%s	%s\n","" , $WebtopList[1], $WebtopList[2], $WebtopList[3], $WebtopList[4], $WebtopList[5], $WebtopList[6], $WebtopList[7], $WebtopList[8]);
for($WebtopCount = 1 ; $WebtopCount <=8; $WebtopCount = $WebtopCount + 1)
{
	printf ("%s	%d		%d		%d		%d		%d		%d		%d		%d\n", $ProbeList[$WebtopCount] , $Results[1 + ($WebtopCount *10)], $Results[2 + ($WebtopCount *10)], $Results[3 + ($WebtopCount *10)], $Results[4 + ($WebtopCount *10)], $Results[5 + ($WebtopCount *10)], $Results[6 + ($WebtopCount *10)], $Results[7 + ($WebtopCount *10)], $Results[8 + ($WebtopCount *10)]);
}





if ($Error)
{
	if ($Verbose){print "Errors Generated Please see log file ( $AppLogFile ) for further details\n";}
}
if ($Verbose){print "Application Exiting\n";}
exit;
