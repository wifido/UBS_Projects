#!/sbclocal/netcool/omnibus/utils/perllib/MUSE_PERL_PROD/bin/perl -w
# #!/sbcimp/run/pd/perl/5.8.7/bin/perl -w

use Net::SNMP qw(:ALL);
use Time::HiRes qw(gettimeofday);
use Getopt::Std;

use strict;

my $trap_community = '2217101:T24_CUSTODY_PR';
my %opt;
my $Debug;
my $JobName;
my $HostName;
my $Port;
my $enterprise;
my $VarBind1 ;
my $VarBind2 ;
my $VarBind3 ;
my $VarBind4 ;
my $VarBind5 ;
my $VarBind6 ;
my $Data1;
my $Data2;
my $Data3;
my $Data4;
my $Data5;
my $Data6;

sub usage()
{
#############################################################################
#
#	This sub shows usage when invokes by -h or incorrect usage
#
#############################################################################
	print "	This program does...\n";
	print "	\n";
	print "	usage: $0 -j jobname\n";
	print "	\n";
	print "	-h        : this (help) message\n";
	print "	-j jobname    : where jobname is the jobname supplied as part of the \n";
	print "			Autosys synthetic trap. this cannot be left blank\n";
	print "	-D        : Puts the script into debug mode\n";
	print "	\n";
	print "	example: $0 -j autosys_job_name\n";
}



# Here we start the loop. The logic will be a bit ovelry complicated as we need to create new sessions for each trap.

sub do_trap 
{
	my $trap_dest = $_[0];
	my $trap_port = $_[1];
	my ($session, $error) = Net::SNMP->session(
		-hostname 	=>  $trap_dest,
		-community 	=> $trap_community,
		-port		=> $trap_port,);

	if (!defined($session)) 
	{
		printf("ERROR: %s.\n", $error);
		exit 1;
	}

	# Here we build the trap properly for UBS standard.
 
	my $time = time();
	my $result = $session->trap(
		-enterprise	=>	$enterprise,
		-generictrap	=>	'6',
		-specifictrap	=>	'1',
		-timestamp	=>	$time,
		-varbindlist	=>	[
		$VarBind1, OCTET_STRING, $Data1, 
		$VarBind2, OCTET_STRING, $Data2, 
		$VarBind3, OCTET_STRING, $Data3, 
		$VarBind4, OCTET_STRING, $Data4, 
		$VarBind5, OCTET_STRING, $Data5, 
		$VarBind6, OCTET_STRING, $Data6
		
		]
	);
	if (!defined($result)) 
	{
		printf("ERROR: %s.\n", $session->error());

	}

	$session->close();
#	print "Trap Dest > $trap_dest    Port > $trap_port \n";
}


getopts( "hj:D", \%opt ) or usage();


# are we in debug mode
if ($opt{D})
{
	$Debug = 1 ;
}
if ($opt{j})
{
	# Use hostname supplied
	$JobName = $opt{j};
}
else
{
	usage();
	exit 1;
}

if ($opt{h})
{
	usage();
	exit 1;
}

#$HostName = "161.239.152.57";
$HostName = "xstm5257dap.stm.swissbank.com";
$Port = "162";
$enterprise = '.1.3.6.1.4.1.858.3.2.1';

$VarBind1 = $enterprise .".1";
$VarBind2 = $enterprise .".2";
$VarBind3 = $enterprise .".3";
$VarBind4 = $enterprise .".4";
$VarBind5 = $enterprise .".5";
$VarBind6 = $enterprise .".6";

$Data1 = 'An AutoSys (instance: DLN machine: wldn0144847) alarm has been generated.';
$Data2 = '06/05/2007 10:40:22';
$Data3 = 'RESOURCE';
$Data4 = $JobName;
$Data5 = 'Rescheduled by auto_remote, File to source (profile): /home/etdlincpuat/CoreProcessing_US/v0.03/bin/AutosysPOC/RN_Pos.profile is missing.';
$Data6 = '512';


if($Debug)
{
	print "\nAutosys Trap sent to $HostName on port $Port\n\n";
	print "Enterprise = $enterprise\n";
	print "Varbind1 ($VarBind1) = $Data1\n";
	print "Varbind2 ($VarBind2) = $Data2\n";
	print "Varbind3 ($VarBind3) = $Data3\n";
	print "Varbind4 ($VarBind4) = $Data4\n";
	print "Varbind5 ($VarBind5) = $Data5\n";
	print "Varbind6 ($VarBind6) = $Data6\n\n";
}

do_trap($HostName, $Port);


exit 0;
