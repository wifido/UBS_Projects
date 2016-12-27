#!/usr/bin/perl
# $Id: patrolcfg_sifter.pl 1066 2010-10-29 13:09:21Z harperri $
# $URL: https://ims-svn.swissbank.com/prod-kerb/AGENTENG/trunk/asagent/migration/patrolcfg_sifter.pl $

use strict;

use Getopt::Std;

my %opts = {};
getopts('p:ob:', \%opts);

my $pcfg = $opts{p};

# Check where the baselines are - they should be stored in a particularly structure
if (defined($opts{b})) {
	my $baseline_dir = $opts{b};
else {
	my $baseline_dir = "/home/harperri/patrol/pcm";
}

# If an output dir is defined, write the open to this
if (defined($opts{o})) {
	my $output = "APP_".$pcfg;
	print "Writing stripped config to $output\n";
	open OUT, '>', $output;
} else {
	open OUT, '>-';
}

my @patrol_config = ();
my $line;
my $agentInfo;

print "[IN] File: $pcfg\n";
open PCFG, $pcfg or die "$!\n";

while (<PCFG>) {
	chomp;
	$line = $_;
	push @patrol_config, $line;
	$agentInfo = $line if (lc($line) =~ /agentinfo/);
}

close PCFG;

$agentInfo	=~ /{ REPLACE = "(.+),.+,.+,.+,(.+),(.+),.+" }/;
my $systemName	= $1;
my $version	= $2;
my $platform	= $3;

if ($version =~ /3\.5/) {
	$version = 'v3500';
} elsif ($version =~ /3\.6/) {
	$version = 'v3600';
} elsif ($version =~ /3\.7/) {
	$version = 'v3700';
}

if ($platform eq 'SOLARIS' or $platform eq 'SOLARIS 5.8') {
	$platform = 'Solaris';
} elsif ($platform eq 'SOLARIS 5.10') {
	$platform = 'Solaris10';
} elsif ($platform eq 'SOLARIS 5.6') {
	print "Warning: AsAgent is not supported on Solaris 2.6\n";
	exit;
} elsif ($platform =~ /^Linux/) {
	$platform = 'Linux';
} elsif ($platform eq 'RS6000') {
	$platform = 'AIX';
} elsif ($platform eq 'RS6000 5.1') {
	print "Warning: AsAgent is not supported on AIX 5.1\n";
	exit;
} elsif ($platform eq 'RS6000 5.2' or $platform eq 'RS6000 5.3') {
	$platform = 'AIX';
}

my $baseline = $baseline_dir."/nbl/$version/$platform";

print "[INFO] System '$systemName' is detected as Patrol $version on '$platform'. Loading $baseline...\n";

# read in the base rules from the directory
opendir(BASEDIR, $baseline) or die "[ERROR] No baseline directory found: $!\n";

my @rules = ();

while (defined(my $file = readdir(BASEDIR))) {
	open RULE, "$baseline/$file";
	while (<RULE>) {
		chomp;
		my ($key, undef) = split '=', $_;

		if ($key =~ m!(/PMG/CONFIG/[^/]+/).+!) {	# Log monitoring
			push @rules, $1;
		} elsif ($key =~ m!(/PUK/PROCPRES/[^/]+/).+!) {	# Process monitoring
			push @rules, $1;
		} else {
			push @rules, $key;
		}
	}

	close RULE;
}

closedir BASEDIR;

my ($f_was, $f_sybase, $f_oracle) = 0;

foreach my $line (@patrol_config) {
	#next if $line =~ m!!;
	
	# Lines we know about
	# Header line
	next if $line eq 'PATROL_CONFIG';
	
	# Skip lines that don't start "/
	next unless $line =~ m!"/!; #"
	
	# Patrol config stuff
	next if $line =~ m!/ALERT/|/APPLICATION_CLASSES/|/NOTIFICATION_SERVER|/AgentSetup/|/AS/a|/PMG/STATE/FILES/|/snmp/!;
	next if $line =~ m!/PMG/CONFIG/monDefault|/PUK/FILESYSTEM/moniList|/PUK/PROCCONT/daemonObjectList|/RecoveryActions/FILESYSTEM/\*/FSCapacity/!;
	next if $line =~ m!/AS/EVENTSPRING/RemoteAgentCommSettings|/AS/EVENTSPRING/arsAction|/AS/EVENTSPRING/useEnvOnlyForCmds|/AS/EVENTSPRING/PARAM_SETTINGS/STATUSFLAGS/paramSettingsStatusFlag|/AS/EVENTSPRING/PARAM_SETTINGS/THRESHOLDS/AS_EVENTSPRING/!;
	next if $line =~ m!/UNIX/PROCCONT/|/PUK/Process/Default|/PUK/SNMPHealth|/PUK/pukserver!;
	next if $line =~ m!/EventRules/catalogs|/PMG/STATE|/PUK/[0-9.]+/migration!;
	next if $line =~ m!/MaxNumLockChanFail|/AS/EVENTSPRING/PARAM_SETTINGS/THRESHOLDS/SNMPHealth/__ANYINST__/SNMPH_monitorSubAgent|/AS/EVENTSPRING/PARAM_SETTINGS/THRESHOLDS/USERS/__ANYINST__/USRNoUser!;
	
	# Remove anything that is disabled
	next if $line =~ m!REPLACE = \"0!;	
	
	# Remove any reference to DCM
	next if $line =~ /DCM/;
	next if $line =~ m!/UNIX_OS/PERFORM_HOME|/UNIX/FILESYSTEM/discovery|^"/FILESYSTEM!;	#"
	next if $line =~ m!/UNIX/FILESYSTEM/.+Tokens|/UNIX/DISK/discovery|/UNIX/FILESYSTEM/DialogTO!;

	# Finally remove some monitors which are enabled, but have no thresholds set
	next if $line =~ m!REPLACE = "1,0 0 0 0 0 0,0 0 0 0 0 0,0 0 0 0 0 0"!;
	
	# Check whether a known KM is required
	if ($line =~ m!WEBSPHERE|PMW|/JMX!) {	# Websphere AS
		$f_was = 1;
		next;
	}
	
	if ($line =~ m!SybaseConfig|SYBRS_|SYBMON_|SYBASE_|/ADVISOR/SybaseInstances!) {	# Sybase
		$f_sybase = 1;
		next;
	}
	
	if ($line =~ m!OracleConfig|ORACLE|ORA_|ORANET_|OraNetConfig|/maxHome|/ADVISOR/[Cartridges|OracleInstances]!) {	# Oracle
		$f_oracle = 1;
		next;
	}
	
	# Now check the remaning rules against the baseline for this system
	my $flag = 0;
	foreach my $rule (@rules) {
		$flag = 1 if $line =~ m!$rule!;
	}
	next if $flag;
	
	print OUT "$line\n";
}

# Print out any Middleware KM details
print "[KM] Websphere AS KM detected\n" if $f_was;
print "[KM] Sybase KM detected\n" if $f_sybase;
print "[KM] Oracle KM detected\n" if $f_oracle;

close OUT;

exit;

