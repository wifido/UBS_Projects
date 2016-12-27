#!/sbcimp/run/pd/perl/5.8.7/bin/perl -w
   
##############################################################################################
#
# This Script extract the Netcool Risk.Lookup file from the Adoption DB
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

#	$TargetFileName	The name ot the file used as the target for this script
my $TargetFileName = "risk.lookup";
#	$TargetDir	the directory that has the target file in it
#$TargetPath = "/home/netcool/scripts/Risk_lookup/";
$TargetPath = "/home/janesch/perl/Risk_lookup/";
#	$TargetFile if file to be used a the target for this scripts output
$TargetFile = $TargetPath . $TargetFileName;


#	$LogDir	the directory that has the archive in it
#$AppLogPath = "/home/janesch/perl/ClassStream/Log/";
$AppLogPath = "/sbclocal/netcool/omnibus/log/";
#	$AppLogFileName the directory that has the log file in it
$AppLogFileName = "RiskLookup.log";
#	$AppLogFile if the file to be used for logging by this scripts 
$AppLogFile = $AppLogPath . $AppLogFileName;

#	Mail File and Path added for body of mail 20080617
#	$LogDir	the directory that has the archive in it
#$AppMailPath = "/home/janesch/perl/ClassStream/Log/";
$AppMailPath = "/sbclocal/netcool/omnibus/log/";
#	$AppMailFileName the directory that has the log file in it
$AppMailFileName = "RiskLookup.mail";
#	$AppLogFile if the file to be used for logging by this scripts 
$AppMailFile = $AppMailPath . $AppMailFileName;
#	$MailRecipient to whom the mail should be sent, if it should include more than 1 the a space should be used to seperate them
#$MailRecipient = "chris.janes\@ubs.com";
$MailRecipient = "DL-Monitoring-Assistance\@ubs.com";
#$MailRecipient = "sh-monitoring-support\@ubs.com";
#	$MailSummary - what the summary field of the Email should be
$MailSummary = "\"Lookup Push Request RiskLookup.pl\"";


#	$MaxLogFileSize Max sizze of this apps log file
$MaxLogFileSize = 200000;
#	$DoLogging set to 1 f you want this app to log or 0 if you don't
$DoLogging = 1;
#	$DoMailing set to 1 f you want this app to Mail the logging or 0 if you don't
$DoMailing = 1;

$Verbose = 0;

$Error = 0;


##############################################################################################
#
#	This is where the Functions Go
#
##############################################################################################


sub GetData
{

	my $dbh;
	$dbh = DBI->connect( "dbi:Oracle:database=MMSTMP1;HOST=151.191.229.147;PORT=1525;SID=MMSTMP1",
	                        "mmadopt",
	                        "mmadopt123",
	                        {
	                            RaiseError => 1,
	                            AutoCommit => 0
	                        }
	                       ) || die "Database connection not made: $DBI::errstr";
	
	my $sthOracle = $dbh->prepare("SELECT CLASS, APP_CRITICALITY FROM MMADOPT.MANAGED_APP ORDER BY CLASS") || die $dbh->errstr;
	
	$sthOracle->execute() || die $sthOracle->errstr;
	while (my (@nodeOracle) = $sthOracle->fetchrow_array) 
	{
		if (defined $nodeOracle[1])
		{
			$info = $nodeOracle[0] . "," . $nodeOracle[1] ."\n";
			push @data, $info;
		}
		else
		{
			$info = $nodeOracle[0] . "," . "" ."\n";
			push @data, $info;
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
	if ($DoMailing)
	{
		chmod 0666, $AppMailFile;
		open (APPLOG,">>$AppMailFile")|| DieHere "cannot open $AppMailFile file";
		print APPLOG $str;
		close (APPLOG);
		chmod 0666, $AppMailFile;
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

sub Set_up_mailit
{
#################################################################################
#
#	This sub reads the config file and calls the archive subs as appropriate
#	usage:	Set_up_mailit
#	Required Global Variables
#		$AppMailFile	logfile including path
#		$AppMailPath	logfile  path
#		$AppMailName	logfile  name
#
#################################################################################

	if(-d $AppMailPath)
	{
		#The Dir $ArchiveDir exists
	}
	else
	{
		#The Dir $ArchiveDir does NOT Exist
		mkpath $AppMailPath or DieHere " cannot create dir $AppMailPath\n";
	}
	
#Get rid of the existing mail file so we can make another
	if (-e $AppMailFile)
	{
		unlink $AppMailFile or DieHere "Cannot delete $AppMailFile\n";
	}

}

sub CheckDataAvailable
{
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


##############################################################################################
#
#	This is where the code Starts
#
##############################################################################################

if ($Verbose){print "Starting Applicaton\n";}


Set_up_logit;
Set_up_mailit;

if ($Verbose){print " Reading Source data\n";}
GetData;
if ($Verbose){print " Completed Reading Source Data\n";}

if (-e $TargetFile)
{
	unlink $TargetFile or die "Cannot delete $TargetFile\n";
}
#open Target file
open (TARGET,">>$TargetFile")|| die "cannot open $TargetFile file";

#	write header info into file
if ($Verbose){print " Writing data to Target\n";}
print TARGET "######################################################################################\n";
print TARGET "#\n";
print TARGET "#	     risk.lookup - generated by RiskLookup.pl\n";
print TARGET "#      \n";
print TARGET "#\n";
print TARGET "#\n";
print TARGET "######################################################################################\n";
print TARGET "\n";

#       Class   Risk
print TARGET "table ClassRisk =\n";
print TARGET "\{\n"; 
foreach $Line (@data)
{
	@TmpArray = split(/,/, $Line);
	$Class = $TmpArray[0];
	$AppCrit = substr($TmpArray[1],0,length($TmpArray[1]) - 1,);
	if (length($AppCrit)==0)
	{
#		logit "There is no APP_CRITICALITY associated to $Class so this Class hass been ommited from the lookup\n";
#		logit "Please advise Monitoring GSD Assistance team of this\n";
#		print "There is no APP_CRITICALITY associated to $Class so this Class hass been ommited from the lookup \n";
#		print "Please advise Monitoring GSD Assistance team of this\n\n";
#		$Error = 1;
	}
	elsif (looks_like_number($Class))
	{


		print TARGET "	\{\"$Class\",\"$AppCrit\"\}\n";
	}
	else
	{
		logit "Unable to resolve the ClassStream lookup for $Class, $AppCrit\n";
		$Error = 1;

	}
}

print TARGET "\}\n";
if ($Verbose){print " Completed Writing Data to Target\n";}


close (TARGET);
chmod 0666,$TargetFile;
if ($Error)
{
	if ($Verbose){print "Errors Generated Please see log file ( $AppLogFile ) for further details\n";}
}

# So lets send the mail
#if (-e $AppMailFile)
#{
#	system("/sbclocal/netcool/omnibus/utils/gen_mail $MailRecipient $MailSummary $AppMailFile");
#}

if ($Verbose){print "Application Exiting\n";}
exit;
