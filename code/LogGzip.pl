#!/sbcimp/run/pd/perl/5.8.7/bin/perl -w
#!/sbclocal/netcool/omnibus/utils/perllib/MUSE_PERL_PROD/bin/perl -w

##############################################################################################
#
# This Script maintains an archive of old log files
#
#	Original	Chris Janes	20070705
#
#
#
#
##############################################################################################


##############################################################################################
#
#	Get the Modules we are using
#
##############################################################################################


use strict;
use Compress::Zlib;
use File::Copy;
use File::Compare;
use File::Basename;


##############################################################################################
#
#	Set the Variables that we need to
#
##############################################################################################

#		$AppLogPath	logfile  path
our $AppLogPath = "/sbclocal/netcool/omnibus/log/";

#		$AppLogName	logfile  name
our $AppLogName	= "LogGzip.log";

#		$AppLogFile	logfile including path
our $AppLogFile = $AppLogPath . $AppLogName;

#		$MaxLogFileSize  logfile size
our $MaxLogFileSize = 100000;

#		$TargetPath	logfile  path
our $TargetPath = "/sbclocal/ism/log/ism/";


#		$DoLogging	logging enables (1) or disables (0)
our $DoLogging = 1;

my $MaxNoFiles = 10;
my $Debug = 0;

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
#		$DoLogging	logging enables (1) or disables (0)
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
#		$MaxLogFileSiz  logfile size
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
			
	my @logfilestat  = stat($AppLogFile);
	if ($logfilestat[7] > $MaxLogFileSize)
	{
		my $AppLogFileBackup = $AppLogFile."_old";
		if (-e $AppLogFileBackup)
		{
			unlink $AppLogFileBackup or DieHere "Cannot delete $AppLogFileBackup\n";
		}
		system("mv $AppLogFile $AppLogFileBackup");
	}

}

sub gzipper
{
#################################################################################
#
#	This sub gzips a file
#	usage:	gzipper <FILENAME inc PATH>
#	Required Global Variables
#		Debug	if set to 1 debug output is printed
#
#	Require Modules
#		use Compress::Zlib;
#
#################################################################################
	
	my $file  = $_[0];

	my $gzfile = "";

#	does the file exist
	if (-e $file) 
	{
		logit "Archiving $file $!";
#		open the target file
		$gzfile = $file.".gz_1";
		open (FILE, $file);
		binmode FILE;

		my $buf;
		my $gz = gzopen($gzfile, "wb");
		if (! $gz) 
		{
   			logit "Unable to write $gzfile $!";
   			exit;
		}
		else 
		{
   			while (my $by = sysread (FILE, $buf, 4096)) 
   			{
#				make the file
      				if (! $gz->gzwrite($buf)) 
      				{
        		 		logit "Zlib error writing to $gzfile: $gz->gzerror\n";
        		 		exit;
      				}
   			}
#			close the target file
   			$gz->gzclose();
   			logit "$file GZipped to '$gzfile";
		}
	
	}
	else	
	{
   		logit "$0 <file>\n";
   		exit;
	}
#	check the new file exists
	if (-e $gzfile)
	{
#		remove the origional
		unlink $file or DieHere "Cannot delete $file\n";
	}
	else
	{
		DieHere "Cannot write $gzfile\n";
	}
}

sub ArchiveShuffle
{
#################################################################################
#
#	This sub maintains an archive stack
#	usage:	ArchiveShuffle <FILENAME inc PATH>, <MaxNoArchives>
#	Required Global Variables
#		Debug	if set to 1 debug output is printed
#
#	Require Modules
#		None
#
#################################################################################
	if($Debug){ print "Entered ArchiveShuffle\n";}

	my $file = $_[0] . ".gz";
	if($Debug){ print "file $file\n";}
	
#	lose the last archive if it exists
	my $LastArcFile = $file . "_" . $MaxNoFiles;

#	check the  file exists
	if (-e $LastArcFile)
	{
#		if it does lose it
		if($Debug){ print "unlink $LastArcFile\n";}
#		remove it
		unlink $LastArcFile or DieHere "Cannot delete $LastArcFile\n";
	}

#	move all the other archives down one
	my $Count = 0;
	my $Count1 = 0;
	for($Count = $MaxNoFiles;  $Count >0; $Count = $Count -1)
	{
		if($Debug){ print "Count $Count\n";}
		$Count1 = $Count + 1;
		my $SourceFileName = $file . "_" . $Count;
		my $TargetFileName = $file . "_" . $Count1;
#		if($Debug){ print "SourceFileName $SourceFileName\n";}
#		if($Debug){ print "TargetFileName $TargetFileName\n";}
		
		if (-e $SourceFileName)
		{
			if($Debug){print "mv $SourceFileName $TargetFileName\n";}
			my $Temp = system("mv $SourceFileName $TargetFileName");
		}
	}
		

}

sub ZipandArchive
{
#################################################################################
#
#	This sub takes a file and if requires creates an archive and shuffles
#		the older archives from this file
#	usage:	ZipandArchive <FILENAME inc PATH
#	Required Global Variables
#		Debug	if set to 1 debug output is printed
#
#	Required Modules
#		None
#
#	
#
#################################################################################

	my $File2Process = $_[0];
	#	check the  file exists
	if (-e $File2Process)
	{
		if($Debug){ print "Shuffle as  $File2Process exists\n";}
		ArchiveShuffle $File2Process;
		gzipper ($File2Process);
	}
}


sub ScanDir
{
#################################################################################
#
#	This sub takes a directory and finds any old log files that require archiving
#	usage:	ScanDir <DIR_PATH>
#	Required Global Variables
#		Debug	if set to 1 debug output is printed
#
#	Required Modules
#		None
#
#	
#
#################################################################################

	my $WorkDir = $_[0];
	chdir($WorkDir);
	opendir(DIR, "$WorkDir") or die "Unable to open $WorkDir\n";
	my @Names = readdir(DIR) or die "Unable to read $WorkDir\n";
	closedir(DIR);
	
	foreach my $Name (@Names)
	{
		next if ($Name eq ".");
		next if ($Name eq "..");
		if (-f $Name)
		{
			if ($Name =~ m/.*_old$/)
			{
				my $CompletFileName = $WorkDir . $Name;
				if($Debug){ print "   $CompletFileName\n";}
				ZipandArchive $CompletFileName;
			}
		}
	}
	

}

#################################################################################
#
#
#		This is where we set up our working enviroment
#
#
#################################################################################




Set_up_logit;

#################################################################################
#
#
#		This is where we start the coding for real
#
#
#################################################################################

#my $cjfile = "/home/janesch/perl/LogGzip/testfile.log_old";
#ScanDir ("/home/janesch/perl/LogGzip/");
ScanDir ($TargetPath);

