#!/sbcimp/run/pd/perl/5.8.7/bin/perl -w

# This Script is to Delete ISM Profiles older than 'n' Months
##############################################################################################
#
#	Get the Modules we are using
#
##############################################################################################

use Cwd;
use File::Copy;
use File::Compare;
use File::Basename;
use strict;


##############################################################################################
#
#	Set the Variables that we need to
#
##############################################################################################

my $yyyymm = "200802";
#	$SourceDir	the directory that has the original files
my $SourceDir = "/sbclocal/ism/ism/datalogs/";

#	$ArchiveDir	the directory that has the archive in it
my $ArchiveDir = "/sbclocal/archive/datalogs" . $yyyymm . "/";

#	$LogDir	the directory that has the archive in it
my $LogDir = "/home/janesch/perl/DataLogClear/Log/";

my $AppLogFile;

my $Debug = 1;
##############################################################################################
#
#	This is where the Functions Go
#
##############################################################################################


sub Normalise
{
	my $LocalVar = $_[0];
	if (length ($LocalVar) == 1)
	{
		$LocalVar = "0" . $LocalVar;
	}
	return ($LocalVar);
}

sub ScanDir
{
	my $IpDir = $_[0];
	my $WorkDir = $SourceDir . $IpDir;
	my $StartDir = cwd;
	chdir($WorkDir);
	my $temp = cwd;
	opendir(DIR, "$WorkDir") or die "Unable to open $WorkDir\n";
	my @Names = readdir(DIR) or die "Unable to read $WorkDir\n";
	closedir(DIR);
	
	foreach my $Name (@Names)
	{
		next if ($Name eq ".");
		next if ($Name eq "..");
		if (-d $Name )
		{
			#print "$Name\n";
			my $SourceDirName = $SourceDir . $IpDir . $Name;
			my $TargetDirName = $ArchiveDir . $IpDir . $Name;

			# Does it exist in the Archive

			if (-e $TargetDirName)
			{
				#if ($Debug) {print "Target dir exists \n";}
			}
			else
			{
			#If not Create it
				if ($Debug) {print " - NEW FOLDER $TargetDirName\n";}
				print APPLOG "Creating NEW Directory $IpDir$Name\n";
				mkdir $TargetDirName or die "mkdir $TargetDirName failed: $!";
			}
			
			# Scan it
			my $DirToScan = $IpDir . $Name;
			ScanDir ($IpDir . $Name . "/");
			
		}
		if (-f $Name)
		{
			if ($Name =~ m/$yyyymm.*\.xml$/)
			{
				print "   $Name";
				# Does this exist in the archive
				my $SourceFileName = $SourceDir . $IpDir . $Name;
				my $ArchiveFileName = $ArchiveDir . $IpDir . $Name;
				if (-e $ArchiveFileName)
				{
					#if ($Debug) {print "Target file exists \n";}
				}
				else
				{
					if ($Debug) {print " ------------  NEW FILE    $ArchiveFileName\n";}
					print APPLOG "Creating NEW File $IpDir$Name\n";
					move ($SourceFileName, $ArchiveFileName) or die "Move failed: $!";
				}
				# if it does exist is it the same
			}
		}
	}
	
	chdir($StartDir);

}

##############################################################################################
#
#	This is where the code Starts
#
##############################################################################################
#	Set up the log file
if (-e $LogDir)
{
	my $Min;
	my $Hour;
	my $Day;
	my $Month;
	my$Year;

#	Build the logfile name
	($Min, $Hour, $Day, $Month, $Year) =(localtime)[1,2,3,4,5];

	$Min = Normalise $Min;
	$Hour = Normalise $Hour;
	$Day = Normalise $Day;
	$Month = Normalise $Month;
	
	my $LogFileName = ($Year + 1900) . ($Month + 1) . $Day . $Hour . $Min . ".log";

	$AppLogFile =  $LogDir .$LogFileName;
	
#	open the logfile
	open (APPLOG,">>$AppLogFile")|| die "cannot open $AppLogFile file";
	print APPLOG "Opened log file \n";

	if (-e $ArchiveDir)
	{
		# the Archive Directory already exists
	}
	else
	{
		if($Debug){print"Creating Archive Directory $ArchiveDir\n";}
		mkdir $ArchiveDir or die "mkdir $ArchiveDir failed: $!";
	}

	ScanDir ("");
	
#	Close the log file	
	close (APPLOG);

}
else
{
	print "Logging Directory ( $LogDir ) doe not exist\n";
}
