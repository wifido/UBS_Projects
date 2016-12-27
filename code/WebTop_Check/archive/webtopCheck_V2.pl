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


# MaxLogFileSize - Maximum size of the logfile
$MaxLogFileSize=10000;

# PathAppLogFile - Location of this apps logfile
#$PathAppLogFile="/sbclocal/netcool/omnibus/log/";
$PathAppLogFile="/home/janesch/perl/WebTop_Check/entity.lst";
#$LastErrorFile="/home/janesch/perl/WebTop_Check/error.txt";
$LastErrorFile="/home/janesch/rules/TempSQLTest.log";
$ErrorLogFile="/home/janesch/perl/WebTop_Check/error.log";

# PathTargetFolder - Location of this Target files
$PathTargetFolder="/home/janesch/perl/GenClass/";

#	$SourceDir	the directory that has the original files
$SourceDir = "/home/janesch/rules/entities/";

my @EntityList;

##################################################################################
#
# 	Functions Go Here 
#
##################################################################################


##########################################################################################################
#
# This connects to the Object servers Database, it requires an argument of the onbserv it is connecting to
#
##########################################################################################################

sub osConnect  {
	my $oserv = shift;
	my $username = "scriptuser";
	my $password = "omnibus";
	my %attr = (
        	syb_flush_finish => 1,
        	AutoCommit => 1,
        	ChopBlanks => 1,
        	PrintError => 0,
        	RaiseError => 0,
		TraceLevel => 0
	);

	
	my $db = DBI->connect("DBI:Sybase:server=$oserv;interfaces=$ENV{OMNIHOME}/etc/interfaces.$ostype;scriptName=EntityTest;loginTimeout=10",$username,$password,\%attr) or print "LOG_INFO_1  $DBI::errstr \n";
	return ($db);
}

##########################################################################################################
#
# This disconnects from the Object servers Database
#
##########################################################################################################

sub osDisconnect  {
	$dbh->disconnect;
}

##########################################################################################################
#
# This inserts an event to the Object servers Database
#
##########################################################################################################






sub testSQL
{
my $filter = $_[0];
	system("/home/janesch/scripts/TestSQL/TestSQL.sh \"$filter\"");
}

sub chkLogSize
{
# Make sure the log file is an acceptable size

        @logfilestat  = stat($AppLogFile);
        if ($logfilestat[7] > $MaxLogFileSize)
        {
                $AppLogFileBackup = $AppLogFile."old";
                if (-e $AppLogFileBackup)
                {
                        unlink $AppLogFileBackup or die "Cannot delete $AppLogFileBackup\n";
                }
                system("mv $AppLogFile $AppLogFileBackup");
        }
}



sub CheckEntity
{
	my $File = $_[0];
	
my $EntityView;
our $DataGood;

	# This bit to run as a one shot deal


    %ostypes = ( linux => "linux2x86",
                 solaris => "solaris2"
               );


    %osmap = ( xldn0064pap => "LDNOBJPROD1",
               xldn0065pap => "LDNOBJPROD1",
               xldn1014pap => "LDNOBJPROD1",
               xldn1017pap => "LDNOBJPROD1",
               xldn1018pap => "LDNOBJPROD1",
               xopf0100pap => "LDNOBJPROD1",
               xopf0101pap => "LDNOBJPROD1",
               xsng1001pap => "LDNOBJPROD1",
               xstm8950pap => "STMOBJPROD1",
               xstm8951pap => "STMOBJPROD1",
               xstm8027pap => "STMOBJPROD1",
               xstm9838dap => "STMOBJTEST1",
               xldn1052dap => "LDNOBJENG1",
               xstm1953dap => "STMOBJENG1"
             );
    $ostype = $ostypes{$^O};

#	open a new file
	open (ENTITY,"$File") || die "Cannot open file $File at ";
	my @Entity_group = <ENTITY>;
	close ENTITY;
	foreach my $Line (@Entity_group)
	{
		if ($Line =~ m/entity\(/)
		{
			my @Entity = split (/,/, $Line);
			foreach my $bit (@Entity)
			{
				if ($bit =~ m/entity\(name/)
				{
					$EntityName = substr ($bit, 12, );
				}
				elsif ($bit =~ m/view/)
				{
					$EntityView = substr ($bit, 5 );
				}
				elsif ($bit =~ m/filter/)
				{
					$EntityFilter = substr ($bit, 8);
				}
				elsif ($bit =~ m/metriclabel/)
				{
					$EntityMetricLabel = substr ($bit, 12);
				}
				elsif ($bit =~ m/metricshow/)
				{
					$EntityMetricShow = substr ($bit, 11);
				}
				elsif ($bit =~ m/metricof/)
				{
					$EntityMetricOf = substr ($bit, 8);
				}
				else
				{
					$EntityFilter = $EntityFilter . "," . $bit;
				}
			}
			$EntityFilter = substr ($EntityFilter,0,-1);
			
			system ("touch $LastErrorFile");
			open (LASTERROR,">>$LastErrorFile") || die "Cannot open file $PathAppLogFile \n ";

			print "File       = $File\n";
			print "EntityName = $EntityName\n";
#			print "EntityView = $EntityView\n";
			print "EntityFilter = $EntityFilter\n\n";
#			print "EntityMetricLabel = $EntityMetricLabel\n";
#			print "EntityMetricShow = $EntityMetricShow\n";
#			print "EntityMetricOf = $EntityMetricOf\n";
#			$DataGood = 0;
			close LASTERROR;

			testSQL ($EntityFilter);

			open (LASTERROR,"$LastErrorFile") || die "Cannot open file $LastErrorFile \n ";
			my @Lasterror = <LASTERROR>;
			close LASTERROR;
			print "Lasterror = $Lasterror[0] \n";
			if($Lasterror[0] =~ /ERROR/)
			{
				print "We have a problem Houston\n";
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

				foreach my $Line (@Lasterror)
				{
					print ERRORLOG "$Line";
				}
				print ERRORLOG "\n\n";
				close ERRORLOG;
				

			}
			else
			{
				print"This one OK \n\n";
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
#				print "$Name";
				my $SourceDirName = $SourceDir . $IpDir . $Name;
	
				# Does it exist in the Archive
	
		
				# Scan it
				my $DirToScan = $IpDir . $Name;
				ScanDir ($IpDir . $Name . "/");
				
			}
			if (-f $Name)
			{
				$Flag1 = 0;
				foreach my $Entry (@EntityList)
				{
					$tmp = substr($Entry,0,-1);
					if ( $IpDir eq $Entry)
					{
						$Flag1 = 1;
					}
				}
					
				if (($Name =~ m/entity.group$/)&&($Flag1 == 0))
				{
					open (ENTITYLST,">>$PathAppLogFile") || die "Cannot open file $PathAppLogFile \n ";
					print ENTITYLST "$IpDir\n";
#					print "$IpDir $Name\n";
					close ENTITYLST;
					my $SourceFileName = $SourceDir . $IpDir . $Name;
					print "$SourceFileName\n";
					CheckEntity($SourceFileName);
				}
			}
		}
		
		chdir($StartDir);
	
}
	
sub GetEntityList
{
my $tmp;
	if (-e $PathAppLogFile)
	{
	}
	else
	{
		system ("touch $PathAppLogFile");
	}
	open (ENTITYLST,"$PathAppLogFile") || die "Cannot open file $PathAppLogFile \n ";
	my @FirstEntityList = <ENTITYLST>;
	close ENTITYLST;
	foreach my $entity (@FirstEntityList)
	{
		$tmp = substr($entity,0,-1);
		push (@EntityList, $tmp)
	}
}

sub GetLastError
{
#$LastErrorFile="/home/janesch/perl/WebTop_Check/error.txt";
#$ErrorLogFile="/home/janesch/perl/WebTop_Check/error.log";
	if (-e $LastErrorFile)
	{
		if (-e $ErrorLogFile)
		{}
		else
		{
			system ("touch $ErrorLogFile");
		}
		open (LASTERROR,"$LastErrorFile") || die "Cannot open file $LastErrorFile \n ";
		my @Lasterror = <LASTERROR>;
		close LASTERROR;
		open (ERRORLOG,">>$ErrorLogFile") || die "Cannot open file $ErrorLogFile \n ";

		foreach my $Line (@Lasterror)
		{
			print ERRORLOG "$Line";
		}
		close ERRORLOG;
	}

}

sub main
{

	ScanDir("");

}

main;


#my $filter = "class = 999999";
#system(testSQL ("AlertGroup != 'Autosys' and Manager not in ('SecurityWatch','ConnectionWatch') and (NodeAlias = 'xstm8950pap.stm.swissbank.com' or NodeAlias = 'xstm8950pap' or Node = 'xstm8950pap.stm.swissbank.com' or Node = 'xstm8950pap' )");
#testSQL $filter;


