#!/sbcimp/run/pd/perl/5.8.7/bin/perl -w

# This Script is to Archive selected files from Micromuse boxes to a Clearcase VOB

##############################################################################################
#
#	Get the Modules we are using
#
##############################################################################################

use Cwd;
use File::Copy;
use File::Compare;
use File::Basename;
use DateTime;


##############################################################################################
#
#	Set the Variables that we need to
#
##############################################################################################

#	$SourceDir	the directory that has the original files
$SourceDir = "/sbclocal/ism/ism/profiles/";

#	$ArchiveDir	the directory that has the archive in it
#$ArchiveDir = "/home/janesch/perl/AdoptionDB/";

#	$LogDir	the directory that has the archive in it
$LogDir = "/home/janesch/perl/AdoptionDB/Log/";


#	$UsingCC this is 1 if using 0 if not
my $atime;
my $mtime;
my $ctime;
my $identifier;
my $notification;


##############################################################################################
#
#	This is where the Functions Go
#
##############################################################################################





sub ScanDir
{
	my $IpDir = $_[0];
	my $WorkDir = $SourceDir . $IpDir;
	# sdfjsdlks
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
		next if ($Name =~ m/lookuptables\./);
		next if ($Name =~ m/lookuptables2/);
		if (-d $Name )
		{
			print "DIR $Name\n";
			
		}
		if (-f $Name)
		{
			if ($Name =~ m/.*\.xml$/)
			{
				print "   $Name\n";
				my $WorkFile = $WorkDir . "/" . $Name;
				my @FileStat = stat($WorkFile);
				$atime = localtime($FileStat[8]);
				$mtime = localtime($FileStat[9]);
				$ctime = localtime($FileStat[10]);
                open (TESTFILE, $WorkFile)|| die "cannot open $WorkFile file";
                my @TestFile = <TESTFILE>;
                close (TESTFILE);
                foreach $Line (@TestFile)
                {
                	if ($Line =~ m/<identifier>.*<\/identifier>/)
                	{
                		$Line =~ s/<identifier>//;
                		$Line =~ s/<\/identifier>//;
                		$Line =~ s/^\s+//g;
                		$Line =~ s/\s+$//g;
                		$identifier = $Line;
                	}
                	if ($Line =~ m/<notification>.*<\/notification>/)
                	{
                		$Line =~ s/<notification>//;
                		$Line =~ s/<\/notification>//;
                		$Line =~ s/^\s+//g;
                		$Line =~ s/\s+$//g;
                		$notification = $Line;
                	}
                }
				print "   $WorkFile\n";
				
			}
		}
	}
}

##############################################################################################
#
#	This is where the code Starts
#
##############################################################################################
#	Set up the log file
if (-e $LogDir)
{
#	Build the logfile name
#	($Min, $Hour, $Day, $Month, $Year) =(localtime)[1,2,3,4,5];

#	$Min = Normalise $Min;
#	$Hour = Normalise $Hour;
#	$Day = Normalise $Day;
#	$Month = Normalise $Month;
	
	$LogFileName = "ISM_Moniitor.log";

	$AppLogFile =  $LogDir .$LogFileName;
	
#	open the logfile
	open (APPLOG,">>$AppLogFile")|| die "cannot open $AppLogFile file";
	print APPLOG "Opened log file \n";


	ScanDir ("active");
	
#	Close the log file	
	close (APPLOG);

}
else
{
	print "Logging Directory ( $LogDir ) doe not exist\n";
}
