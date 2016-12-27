#!/sbcimp/run/pd/perl/5.8.7/bin/perl -w
###################################################################################
#
# Script to Create GenerateClasses.sh
#
# Origional	14th August 2006	Chris Janes of Abilitec 
#
#
#
#
##################################################################################

BEGIN  {
    use Net::Domain qw(hostname hostfqdn);
    $ENV{LANG} = "C";
    $ENV{OMNIHOME} = qw(/sbclocal/netcool/omnibus);
    $ENV{SYBASE} = "$ENV{OMNIHOME}/platform/solaris2" if $^O eq "solaris";
    $ENV{SYBASE} = qw(/sbcimp/run/tp/sybase/OpenClientServer/v12.5) if $^O eq "linux";
    $ENV{SYBASE_OCS} = q(OCS-12_5) if $^O eq "linux";
}
##################################################################################
#
#	Get the modules we are going to use
#
#
##################################################################################


use Time::Local;
use IO::Handle;
use lib qw(//sbcimp/run/pd/perl/5.8.7/lib);
use DBI;
use DBD::Sybase;
use Cwd;
use File::Copy;
use File::Compare;
use File::Basename;

##################################################################################
#
# Configuration Settings (These are overwriten by any entries in the .gmconf file
#			  this lives in $OMNIHOME/etc)
#
##################################################################################

$Cwd = cwd;

$LastErrorFile=$Cwd . "/TempSQLTest.log";
$ErrorLogFile="/home/janesch/perl/WebTop_Check/error.log";


#	$SourceDir	the directory that has the original files
$SourceDir = "/sbclocal/netcool/webtop/config/entities/";


my @EntityList;
$FilterCount = 0;
$ErrorCount = 0;

##################################################################################
#
# 	Functions Go Here 
#
##################################################################################




##########################################################################################################
#
# This sub calls a shell script that tests the filter
#
##########################################################################################################






sub testSQL
{
my $filter = $_[0];
	system("$Cwd/TestSQL.sh \"$filter\" $Cwd");
}

##########################################################################################################
#
# This checks the entity
#
##########################################################################################################



sub CheckEntity
{
	my $File = $_[0];
	
my $EntityView;
our $DataGood;


#	This reads the whole entities group
	open (ENTITY,"$File") || die "Cannot open file $File at ";
	my @Entity_group = <ENTITY>;
	close ENTITY;
	
	# Sort through line by line for the target entity
	foreach my $Line (@Entity_group)
	{
		if ($Line =~ m/entity\(/)
		{
			#split the entity into it's constituant parts
			$FilterCount = $FilterCount + 1;
			my @Entity = split (/,/, $Line);
			foreach my $bit (@Entity)
			{
				if ($bit =~ m/entity\(name/)
				{
					$EntityName = substr ($bit, 12, );
				}
				elsif ($bit =~ m/view/)
				{
					#$EntityView = substr ($bit, 5 );
				}
				elsif ($bit =~ m/filter/)
				{
					$EntityFilter = substr ($bit, 8);
				}
				elsif ($bit =~ m/metriclabel/)
				{
					#$EntityMetricLabel = substr ($bit, 12);
				}
				elsif ($bit =~ m/metricshow/)
				{
					#$EntityMetricShow = substr ($bit, 11);
				}
				elsif ($bit =~ m/metricof/)
				{
					#$EntityMetricOf = substr ($bit, 8);
				}
				else
				{
					$EntityFilter = $EntityFilter . "," . $bit;
				}
			}
			$EntityFilter = substr ($EntityFilter,0,-1);
			
			# is the the entity to test
			if($EntityName =~ /$EntityToTest/)
			{
				system ("touch $LastErrorFile");
				open (LASTERROR,">>$LastErrorFile") || die "Cannot open file $LastErrorFile \n ";
	
#				print "File       = $File\n";
#				print "EntityName = $EntityName  \n";
				close LASTERROR;
				
				# Test the filter
				testSQL ($EntityFilter);
				
				# read in theresults of the test
				open (LASTERROR,"$LastErrorFile") || die "Cannot open file $LastErrorFile \n ";
				my @Lasterror = <LASTERROR>;
				close LASTERROR;
				
				#if it's an error then tell them so
				if($Lasterror[0] =~ /ERROR/)
				{
					$ErrorCount = $ErrorCount +1;
					print "We have a problem $ErrorCount Houston	\n";
					if (-e $LastErrorFile)
					{
						if (-e $ErrorLogFile)
						{}
						else
						{
							system ("touch $ErrorLogFile");
						}
					
					}
					open (ERRORLOG,">>$ErrorLogFile") || die "Cannot open file $ErrorLogFile \n ";
					print ERRORLOG "File       = $File\n";
					print ERRORLOG "EntityName = $EntityName\n";
					print ERRORLOG "EntityFilter = $EntityFilter\n\n";
					print "EntityFilter = $EntityFilter\n\n";
	
					foreach my $Line (@Lasterror)
					{
						print ERRORLOG "$Line";
					}
					print ERRORLOG "\n\n";
					close ERRORLOG;
				}
				else
				# if it's OK then tell them so
				{
					print " Entity $EntityGroupToTest $EntityToTest is OK\n";
				}
			}
		}
	}
}

sub ScanDir
{
	my $IpDir = $_[0];
	my $WorkDir = $SourceDir . $IpDir;
	my $Flag1 = 0;
	my $tmp;
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
			if (-d $Name )
			{
				my $SourceDirName = $SourceDir . $IpDir . $Name;
	
				# Does it exist in the Archive
	
		
				# Scan it
				my $DirToScan = $IpDir . $Name;
				ScanDir ($IpDir . $Name . "/");
				
			}
			if (-f $Name)
			{
				if ($Name =~ m/entity.group$/)
				{
					my $SourceFileName = $SourceDir . $IpDir . $Name;
#					print "SourceFileName = $SourceFileName\n";
					CheckEntity($SourceFileName);
				}
			}
		}
		
		chdir($StartDir);
	
}
	


sub main
{

	ScanDir("$EntityGroupToTest");

}


#Set folder that this Program is in (is used for temp files
$Cwd = cwd;

# Get the cmd line args for entitygroup and entity
$EntityGroupToTest = $ARGV[0] . "/";
$EntityToTest = $ARGV[1];

# run the real code
main;
