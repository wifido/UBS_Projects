#!/sbcimp/run/pd/perl/5.8.7/bin/perl -w
   
##############################################################################################
#
# 	This is a template for perl scripting
# 
#
#	Original	Chris Janes	20xxxxxx
#
##############################################################################################

   BEGIN {


#      $ENV{ ORACLE_HOME } = "/sbcimp/run/tp/oracle/client/v9.2.0.4.0-32bit";
#      $ENV{ TNS_ADMIN   } = "/sbcimp/run/pkgs/oracle/config";
#      $ENV{LANG} = "C";
#      $ENV{OMNIHOME} = qw(/sbclocal/netcool/omnibus);
#      $ENV{SYBASE} = qw(/sbcimp/run/tp/sybase/OpenClientServer/v12.5);
#      $ENV{SYBASE_OCS} = q(OCS-12_5);
#      $ENV{PERL5LIB} = "";

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

#use lib "/sbcimp/run/pd/cpan/5.8.5-2004.09/lib";


#use DBI;
#use DBD::Sybase;
#use DateTime;
#use Switch;
#use Scalar::Util qw(looks_like_number);
#use File::Path;



##############################################################################################
#
#	Set the Variables that we need to
#
##############################################################################################

# Variables require for my standard log functions

#	$LogDir	the directory that has the archive in it
my $AppLogPath = "/home/janesch/Log/";
#	$AppLogFileName the directory that has the log file in it
my $AppLogFileName = "applogfile.log";
#	$AppLogFile if the file to be used for logging by this scripts 
my $AppLogFile = $AppLogPath . $AppLogFileName;
#	$MaxLogFileSize Max sizze of this apps log file
my $MaxLogFileSize = 200000;
#	$DoLogging set to 1 f you want this app to log or 0 if you don't
my $DoLogging = 0;

my $Verbose = 0;

my $Error = 0;


##############################################################################################
#
#	This is where the Functions Go
#
##############################################################################################



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




##############################################################################################
#
#	Startup and initialise as required
#
##############################################################################################


if ($Verbose){print "Starting $0 Applicaton\n";}
Set_up_logit();
if ($DoLogging){logit "Starting $0 Applicaton\n";}


##############################################################################################
#
#	This is where the code Starts
#
##############################################################################################








##############################################################################################
#
#	Now Gracefully exit
#
##############################################################################################



if ($Error)
{
	if ($Verbose){print "Errors Generated Please see log file ( $AppLogFile ) for further details\n";}
}
if ($Verbose){print "Application $0 Exiting\n";}
if ($DoLogging){logit "Application $0 Exiting\n";}
exit;
