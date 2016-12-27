#!/sbcimp/run/pd/perl/5.8.7/bin/perl -w
###################################################################################
#
# Script to Monitor Netcool Omibus Gateways 
#
# Origional	8th june 2005	Chris Janes of Abilitec 
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

##################################################################################
#
# Configuration Settings (These are overwriten by any entries in the .gmconf file
#			  this lives in $OMNIHOME/etc)
#
##################################################################################


# MaxLogFileSize - Maximum size of the logfile
#$MaxLogFileSize=1000000;

# PathAppLogFile - Location of this apps logfile
#$PathAppLogFile="/sbclocal/netcool/omnibus/log/";
$PathAppLogFile="/home/janesch/perl/latency/";


# SleepTime - the period that this app sleeps between loops in seconds
#$Sleeptime = 600;


##################################################################################
#
# Functions Go Here 
#
##################################################################################

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

sub osConnect  {
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
	my $db = DBI->connect("DBI:Sybase:server=$oserv;interfaces=$ENV{OMNIHOME}/etc/interfaces.$ostype;scriptName=LatencyCheck;loginTimeout=10",$username,$password,\%attr) or print "LOG_INFO_1  $DBI::errstr \n";
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


#sub osInsertEvent  {
#	my ($sth, $stmt);
#	my ($id, $nodealias, $node, $agent, $mgr, $group, $key, $summary, $nod, $noda, $ident);
#	my ($time, $reg, $locn, %locs, %locreg, $lc, $rg);
#	%locs = (   ldn => 'London',
#		stm => 'Stamford',
#		opf => 'Opfikon',
#		sng => 'Singapore'
#	);
#	%locreg = ( ldn => 'EMEA',
#		stm => 'Americas',
#		opf => 'Switzerland',
#		sng => 'Asia Pacific'
#	);
## Set up default values hash out if setting them else where
#	$Group = "Connection Monitor";
#	#$Key = "WriterName";
#	$Mgr = "NumClientWatch";
##	$Summary = "Test Event Please Ignore - janesch";
##	$ExpireTime = 1200;
##	$Severity = 5;
#	$Agent = "janesch";
#	$Type = 0; 
#	($node, $nodealias) = getHostInfo(hostname());
#	$locn = $locs{substr($nodealias, 1, 3)};
#	$reg = $locreg{substr($nodealias, 1, 3)};
##	Format vars for the database (sort out the '" stuff)
#	$lc = $dbh->quote($locn);
#	$rg = $dbh->quote($reg);
#	$nod = $dbh->quote($node);
#	$noda = $dbh->quote($nodealias);
#	$agent = $dbh->quote($Agent);
#	$mgr = $dbh->quote($Mgr);
#	$group = $dbh->quote($Group);
#	$key = $dbh->quote($Key);
#	$summary = $dbh->quote($Summary);
#	$time = time();
#	$type = $Type;
#	$ident = $nodealias . $Agent . $Group . $Key . $Type;
#	$id = $dbh->quote($ident);
#	$severity = $Severity;
#	$expiretime = $ExpireTime;
##	create the SQL string
#	$stmt = qq{insert into alerts.status (Identifier, FirstOccurrence, LastOccurrence, #NodeAlias, Node, Agent, Manager, OwnerGID, OwnerUID, Class, AlertGroup, AlertKey, Severity, #Summary, Type, Location, Region, ExpireTime)
#		values
#			($id, $time, $time, $noda, $nod, $agent, $mgr, 591, 65534, 0, $group, #$key, $severity, $summary, $type, $lc, $rg, $expiretime)
#		updating
#			(Summary, AlertKey, Location);};
##	check the server is there
#	if (my $ret = $dbh->ping)  {
##	do the prepare execute sruff
#		$sth = $dbh->prepare($stmt);
#		if (my $rets = $sth->execute())  
#		{
#			return($rets);
#		}
#		else  
#		{
#			logit "Failed to insert Event";
#			return($rets);
#		}
#	}
#	else
#	{
#		logit "Object server not available";
#		return($ret);
#	}
#}

#
# when passed the hostname it returns $node and $nodealias
#

sub getHostInfo  {
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

sub osGetLatency
{
	$Manager = $_[0];
	$ProbeHostName = $_[1];
	
#	create the SQL string
#	$stmt = "users";
	$stmt = "select top 10 LastOccurrence, StateChange from alerts.status where ProbeHostName like '$ProbeHostName' and Manager like '$Manager' order by LastOccurrence desc"; 
#	check the server is there
	my $ret = 1;
	if ( $ret == 1)  {
#	do the prepare execute sruff
		$sth = $dbh->prepare($stmt);
		if (my $rets = $sth->execute())  
		{

			my $NoRows = $sth->rows;
			$count = 0;
			$tally = 0;
			while ( my @row = $sth->fetchrow_array() ) 
			{
				$count++;
				$LastOccurrence = $row[0];
				$StateChange = $row[1];
				$Diff = $StateChange - $LastOccurrence;
				$tally = $tally + $Diff;
#				print "count $count $LastOccurrence $StateChange $Diff\n";
			}
			$ave = int($tally / $count);
#			print "$objserv Ave Latency for $ProbeHostName $Manager is $ave \n";
#			print "*";
			
			return($ave);
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
#
#        @logfilestat  = stat($AppLogFile);
#        if ($logfilestat[7] > $MaxLogFileSize)
#        {
#                $AppLogFileBackup = $AppLogFile."old";
#                if (-e $AppLogFileBackup)
#                {
#                        unlink $AppLogFileBackup or die "Cannot delete $AppLogFileBackup\n";
#                }
#                system("mv $AppLogFile $AppLogFileBackup");
#        }
}


sub cons
{
	$AppLogFile = $PathAppLogFile . "ConnMon" . hostname(). ".log";

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
               xstm1953dap => "STMOBJENG1",
               xstm1315pap => "STMOBJPHBT1"
             );
    $ostype = $ostypes{$^O};

print "Wait for it\n";
#    $objserv = $osmap{hostname()};
    	$objserv = "EMEA";
#    	$objserv = "DISP-LDN-1";

	# Open Connection to database
	$dbh = osConnect($objserv);
my $EMEA_SSM_SNG = osGetLatency ("MTPPROD2", "xsng");
my $EMEA_MTT_SNG = osGetLatency ("MTPPROD1", "xsng");
my $EMEA_SOC_SNG = osGetLatency ("ubs_socket", "xsng");
my $EMEA_SSM_STM = osGetLatency ("MTPPROD2", "xstm");
my $EMEA_MTT_STM = osGetLatency ("MTPPROD1", "xstm");
my $EMEA_SOC_STM = osGetLatency ("ubs_socket", "xstm");
my $EMEA_SSM_LDN = osGetLatency ("MTPPROD2", "xldn");
my $EMEA_MTT_LDN = osGetLatency ("MTPPROD1", "xldn");
my $EMEA_SOC_LDN = osGetLatency ("ubs_socket", "xldn");
	osDisconnect;
	chkLogSize;

print "Wait for it\n";
	
	$objserv = "USAPAC";
#    	$objserv = "DISP-STM-1";
	
	# Open Connection to database
	$dbh = osConnect($objserv);
my $USAPAC_SSM_SNG = osGetLatency ("MTPPROD2", "xsng");
my $USAPAC_MTT_SNG = osGetLatency ("MTPPROD1", "xsng");
my $USAPAC_SOC_SNG = osGetLatency ("ubs_socket", "xsng");
my $USAPAC_SSM_STM = osGetLatency ("MTPPROD2", "xstm");
my $USAPAC_MTT_STM = osGetLatency ("MTPPROD1", "xstm");
my $USAPAC_SOC_STM = osGetLatency ("ubs_socket", "xstm");
my $USAPAC_SSM_LDN = osGetLatency ("MTPPROD2", "xldn");
my $USAPAC_MTT_LDN = osGetLatency ("MTPPROD1", "xldn");
my $USAPAC_SOC_LDN = osGetLatency ("ubs_socket", "xldn");
	osDisconnect;
	chkLogSize;
	
	
    	$objserv = "PACIFIC";
#    	$objserv = "DISP-SNG-1";
print "Wait for it\n";

	# Open Connection to database
	$dbh = osConnect($objserv);
my $PACIFIC_SSM_SNG = osGetLatency ("MTPPROD2", "xsng");
my $PACIFIC_MTT_SNG = osGetLatency ("MTPPROD1", "xsng");
my $PACIFIC_SOC_SNG = osGetLatency ("ubs_socket", "xsng");
my $PACIFIC_SSM_STM = osGetLatency ("MTPPROD2", "xstm");
my $PACIFIC_MTT_STM = osGetLatency ("MTPPROD1", "xstm");
my $PACIFIC_SOC_STM = osGetLatency ("ubs_socket", "xstm");
my $PACIFIC_SSM_LDN = osGetLatency ("MTPPROD2", "xldn");
my $PACIFIC_MTT_LDN = osGetLatency ("MTPPROD1", "xldn");
my $PACIFIC_SOC_LDN = osGetLatency ("ubs_socket", "xldn");
	osDisconnect;
	chkLogSize;
system("clear");

print"\n";
printf " _______________________________________________________________________________________________________________________\n";
printf "|			|	SNG PROBES		|	EMEA PROBES		|	STM PROBES		|\n";
printf "|			|	SSM	MTT	SOC	|	SSM	MTT	SOC	|	SSM	MTT	SOC	|\n";
printf "|_______________________|_______________________________|_______________________________|_______________________________|\n";
printf "|	EMEA OS		|	%d	%d	%d	|	%d	%d	%d	|	%d	%d	%d	|\n", $EMEA_SSM_SNG, $EMEA_MTT_SNG,$EMEA_SOC_SNG, $EMEA_SSM_STM, $EMEA_MTT_STM,$EMEA_SOC_STM,$EMEA_SSM_LDN, $EMEA_MTT_LDN,$EMEA_SOC_LDN;
printf "|	USA OS		|	%d	%d	%d	|	%d	%d	%d	|	%d	%d	%d	|\n", $USAPAC_SSM_SNG, $USAPAC_MTT_SNG,$USAPAC_SOC_SNG, $USAPAC_SSM_STM, $USAPAC_MTT_STM,$USAPAC_SOC_STM,$USAPAC_SSM_LDN, $USAPAC_MTT_LDN,$USAPAC_SOC_LDN;
printf "|	PACIFIC OS	|	%d	%d	%d	|	%d	%d	%d	|	%d	%d	%d	|\n", $PACIFIC_SSM_SNG, $PACIFIC_MTT_SNG,$PACIFIC_SOC_SNG, $PACIFIC_SSM_STM, $PACIFIC_MTT_STM,$PACIFIC_SOC_STM,$PACIFIC_SSM_LDN, $PACIFIC_MTT_LDN,$PACIFIC_SOC_LDN;
printf "|_______________________|_______________________________|_______________________________|_______________________________|\n";

}

# This bit for testing
#for (;;)
#{
	cons();
#	sleep $Sleeptime;
#}


# This bit to run as a one shot deal
#cons();
