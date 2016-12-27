#!/sbclocal/netcool/omnibus/utils/perllib/MUSE_PERL_PROD/bin/perl -w
###################################################################################
#
# Script to Monitor Netcool Omibus Gateways 
#
# Origional	8th june 2005	Chris Janes of Abilitec 
# 1.0		25th Oct 2005	First production Version
# 1.1		31st Oct 2005	Method of aquiring Gateway Log File changed
# 2.0.0		20th Dec 2005	rewrite to overcome several problems
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
#use lib qw(/sbcimp/run/pd/cpan/5.8.0-2003.05/lib);
#use lib qw(/home/janesch/perl/lib);
#use lib qw(/sbcimp/run/pd/cpan/5.8.6-2005.03/lib);
use DBI;
use DBD::Sybase;
use Proc::ProcessTable;

##################################################################################
#
# Configuration Settings (These are overwriten by any entries in the .gmconf file
#			  this lives in $OMNIHOME/etc)
#
##################################################################################

# GateNane - Name of Gateway
$GateName = "FG_LDN-ENG";
 
# PathConfFile - Location of gateway conf file
$PathConfFile = "/sbclocal/netcool/omnibus/etc/";
 
# PathAppConfFile - Location of this app's conf file
$PathAppConfFile = "/sbclocal/netcool/omnibus/etc/";

# PathGatewayLogFile - Location of gateway log file
$PathGatewayLogFile="/sbclocal/netcool/omnibus/log/";

# MaxLogFileSize - Maximum size of the logfile
$MaxLogFileSize=1000000;

# PathAppLogFile - Location of this apps logfile
$PathAppLogFile="/sbclocal/netcool/omnibus/log/";

# _debug - make this 0 to take out debug messages
$_debug = 5 ;

# IsProd - is this in Dev(0) or Prod(1)
$IsProd = 1;

# ChildLog is set to 1 for stderr and stdout redirected to gatemon child log
 $ChildLog = 0;

# TimeLimit - This is the time limit after which a Event is generated in seconds
$TimeLimit = 4;

# FlushTime - This is the time that records are allowed to exist in the hashes for before being flushed in seconds
$FlushTime = 20;

# MaxNoEvents - if the number of event in any log entry if exceded then an Event is inserted into the object server
$MaxNoEvents = 6499;

# SleepTime - the period that this app sleeps between loops in seconds
$Sleeptime = 5;

# MaxTimeNoEvent the time with out gateway activity, after which an Omnibus Event is raised
$MaxTimeNoEvent = 60;

# Log each gateway event to logfile 
$_logline = 0;

#	this shows where the config origonated from
$ConfigFrom = " Base Config  \n";

# this logs the config at app startup
$LogConfig = 1;

# This tells us if it is a Bi or Uni gate  1 = Uni 2 = Bi
$BiUni = 2;



##################################################################################
#
# Global Vars go here Go Here 
#
##################################################################################

our $ObjectServerA, $ObjectServerB, $UniqueLog, $MessageLog;
our $Agent = "GateMon.pl";
our $AppConfFile, $ConfFile;


##################################################################################
#
# Functions Go Here 
#
##################################################################################



#
# This is just to get rid of some warnings during debug
#

sub wanings
{

}

#
# This writes to the Record to the App Log File
#
sub logit
{
	my $str = $_[0];
	chomp $str;
	print $str;
	my $error_str = $str . " " . localtime(time) . "\n";
	open (APPLOG,">>$AppLogFile")|| die "cannot open $AppLogFile file";
	print APPLOG $error_str;
	close (APPLOG);
}

sub get_log_file
{
	my $NewLogfile;
	#logit "Discovering New Gateway Log file";
	if ($UniqueLog =~ /"TRUE"/)
	{
		$t = new Proc::ProcessTable;
		foreach $p ( @{$t->table} )
		{
			if (($p->cmndline )&&($p->cmndline =~ m/nco_gate/))
			{
				
				my $LenghtMessageLog = length ($MessageLog);
				my $PathGatewayLog = substr($MessageLog,0,$LenghtMessageLog - 4);
				$NewLogfile = $PathGatewayLog . "." . $p->pid . ".log";
				my $TmpLogEntry =  "Discovered Gateway Log File " . $NewLogfile;
				logit $TmpLogEntry;
			}
		}
	}
	else 
	{
		$NewLogfile = $MessageLog;
	}
	return $NewLogfile;
}



#
# This generates a display for testing purpose's
#
sub print_details
{
	$UpdatesSize = 0;
	foreach $key (keys %Updates)
	{
	        $UpdatesSize = int($UpdatesSize) + 1;
	}
	$DeletesSize = 0;
	foreach $key (keys %Deletes)
	{
	        $DeletesSize = int($DeletesSize) + 1;
	}
	$InsertsSize = 0;
	foreach $key (keys %Inserts)
	{
	        $InsertsSize = int($InsertsSize) + 1;
	}
	$TransCount = int($UpCountIn) +  int($InCountIn) + int($DeCountIn) + int($UpCountOut) +  int($InCountOut) + int($DeCountOut);
	print "Trans Count     > $TransCount\n";
	print "Update Count in > $UpCountIn\n";
	print "Update Count out> $UpCountOut\n";
	print "Update % Count  > $UpdatesSize\n";
	print "Insert Count in > $InCountIn\n";
	print "Insert Count out> $InCountOut\n";
	print "Insert % Count  > $InsertsSize\n";
	print "Delete Count in > $DeCountIn\n";
	print "Delete Count out> $DeCountOut\n";
	print "Delete % Count  > $DeletesSize\n";
	print "Total Discards  > $NoDiscards\n";
	print "Last read       > $LastRead\n";
	$NowTime = time;
	print "Time Now        > $NowTime\n";
}


#
#This parses  numeric vallues that are recovered from the log file
#
sub parse_numbers
{
	if (!($fields[2] =~ /[0-9]+/))
	{
		#It's not a number;
		$mon=998;
	}
	elsif (!($fields[1] =~ /[0-9]+/))
	{
		#It's not a number;
		$mon=998;
	}
	else
	{
	}
}

#
# This cleans up  the reader and writer fields that are extracted from the log and conf files
#
sub rw_clean
{
	my $vartest = $_[0];
	$vartest =~ s/\'//g;
	$vartest =~ s/;//;
	$vartest =~ s/://;
	chomp $vartest;
	$vartest = $vartest;
}

#
# This converts from short form text months to numeric months (Nb Jan = 0)
#
sub whichmonth
{
	if ($_[0] =~/Jan/)
	{
		$mon = 0;
	}
	elsif ($_[0] =~/Feb/)
	{
		$mon = 1;
	}
	elsif ($_[0] =~/Mar/)
	{
		$mon = 2;
	}
	elsif ($_[0] =~/Apr/)
	{
		$mon = 3;
	}
	elsif ($_[0] =~/May/)
	{
		$mon = 4;
	}
	elsif ($_[0] =~/Jun/)
	{
		$mon = 5;
	}
	elsif ($_[0] =~/Jul/)
	{
		$mon = 6;
	}
	elsif ($_[0] =~/Aug/)
	{
		$mon = 7;
	}
	elsif ($_[0] =~/Sep/)
	{
		$mon = 8;
	}
	elsif ($_[0] =~/Oct/)
	{
		$mon = 9;
	}
	elsif ($_[0] =~/Nov/)
	{
		$mon = 10;
	}
	elsif ($_[0] =~/Dec/)
	{
		$mon = 11;
	}
	else
	{
		$mon = 999;
	}
}

#
#
#

#
# This reads config info from file specified on the command line
#
sub getconfig
{
        $AppConfFile= $PathAppConfFile . $_[0] . ".gmconf";
        print "AppConfFile = $AppConfFile \n";
        if (-e $AppConfFile)
        {
                open (APPCONFIG, $AppConfFile)|| die "cannot open $AppConfFile file";
                my @AppConfig = <APPCONFIG>;
                close (APPCONFIG);
                foreach $Line (@AppConfig)
                {
                        if ($Line =~m/\#/){}
                        else
                        {
                                chomp $Line;
                                if (length ($Line))
                                {
                                        my @temparray = split (/ /, $Line);
                                        if ($temparray[0] eq "GateName")
                                        {
                                                $GateName = $temparray[2];
                                                if ($_debug > 4)
                                                {
                                                	print "getconfig Setting $temparray[0] \n";
                                                }
                                        }
                                        elsif ($temparray[0] eq "PathGatewayLogFile")
                                        {
                                                $PathGatewayLogFile = $temparray[2];
                                                if ($_debug > 4)
                                                {
                                                	print "getconfig Setting $temparray[0] \n";
                                                }
                                        }
                                        elsif ($temparray[0] eq "PathConfFile")
                                        {
                                                $PathConfFile = $temparray[2];
                                                if ($_debug > 4)
                                                {
                                                	print "getconfig Setting $temparray[0] \n";
                                                }
                                        }
                                        elsif ($temparray[0] eq "PathAppLogFile")
                                        {
                                                if ($_debug > 4)
                                                {
                                                	print "getconfig Setting $temparray[0] \n";
                                                }
                                                $PathAppLogFile = $temparray[2];
                                        }
                                        elsif ($temparray[0] eq "_debug")
                                        {
                                                $_debug = $temparray[2];
                                                if ($_debug > 4)
                                                {
                                                	print "getconfig Setting $temparray[0] \n";
                                                }
                                        }
                                        elsif ($temparray[0] eq "GetIduc")
                                        {
                                                getiduc;
                                                if ($_debug > 4)
                                                {
                                                	print "getconfig Setting $temparray[0] \n";
                                                }
                                        }
                                        elsif ($temparray[0] eq "IsProd")
                                        {
                                                $IsProd = $temparray[2];
                                                if ($_debug > 4)
                                                {
                                                	print "getconfig Setting $temparray[0] \n";
                                                }
                                        }
                                        elsif ($temparray[0] eq "TimeLimit")
                                        {
                                                $TimeLimit = $temparray[2];
                                                if ($_debug > 4)
                                                {
                                                	print "getconfig Setting $temparray[0] \n";
                                                }
                                        }
                                        elsif ($temparray[0] eq "FlushTime")
                                        {
                                                $FlushTime = $temparray[2];
                                                if ($_debug > 4)
                                                {
                                                	print "getconfig Setting $temparray[0] \n";
                                                }
                                        }
                                        elsif ($temparray[0] eq "MaxNoEvents")
                                        {
                                                $MaxNoEvents = $temparray[2];
                                                if ($_debug > 4)
                                                {
                                                	print "getconfig Setting $temparray[0] \n";
                                                }
                                        }
                                        elsif ($temparray[0] eq "MaxTimeNoEvent")
                                        {
                                                $MaxTimeNoEvent = $temparray[2];
                                                if ($_debug > 4)
                                                {
                                                	print "getconfig Setting $temparray[0] \n";
                                                }
                                        }

                                }
                        }
                }
                $ConfigFrom = " Loaded Config from $AppConfFile \n";
        }
         else
        {
	logit "Unable to open Application ConfFile\n";
        }
}

#
# Get what we need to know from Gateway Properties file
#

sub GetGateProps
{
        $ConfFile= $PathAppConfFile . $_[0] . ".props";
        if (-e $ConfFile)
        {
                open (GATECONFIG, $ConfFile) || die "Couldn't open gate props file" ;
                my @GateConfig = <GATECONFIG>;
                close (GATECONFIG);
                foreach my $Line (@GateConfig)
                {
                        if ($Line =~m/\#/){}
                        else
                        {
                                chomp $Line;
                                if (length ($Line))
                                {
                                        my @temparray = split (/\s/, $Line);
                                        if ($temparray[0] eq "Gate.ObjectServerA.Server")
                                        {
                                                $ObjectServerA = $temparray[2];
                                                if ($_debug > 4)
                                                {
                                                	print "GetGateProps Setting $temparray[0] \n";
                                                }
                                        }
                                        elsif ($temparray[0] eq "Gate.ObjectServerB.Server")
                                        {
                                                $ObjectServerB = $temparray[2];
                                                if ($_debug > 4)
                                                {
                                                	print "GetGateProps Setting $temparray[0] \n";
                                                }
                                        }
                                        
                                        elsif ($temparray[0] eq "Gate.Writer.Server")
					{
						$GateWriterServer = $temparray[2];
						if ($_debug > 4)
						{
							print "GetGateProps Setting $temparray[0] \n";
						}
					}
                                        elsif ($temparray[0] eq "Gate.Reader.Server")
					{
						$GateReaderServer = $temparray[2];
						if ($_debug > 4)
						{
							print "GetGateProps Setting $temparray[0] \n";
						}
					}

                                        elsif ($temparray[0] eq "MessageLog")
                                        {
                                                $MessageLog = $temparray[2];
                                                if ($_debug > 4)
                                                {
                                                	print "GetGateProps Setting $temparray[0] \n";
                                                }
                                        }
                                        elsif ($temparray[0] eq "UniqueLog")
                                        {
                                                $UniqueLog = $temparray[2];
                                                if ($_debug > 4)
                                                {
                                                	print "GetGateProps Setting $temparray[0] \n";
                                                }
                                        }
				}
			}
		}
	}
	else
	{
		# no Props file
	}
}


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
#	logit("LOG_INFO, Attempting connection to Object Server " . $oserv . "\n");
	my $db = DBI->connect("DBI:Sybase:server=$oserv;interfaces=$ENV{OMNIHOME}/etc/interfaces.$ostype;scriptName=ProcessMonitor;loginTimeout=10",$username,$password,\%attr) or logit("LOG_INFO_1 " . $DBI::errstr . "\n");
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


sub osInsertEvent  {
	my ($sth, $stmt);
	my ($id, $nodealias, $node, $agent, $mgr, $group, $key, $summary, $nod, $noda, $ident);
	my ($time, $reg, $locn, %locs, %locreg, $lc, $rg);
	%locs = (   ldn => 'London',
		stm => 'Stamford',
		opf => 'Opfikon',
		sng => 'Singapore'
	);
	%locreg = ( ldn => 'EMEA',
		stm => 'Americas',
		opf => 'Switzerland',
		sng => 'Asia Pacific'
	);
# Set up default values hash out if setting them else where
	$Group = $GateName;
	#$Key = "WriterName";
	$Mgr = "GatewayWatch";
#	$Summary = "Test Event Please Ignore - janesch";
#	$ExpireTime = 1200;
#	$Severity = 5;
	$Prule = "Direct into Probe from GateMon";
	if ($PType == 0)
	{
		$Type = 0;
	}
	else
	{
		$Type = $PType;
		$PType = 0;
	}
	($node, $nodealias) = getHostInfo(hostname());
	$locn = $locs{substr($nodealias, 1, 3)};
	$reg = $locreg{substr($nodealias, 1, 3)};
#	Format vars for the database (sort out the '" stuff)
	$lc = $dbh->quote($locn);
	$rg = $dbh->quote($reg);
	$nod = $dbh->quote($node);
	$prule = $dbh->quote($Prule);
	$noda = $dbh->quote($nodealias);
	$agent = $dbh->quote($Agent);
	$mgr = $dbh->quote($Mgr);
	$group = $dbh->quote($Group);
	$key = $dbh->quote($Key);
	$summary = $dbh->quote($Summary);
	$time = time();
	$type = $Type;
	$ident = $nodealias . $Agent . $Group . $Key . $Type;
	$id = $dbh->quote($ident);
	$severity = $Severity;
	$expiretime = $ExpireTime;
#	create the SQL string
	$stmt = qq{insert into alerts.status (Identifier, FirstOccurrence, LastOccurrence, NodeAlias, Node, Agent, Manager, OwnerGID, OwnerUID, Class, AlertGroup, AlertKey, Severity, Summary, Type, Location, Region, ExpireTime)
		values
			($id, $time, $time, $noda, $nod, $agent, $mgr, 591, 65534, 0, $group, $key, $severity, $summary, $type, $lc, $rg, $expiretime)
		updating
			(Summary, AlertKey, Location);};
#	do the prepare execute sruff
		$sth = $dbh->prepare($stmt);
		if (my $rets = $sth->execute())  
		{
			logit "$summary Event Inserted at ";
			print "$summary Event Inserted at ";
			return($rets);
		}
		else  
		{
			logit "Failed to insert Event";
			print "Failed to insert Event";
			return($rets);
		}
}

#
# when passed the hostname it returns $node and $nodealias
#

sub getHostInfo  {
    my $host = shift;
    my ($name, $aliases, $addrtype, $length, @addrs) = gethostbyname($host);
    my @addr = unpack('C4',$addrs[0]);
    return(join(".", @addr), $name);
}
sub duffs
{
	$prule = 0;
	$discard1 = 1;
	$discard1 = 2;
	$discard1 = 3;
	$discard1 = 4;
	$Duff = 0;
}

sub ShowConfig
{
open (APPLOG,">>$AppLogFile")|| die "cannot open $AppLogFile file";
print APPLOG " Gateway			> $GateName \n";
print APPLOG " Gateway Config file	> $ConfFile \n";
print APPLOG " Gateway Log File 	> $LogFile \n";
print APPLOG " This Apps Config File	> $AppConfFile \n";
print APPLOG " This Apps Log File	> $AppLogFile \n";
print APPLOG " Max Size for Log File	> $MaxLogFileSize \n";
print APPLOG " _debug			> $_debug \n";
print APPLOG " IsProd			> $IsProd \n";
print APPLOG " TimeLimit		> $TimeLimit \n";
print APPLOG " FlushTime		> $FlushTime \n";
print APPLOG " MaxNoEvents		> $MaxNoEvents \n";
print APPLOG " Sleeptime		> $Sleeptime \n";
print APPLOG " MaxTimeNoEvent		> $MaxTimeNoEvent \n";
print APPLOG " _logline			> $_logline \n";
print APPLOG " ConfigFrom		> $ConfigFrom \n";
close (APPLOG);
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
#    %osmap = ( xldn0064pap => "LDNOBJPROD1",
#               xldn0065pap => "LDNOBJPROD1",
#               xldn1014pap => "LDNOBJPROD1",
#               xldn1017pap => "LDNOBJPROD1",
#               xldn1018pap => "LDNOBJPROD1",
##               xopf0100pap => "LDNOBJPROD1",
#               xopf0101pap => "LDNOBJPROD1",
#               xsng1001pap => "LDNOBJPROD1",
#               xsng1209pap => "LDNOBJPROD1",
#               xstm8950pap => "STMOBJPROD1",
#               xstm8951pap => "STMOBJPROD1",
#               xstm8027pap => "STMOBJPROD1",
#               xstm9838dap => "STMOBJTEST1",
#               xldn1052dap => "LDNOBJENG1",
#               xldn1053dap => "LDNOBJENG1",
#               xldn1054dap => "LDNOBJENG1",
#               xstm1953dap => "STMOBJENG1"
#             );

    %osmap = ( xldn0064pap => "LDNOBJPROD1",
               xldn0065pap => "LDNOBJPROD1",
               xldn0055pap => "LDNOBJPROD1",
               xldn1019pap => "LDNOBJPROD1",
               xldn1014pap => "LDNOBJPROD1",
               xldn1017pap => "LDNOBJPROD1",
               xldn1018pap => "LDNOBJPROD1",
               xopf0100pap => "LDNOBJPROD1",
               xopf0101pap => "LDNOBJPROD1",
               xsng1209pap => "SNGOBJPROD1",
               xsng1216pap => "SNGOBJPROD1",
               xsng1215pap => "SNGOBJPROD1",
               xsng1000pap => "SNGOBJPROD1",
               xsng1001pap => "SNGOBJPROD1",
               xsng1052pap => "SNGOBJPROD1",
               xstm8950pap => "STMOBJPROD1",
               xstm8951pap => "STMOBJPROD1",
               xstm1394pap => "STMOBJPROD1",
               xstm1335pap => "STMOBJPROD1",
               xstm1338pap => "STMOBJPROD1",
               xstm1317pap => "STMOBJPROD1",
               xstm8027pap => "STMOBJPROD1",
               xstm9838dap => "STMOBJTEST1",
               xstm1935dap => "STMOBJTEST1",
               xldn1052dap => "LDNOBJENG1",
               xldn1053dap => "LDNOBJENG1",
               xldn1054dap => "LDNOBJENG1",
               xstm1953dap => "STMOBJENG1",
               xstm1979dap => "STMOBJENG1"
             );


    $ostype = $ostypes{$^O};
    $objserv = $osmap{hostname()};

# Open Connection to database
$dbh = osConnect($objserv);

# Insert an Event into the database
osInsertEvent;

# Disconnect from the database
osDisconnect;

}
sub GetLogFile
{
	$t = new Proc::ProcessTable;
	foreach $p ( @{$t->table} )
	{
		if (($p->cmndline =~ m/$GateName/)&&($p->cmndline =~ m/nco_g_objserv/))
		{
			$NewLogfile = $PathGatewayLogFile . $GateName . "." . $p->pid . ".log";
			return($NewLogfile);
		}
	}
}

sub GetTime
{
#	my $hh, $mm, $ss, $mon, $time;
	(my $hh, my $mm, my $ss) = split (/:/,$fields[3]);
	my $mon=whichmonth($fields[1]);
	my $time = timelocal($ss, $mm, $hh, $fields[2], $mon, $fields[4]);
	return $time;
}

##################################################################################
#
# Read in from the .conf file specified on the command line (if it exists!)
#
##################################################################################
if ($ARGV[0])
{
        my $Arg = $ARGV[0];
        print "Getting Config\n";
        getconfig ($Arg);
        print "Getting Gate Pproperties\n";
        GetGateProps ($Arg);
}

##################################################################################
#
# Test the relevent files exist, if not logit and exit
#
##################################################################################
#Location of this apps logfile
$AppLogFile=$PathAppLogFile."GateMon_".$GateName.".log";
system ("touch $AppLogFile");
if (-e $AppLogFile){}
else 
{ 
	if ($_debug)
	{
		print "Unable to open $AppLogFile \n";
	}
	exit 0;
}
print " AppLogFile $AppLogFile \n";
#Location of this apps childlogfile
$ChildAppLogFile=$PathAppLogFile."GateMon_".$GateName.".child.log";
system ("touch $ChildAppLogFile");
if (-e $ChildAppLogFile){}
else 
{ 
	if ($_debug)
	{
		print "Unable to open $ChildAppLogFile \n";
	}
	exit 0;
}

if ($ChildLog)
{
         open(LOG, ">>$ChildAppLogFile") or die "Couldn't open $ChildAppLogFile for writing: $!";
         open(STDOUT, ">&", \*LOG) or warn "Couldn't redirect STDOUT to $logfile: $!";
         open(STDERR, ">&", \*LOG) or warn "Couldn't redirect STDERR to $logfile: $!";
}
else
{
	# But not in Dev ie not Prod
}

if ($_debug < 4 )
{
	print "Application Started\n";
}
logit "Application Started\n";
$PType = 0;
$Severity = 2;
$Key =  "Application";
$ExpireTime = 120;
$Summary ="GateMon Application Started";
osRaiseEvent();

if ($LogConfig)
{
	$LogFile = GetLogFile();
	ShowConfig;
}

our @fields;
$GetLogFile = 0;
$IgnoredEventCount = 0;
for(;;)
{
	#	get the logfile
	do
	{
		print "**************************************** Getting Log file ************************************\n";
		# Location of gateway log file
		if ($IsProd)
		{
			$LogFile = GetLogFile();
		}
		else
		{
			$LogFile=$PathLogFile.$GateName.".log";
		}
		if ($_debug > 4)
		{
			print "Gateway Logfile is $LogFile \n";
		}
		
		if (-e $LogFile)
		{
				$GoodLogFile = 1;
				$PType = 2;
				$Severity = 2;
				$Key =  "Gateway Log File";
				$ExpireTime = 360;
				$Summary ="Unable to find Gateway Log";
				osRaiseEvent();
		}
		else 
		{ 
			if ($_debug <4)
			{
				print "Unable to open $LogFile msg\n";
			}
			logit "Unable to open Gateway Log File \n";
			print "Unable to open Gateway Log File \n";
			$GoodLogFile = 0;
			$PType = 1;
			$Severity = 4;
			$Key =  "Gateway Log File";
			$ExpireTime = 36000;
			$Summary ="Unable to find Gateway Log";
			osRaiseEvent();

			sleep 60;
		}
	} until ($GoodLogFile == 1);
	$UtcStart =time;
	$LastRead = $UtcStart;
	
	$LoopCount =0;
	$LastGetLog = now;
	$GetLogFile = $GetLogFile + 1;
	logit "Discovered Gateway Logfile to be $LogFile \n";
	open (LOGFILE,$LogFile) || die "Cannot open logfile $LogFile at ";
	do
	{
		for ($CurPos = tell(LOGFILE); <LOGFILE>;$CurPos = tell(LOGFILE))
		{
			$LogLine = $_;
			$LastRead = time;
			if ($LoopCount ==0)
			{}
			else
			{
				if ($_logline) 
				{
					logit "Event > $LogLine\n";
				}
			}
			@fields = split (/ /,$LogLine);
		        $count_fields = @fields;
		        $LineTime = GetTime();
		        if ($UtcStart < $LineTime)
		        {
		        	if ($fields[6] =~/I-NGOBJSE-104-001:/)
		        	{
					logit "Event > $LogLine\n";
		        		#Uni-directional resync request
		        	}
		        	elsif ($fields[6] =~/I-NGOBJSE-104-027:/)
		        	{
					logit "Event > $LogLine\n";
		        		#Successful resynchronisation complete
		        	}
		        	elsif ($fields[6] =~/E-IPCM-053-008:/)
		        	{
					logit "Event > $LogLine\n";
		        		#Failed to connect to ObjectServer
		        	}
		        	elsif ($fields[6] =~/I-UNK-000-000:/)
		        	{
					
					logit "Event > $LogLine\n";
		        		#Checking in license
		        	}
		        	elsif ($fields[6] =~/I-NGOBJSE-104-025:/)
		        	{
					
					logit "Event > $LogLine\n";
		        		#Transfer Manager: Sending data set to mapper.
		        	}
		        	elsif ($fields[6] =~/I-NGOBJSE-104-026:/)
		        	{
					
		        		$IgnoredEventCount = $IgnoredEventCount + 1;
		        		#Failed to lookup the required row in table 'alerts.status' from server
		        	}
		        	else
		        	{
					logit "Event Ignored > $LogLine\n";
		        		$IgnoredEventCount = $IgnoredEventCount + 1;
		        	}
}
		}
		$now = time;
		
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


        	sleep $Sleeptime;
        	seek(LOGFILE,$CurPos,0);
	
		$LoopCount =$LoopCount + 1;
	system ("clear");
		if ($_debug > 4)
		{
			print " Loop Count   > $LoopCount \n";
			print " Last Read    > $LastRead \n";
			print " Now          > $now \n";
			print " Get Log File > $GetLogFile \n";
			print " Ignored Events > $IgnoredEventCount\n";
		}
	}until ($LastRead < ($now - $MaxTimeNoEvent));
	close (LOGFILE);
}

