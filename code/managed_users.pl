#!/sbcimp/run/pd/perl/32-bit/5.8.8/bin/perl


####!/sbcimp/run/pd/perl/5.8.7/bin/perl -w
###################################################################################
#
# Script to list all ObjectServer SuperUsers are with the information
# required by 
#
# Origional	20081008	Chris Janes of Abilitec  
#						1st Beta copy
# V 1.0		20081016	Chris Janes of Abilitec
#						Initial release to Production
#
#
##################################################################################

BEGIN  {
    use Net::Domain qw(hostname hostfqdn);
    $ENV{ ORACLE_HOME } = "/sbcimp/run/tp/oracle/client/v9.2.0.4.0-32bit";
    $ENV{ TNS_ADMIN   } = "/sbcimp/run/pkgs/oracle/config";
    $ENV{LANG} = "C";
    $ENV{OMNIHOME} = qw(/sbclocal/netcool/omnibus);
    $ENV{SYBASE} = "$ENV{OMNIHOME}/platform/solaris2" if $^O eq "solaris";
    $ENV{SYBASE} = qw(/sbcimp/run/tp/sybase/OpenClientServer/v12.5) if $^O eq "linux";
    $ENV{SYBASE_OCS} = q(OCS-12_5) if $^O eq "linux";
    $ENV{PERL5LIB} = "";

}
##################################################################################
#
#	Get the modules we are going to use
#
#
##################################################################################

#use lib "/sbcimp/run/pd/cpan/5.8.5-2004.09/lib";

use Time::Local;
use IO::Handle;
#use lib qw(//sbcimp/run/pd/perl/5.8.7/lib);
use lib qw( /sbcimp/run/pd/cpan/32-bit/5.8.8-2007.09/lib );
use DBI;
use DBD::Sybase;

##################################################################################
#
# Configuration Settings (These are overwriten by any entries in the .gmconf file
#			  this lives in $OMNIHOME/etc)
#
##################################################################################


# MaxLogFileSize - Maximum size of the logfile
$MaxLogFileSize=1000000;

# PathAppLogFile - Location of this apps logfile
#$PathAppLogFile="/sbclocal/netcool/omnibus/log/";
$PathAppLogFile="/home/janesch/perl/ManagedUsers/";

# Raise an Event if 1
#$RaiseEvent = 0;

# Log to file if 1 
#$LogEvent = 1;
#$ShowEvent = 1;

# Log Detail to file if 1 
#$LogDetail = 1;

$TargetFile = "micromuse.csv";

$Verbose = 1;
# SleepTime - the period that this app sleeps between loops in seconds
#$Sleeptime = 600;

our @data;
##################################################################################
#
# Functions Go Here 
#
##################################################################################


sub GetAdoptData
{
	my $dbh;
	my $CLASS_ID;
	my $GROUP_ID;

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
	
#	my $sthOracle = $dbh->prepare("select * from managed_users") || die $dbh->errstr;
	my $sthOracle = $dbh->prepare("select OwnerUID, Gpin, User_ID, Type, Profile, Status, Email from managed_users") || die $dbh->errstr;
	
	$sthOracle->execute() || die $sthOracle->errstr;
	while (my (@nodeOracle) = $sthOracle->fetchrow_array) 
	{
			$OwnerUID = $nodeOracle[0];
			$Gpin = $nodeOracle[1];
			$User_ID = $nodeOracle[2];
			$Type = $nodeOracle[3];
			$Profile = $nodeOracle[4];
			$Status = $nodeOracle[5];
			$Email = $nodeOracle[6];
			$Adopt_Hash{$OwnerUID} = $Gpin . "," . $User_ID . "," . $Type . "," . $Profile . "," . $Status . "," . $Email . "," ;

	}
	$sthOracle->finish;
	$dbh->disconnect();
	
}

#
# This writes to the Record to the App Log File
#
sub logit
{
	my $str = $_[0];
	chomp $str;
	my $error_str = $str . " " . localtime(time) . "\n";
	open (APPLOG,">>$AppLogFile")|| die "cannot open $AppLogFile file";
	print APPLOG $error_str;
	close (APPLOG);
}

#
# This writes detail to the App Log File
#
sub logDetail{
	my $str = $_[0];
	chomp $str;
	my $error_str = "    " . $str  . "\n";
	open (APPLOG,">>$AppLogFile")|| die "cannot open $AppLogFile file";
	print APPLOG $error_str;
	close (APPLOG);
}

##########################################################################################################
#
# This connects to the Object servers Database, it requires an argument of the onbserv it is connecting to
#
##########################################################################################################

sub osConnect  
{
#print"osConnect\n";
	my $oserv = shift;
	my $username = "root";
	my $password = "clutt3r";
	my %attr = (
        	syb_flush_finish => 1,
        	AutoCommit => 1,
        	ChopBlanks => 1,
        	PrintError => 0,
        	RaiseError => 0,
		TraceLevel => 0
	);
#	logit("LOG_INFO, Attempting connection to Object Server " . $oserv . "\n");
#print"get db\n";
#my $OSConnectString = "DBI:Sybase:server=$oserv;interfaces=$ENV{OMNIHOME}/etc/interfaces.$ostype;scriptName=ConnectionMonitor;loginTimeout=10," . $username . "," . $password . "," . \%attr;

#	my $db = DBI->connect($OSConnectString) or print "LOG_INFO_1  $DBI::errstr \n";
	my $db = DBI->connect("DBI:Sybase:server=$oserv;interfaces=$ENV{OMNIHOME}/etc/interfaces.$ostype;scriptName=ConnectionMonitor;loginTimeout=10",$username,$password,\%attr) or print "LOG_INFO_1  $DBI::errstr \n";
#print"got db\n";
	return ($db);
}

##########################################################################################################
#
# This disconnects from the Object servers Database
#
##########################################################################################################

sub osDisconnect  {

# print"osDisconnect\n";
	$dbh->disconnect;
}

##########################################################################################################
#
# This inserts an event to the Object servers Database
#
##########################################################################################################



#
# when passed the hostname it returns $node and $nodealias
#

sub getHostInfo  
{
    my $host = shift;
    my ($name, $aliases, $addrtype, $length, @addrs) = gethostbyname($host);
    my @addr = unpack('C4',$addrs[0]);
    return(join(".", @addr), $name);
}


##################################################################################
#
# osRaiseEvent this raise and event in an objectserver
#
##################################################################################

sub osRaiseEvent
{

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
    $objserv = $osmap{hostname()};

# Open Connection to database
$dbh = osConnect($objserv);

# Insert an Event into the database
#osInsertEvent;

# Disconnect from the database
osDisconnect;
}


sub GetOSUser
{
	my $user_id = $_[0];
	my $user_name ;
	
	
#	create the SQL string
	$stmt = "select UID from master.names where UID = " . $user_id;
	my $ret = 1;
	if ( $ret == 1)  
	{
#	do the prepare execute sruff
		$sth = $dbh->prepare($stmt);
		if (my $rets = $sth->execute())  
		{
			while ( my @rows = $sth->fetchrow_array() ) 
			{
				foreach $row (@rows)
				{
					$user_name = $row;
				}
			}
		}
	}
	return  $user_name;
}
	
	
sub osNumClients
{
#print"osNumClients\n";
#	create the SQL string
	$stmt = "select UID from master.names where Type = 1 ";

#	check the server is there
	my $ret = 1;
	if ( $ret == 1)  
	{
#	do the prepare execute sruff
		$sth = $dbh->prepare($stmt);
		if (my $rets = $sth->execute())  
		{
			my $NoRows = $sth->rows;
			if (-e $TargetFile)
			{
				unlink $TargetFile or die "Cannot delete $TargetFile\n";
			}
			open (TARGET ,">>$TargetFile")|| die "cannot open $TargetFile file";
			print TARGET "User,GPIN,Type,Profile,Status,Email\n";;

			while ( my @rows = $sth->fetchrow_array() ) 
			{
				foreach $row (@rows)
				{
					if (defined $Adopt_Hash{$row})
					{
						@UserData = split(/\,/,$Adopt_Hash{$row});
						if ($Verbose){print "$UserData[1],$UserData[0],$UserData[2],$UserData[3],$UserData[4],$UserData[5]\n";}
						if ($UserData[4] =~ m/Active/)
						{
							print TARGET "$UserData[1],$UserData[0],$UserData[2],$UserData[3],$UserData[4],$UserData[5]\n";
						}
						else
						{
							print  " User_id $row is not Active  $UserData[4]\n";
							print TARGET " User_id $row is not Active  \n";
						}
					}
					else 
					{
						print  " User_id $row is not defined  \n";
						print TARGET "@@@@@@@@@@@@@@@@@@@@ User_id $row is not defined  @@@@@@@@@@@@@@@@@@@@\n";
					}
				}
			}
			close (TARGET);
			return($rets);
		}
	}
	else
	{
		print "Object server not available\n";
		return($ret);
	}
}

sub chkLogSize
{
# Make sure the log file is an acceptable size

        if (-e $AppLogFile)
        {
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
}


sub cons
{
#print "cons\n";

	$AppLogFile = $PathAppLogFile . "ManagedUsers" . hostname(). ".log";

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
#               xstm5257dap => "STMOBJTEST1",
               xstm5257dap => "LDNOBJPROD1",
               xldn2929dap => "LDNOBJENG1",
               xstm1953dap => "STMOBJENG1",
               xstm1315pap => "STMOBJPHBT1"
             );
    $ostype = $ostypes{$^O};
#    $objserv = $osmap{hostname()};
    $objserv = "LDNOBJPROD1";

	# Open Connection to database

	$dbh = osConnect($objserv);
	osNumClients;
	osDisconnect;
	chkLogSize;
}

# This bit for testing
#for (;;)
#{
#	cons();
#	sleep $Sleeptime;
#}


# This bit to run as a one shot deal
GetAdoptData;
cons();
