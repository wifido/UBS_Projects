# $Id: getmyfiles.pl 1607 2011-10-24 09:41:52Z harperri $
# $URL: https://ims-svn.swissbank.com/prod-kerb/AGENTENG/trunk/dmcp/htdocs/config/getmyfiles.pl $
#$ENV{ORACLE_HOME} = '/sbcimp/run/tp/oracle/client/v10.2.0.2.0-32bit';

use strict;

use CGI qw(param header);
use DBI;

my $q			= new CGI;

# Get the Apache::Registry handlers & Oracle connection details
my $r			= shift;
my $dmcp_dbname		= $r->dir_config('dmcp_dbname');
my $dmcp_dbuser		= $r->dir_config('dmcp_dbuser');
my $dmcp_dbpass		= $r->dir_config('dmcp_dbpass');

my $servername		= $q->param('host');
my $UBS_VERSION		= $q->param('update');
my $LOB			= $q->param('lob');
my $OS			= lc($q->param('OS'));
my $OS_VER		= $q->param('OS_VER');

my $tla			= undef;
my ($host, @domain)	= split '\.', $servername;

# Work out what key to use into regloc
# Get the last two pieces - this should cover most situations
my $top_level = join '.', $domain[-2], $domain[-1];
my $top_three = join '.', $domain[-3], $domain[-2], $domain[-1];

if ($top_level eq 'swissbank.com') {
	# IB is well behaved
	$tla = $domain[-3];

} elsif ($top_level eq 'ubsamch.net' or $top_level eq 'ubsluxdm.net' or $top_level eq 'ubsusapb.net') {
	$tla = join '.', $domain[-2], $domain[-1];
	
} elsif ($top_three eq 'zur.ubs.net' or $top_three eq 'itdn.ubs.net' or $top_three eq 'gdzd.ubs.net') {
	$tla = $domain[-3];

} elsif ($top_level eq 'ubs.ch' or $top_level eq 'ubs.net' or $top_level eq 'ubs.com') {
	# Take the 4th from last element
	$tla = $domain[-4];
	$tla = $domain[-3] if $tla eq 'city';
	
} else {
	# Last resort - use the first piece of domainname
	$tla = shift @domain;

}

my $server_environment	= undef;
my $OS_REL		= undef;
my ($location, $region)	= undef;
my ($server_status, $server_lifecycle)
			= 'UNKNOWN';
my $server_inka		= 0;
my $lob_class_id	= 0;

my $DMCP_SERVER		= $ENV{'SERVER_NAME'};
my $protocol		= 'http';
$protocol 		= 'https' if $ENV{'HTTPS'} ;

$DMCP_SERVER		= $protocol.'://'.$DMCP_SERVER;

# Add port if required
if ($ENV{'HTTPS'}) {
	$DMCP_SERVER	.= ':'. $ENV{'SERVER_PORT'} unless ($ENV{'SERVER_PORT'} == '443');
} else {
	$DMCP_SERVER	.= ':'. $ENV{'SERVER_PORT'} unless ($ENV{'SERVER_PORT'} == '80');
}

$UBS_VERSION 		= '00000000' unless $UBS_VERSION;

# If no host is defined (for some reason), return a valid fragment and finish
unless ($host) {
	print header('text/xml');

	print "<Fragment />\n";
	exit;
}

# Connect to Oracle. This is already done for us by Apache::DBI, but we need to run to pick up the handle
my $dbh	= DBI->connect("DBI:Oracle:$dmcp_dbname", $dmcp_dbuser, $dmcp_dbpass);
my $sth	= undef;

my $platform_release = undef;

# Resolve LOB into numerical value
$sth = $dbh->prepare('SELECT id FROM cv_lobs WHERE lob = ?');
$sth->execute($LOB);
my ($LOB_ID) = $sth->fetchrow_array();

# Resolve OS types & versions
if ($OS eq 'linux') {
	# Determine if this is a VMware ESX server first
	if ($OS_VER =~ /vmnix/) {
		$OS = 'vmware';
		if ($OS_VER =~ /^2\.4\.9.*$/) {
			# ESX 2.5
			$platform_release = '2.5';
		} elsif ($OS_VER =~ /^2\.4\.21-37.*$/) {
			# ESX 3.0
			$platform_release = '3.0';
		} elsif ($OS_VER =~ /^2\.4\.21-57.*$/) {
			# ESX 3.5
			$platform_release = '3.5';
		}
	} else {
		if ($OS_VER =~ /^2\.4\.9.*$/) {
			# AS2.1
			$platform_release = '2.1';
		} elsif ($OS_VER =~ /^2\.4\.21.*$/) {
			# RHEL3
			$platform_release = '3';
		} elsif ($OS_VER =~ /^2\.6\.18.*$/) {
			# RHEL5
			$platform_release = '5';
		} elsif ($OS_VER =~ /^2\.6\.32.*$/) {
			# RHEL6
			$platform_release = '6';
		}
	}
} elsif ($OS eq 'sunos') {
	if ($OS_VER eq '5.8' or $OS_VER eq '5.9') {
		$platform_release = '8';
	} elsif ($OS_VER eq '5.10') {
		$platform_release = '10';
	} elsif ($OS_VER eq '5.10z') {
		$platform_release = '10z';
	}
} elsif ($OS eq 'aix') {
	if ($OS_VER =~ /^52.+$/) {
		$platform_release = '5.2';
	} elsif ($OS_VER =~ /^53.+$/) {
		$platform_release = '5.3';
	} elsif ($OS_VER =~ /^61.+$/) {
		$platform_release = '6.1';
	} else {
		$platform_release = '5.3';
	}
} elsif ($OS eq 'darwin') {
	$platform_release = '10';
}

# Get the location & region
if ($LOB eq 'wmi') {
	# Base WMI on start of hostname
        $host =~ /^[a-z]{1}([a-z]{2}).+/;
        my $loccode = $1;
        if ($loccode eq 'ln') {
                $location = 'Europe';
                $region = 'London';
        } elsif ($loccode eq 'ff' or $loccode eq 'fr') {
                $location = 'Europe';
                $region = 'Frankfurt';
        } else {
                $location = 'Europe';
                $region = 'London';
        }
} else {
	# Base everything else on the key we found earlier in the domainname
	$sth = $dbh->prepare('SELECT location, region FROM reglocs WHERE tla = ?');
	$sth->execute($tla);
	while (my @reg_loc = $sth->fetchrow_array()) {
		($location, $region) = @reg_loc;
	}
}

# Where is this host and what environment is it in? This determines whether the machine gets
# automatic monitoring (IB, WMI, WMA) or whether it just needs config group manifests
($server_environment, $server_status, $server_lifecycle, $server_inka)
		= getenv($LOB, $servername);

my $temp_env = 0;
# Reset environment for use in SERVERS
if ($server_environment < 10) {
	$temp_env = $server_environment;
} else {
	$temp_env = $server_environment - 10;
}

# When did this host last contact DMCP?
$sth = $dbh->prepare('SELECT id, ip, lastdate FROM servers WHERE hostname in (?, ?)');
$sth->execute($host, $servername);
my $last_contact = $sth->fetchrow_hashref();
my $SERVERS_ID = $last_contact->{'ID'} if $last_contact->{'ID'};

# We have seen this host before, update the last contact timestamp
#   (providing the request has actually come from the agent, based
#   on the HTTP_USER_AGENT

if ($ENV{'HTTP_USER_AGENT'} =~ /Python-urllib/) {

	# Log this system into the servers table now to obtain its ID in SERVERS
	my $remote_ip = 0;
	if ($ENV{'HTTP_X_FORWARDED_FOR'}) {
		$remote_ip = $ENV{'HTTP_X_FORWARDED_FOR'};
	} else {
		$remote_ip = $ENV{'REMOTE_ADDR'};
	}
	
	if ($last_contact->{'LASTDATE'} eq '' and $last_contact->{'IP'} eq '') {
		# First time this host has contacted the DB, add an entry

		# Get the next ID available
		$sth = $dbh->prepare('SELECT servers_seq.NEXTVAL FROM dual');
		$sth->execute();
		my ($SERVERS_ID) = $sth->fetchrow_array();

		my $insert_sql = $dbh->prepare( <<_SQL_ );
INSERT INTO servers (id, 
  hostname, ip, lastdate, firstdate,
  version, os, os_version,
  cv_lobs_id, cv_environments_id, inka
) VALUES ( servers_seq.nextval, 
  ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
)
_SQL_

		$insert_sql->execute($servername, $remote_ip, time(), time(), $UBS_VERSION, $OS, $platform_release, $LOB_ID, $temp_env, $server_inka);

	} elsif ($last_contact->{'LASTDATE'} eq '' and $last_contact->{'IP'} eq '0.0.0.0') {

		# This host has been added already (probably to exempt it), but we haven't seen the agent before
		my $insert_sql = $dbh->prepare( <<_SQL_ );
UPDATE servers SET
  lastdate = ?,
  firstdate = ?,
  ip = ?,
  version = ?,
  os = ?,
  os_version = ?,
  cv_lobs_id = ?,
  cv_environments_id = ?,
  inka = ?
WHERE id = ?
_SQL_

		$insert_sql->execute(time(), time(), $remote_ip, $UBS_VERSION, $OS, $platform_release, $LOB_ID, $temp_env, $server_inka, $SERVERS_ID);

	} else {
		my $insert_sql = $dbh->prepare( <<_SQL_ );
UPDATE servers SET
  lastdate = ?,
  version = ?,
  os = ?,
  os_version = ?,
  cv_lobs_id = ?,
  cv_environments_id = ?,
  inka = ?
WHERE id = ?
_SQL_

		$insert_sql->execute(time(), $UBS_VERSION, $OS, $platform_release, $LOB_ID, $temp_env, $server_inka, $SERVERS_ID);
	}
}

my @cfg_grps	= ();
my @my_cfg_grps = ();
my $myfiles	= {};
my $file_id	= 0;
my $t_effective	= 0;
my @implied_groups = ();
my $WMSB_class_id;
my $WMSB_csc_profile;
	
if ($LOB eq 'wmus') {	
	# Class ID depends on platform (for Agent field lookup in Netcool)
	if ($OS eq 'aix') {
		$lob_class_id = 6000128;
	} elsif ($OS eq 'linux') {
		$lob_class_id = 6000129;
	} else {
		# Default to Solaris
		$lob_class_id = 6000123;
	}
			
} elsif ($LOB eq 'wmbb') {
			
	# Get the filterpath from the table
	my $filter_path = $dbh->prepare('SELECT class, name FROM wmsb_filter_paths w JOIN cv_class c ON w.class = c.id WHERE hostname = ?');
	$filter_path->execute($servername);
	($WMSB_class_id, $WMSB_csc_profile) = $filter_path->fetchrow_array();

	# Default values for info from WMSB filter paths if they're still empty
	unless ($WMSB_class_id) {
		if ($OS eq 'sunos') {
			$WMSB_class_id		= '6000112';
			$WMSB_csc_profile	= 'cscOLUprod';
		} elsif ($OS eq 'aix') {
			$WMSB_class_id		= '6000106';
			$WMSB_csc_profile	= 'cscDWHprod';
		} else {
			# Default to cscOLUprod
			$WMSB_class_id		= '6000112';
			$WMSB_csc_profile	= 'cscOLUprod';
		}
	}
}

# Get the main configs for this server
# If the environment is > 10, it doesn't need main configs
if ($server_environment < 10) {
	# Find the configuration group associated with this LOB/OS/REL/ENV type
	$sth = $dbh->prepare('SELECT group_id FROM standardunix_groups WHERE cv_lobs_id = ? AND os = ? AND os_version = ? AND cv_environments_id = ?');
	$sth->execute($LOB_ID, $OS, $platform_release, $server_environment);

	# Push any standard UNIX monitoring into @cfg_grps
	while (my ($group) = $sth->fetchrow_array()) {
		push @cfg_grps, $group;
	}
} else {
	# Reset the environment to a valid value
	$server_environment = $server_environment - 10;
}

$server_environment = 1 if ($server_environment == 5); # Reset Premium hosts to production

# Keep a record of which groups are implied and which are explicit (if any)
if (scalar @cfg_grps) {
	my $group_sql = 'SELECT id FROM groups START WITH id IN (?';
	for (my $i = 1; $i < scalar @cfg_grps; $i++) {
		$group_sql .= ',?';
	}
	$group_sql .= ') CONNECT BY PRIOR parent_id = id';
	
	$sth = $dbh->prepare($group_sql);
	$sth->execute(@cfg_grps);
	while (my $group = $sth->fetchrow_hashref()) {
		push @implied_groups, $group->{'ID'};
	}
}

# What files does this machine need
$sth = $dbh->prepare('SELECT group_id, active FROM groups_servers WHERE server_id = ?');

# What config group is this agent in?
$sth->execute($SERVERS_ID);
while (my $group = $sth->fetchrow_hashref()) {
	push @cfg_grps, $group->{'GROUP_ID'} if $group->{'ACTIVE'} eq 'Y';
}

# If the server is in any groups, find out what the parents of those groups are
if (scalar @cfg_grps) {
	my $group_sql = 'SELECT id FROM groups START WITH id IN (?';
	for (my $i = 1; $i < scalar @cfg_grps; $i++) {
		$group_sql .= ',?';
	}
	$group_sql .= ') CONNECT BY PRIOR parent_id = id';

	$sth = $dbh->prepare($group_sql);
	$sth->execute(@cfg_grps);
	while (my $group = $sth->fetchrow_hashref()) {
		push @my_cfg_grps, $group->{'ID'};
	}

	my $manifest_sql = 'SELECT c.id id, g.group_id group_id, c.override_url url, c.path path, c.name name, g.active active FROM groups_confs g JOIN confs c on g.conf_id = c.id WHERE g.group_id in (?';
	for (my $i = 1; $i < scalar @my_cfg_grps; $i++) {
		$manifest_sql .= ',?';
	}
	$manifest_sql .= ')';

	# Get all the manifests in the selected groups
	$sth = $dbh->prepare($manifest_sql);
	$sth->execute(@my_cfg_grps);

	# Push the manifest list into the $myfiles hash, indexed by $file_id
	while (my $config = $sth->fetchrow_hashref()) {
		$myfiles->{$file_id} = $config;
		$file_id++;
	}
}

# print manifest reply
print header('text/xml');
manifest($t_effective);

sub manifest {
	my $update	= shift;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)
			= undef;

	my $effective_DTS = "2007/01/01 00:00:00";
	if ($update) {
		($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($update);
		$effective_DTS = sprintf("%04d/%02d/%02d %02d:%02d:%02d", $year + 1900, $mon + 1, $mday, $hour, $min, $sec);
	}

	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime();
	my $update_DTS = sprintf("%04d/%02d/%02d %02d:%02d:%02d", $year + 1900, $mon + 1, $mday, $hour, $min, $sec);

	# Remap agent for MIRO
	my $AGENT = uc($OS);
	$AGENT = 'SOLARIS' if $AGENT eq 'SUNOS';

	print <<_XML_;
<Manifest name="default"
	updated="$update_DTS"
	effectiveFrom="$effective_DTS"
	xmlns:xi="http://www.w3.org/2001/XInclude">

	<!-- Define some UBS Global variables -->
	<Variable name="version">$UBS_VERSION</Variable>
	<Variable name="platform">$OS $OS_VER</Variable>
	<Variable name="fqdn">$servername</Variable>
	<Variable name="location">$location</Variable>
	<Variable name="region">$region</Variable>

	<!-- Define trap variables. These are overwritten within monitors -->
	<Variable name="monitor">0</Variable>
	<Variable name="prefix">default</Variable>
	<Variable name="alertkey">0</Variable>
	<Variable name="alertgroup">0</Variable>
	<Variable name="subclass">0</Variable>
	<Variable name="parameter">0</Variable>
	<Variable name="object">0</Variable>
	<Variable name="agent">$AGENT</Variable>
	<Variable name="environment">$server_environment</Variable>
	<Variable name="suppression">0</Variable>

	<!-- Server data from iSAC -->
	<Variable name="current_state">$server_status</Variable>
	<Variable name="server_lifecycle">$server_lifecycle</Variable>
	
_XML_

	# Add in some LOB specific variables
	if ($LOB eq 'wmbb') {
		# Add class ID & CSC Profile for this host based on the filter path table (ESM supplied/managed)
		print "\t<!-- Add Class ID for WM&SB hosts based on filter path for this agent -->\n";
		print "\t<Variable name=\"class\">$WMSB_class_id</Variable>\n";
		print "\t<Variable name=\"cscprofile\">$WMSB_csc_profile</Variable>\n";	
	} else {
		print "\t<Variable name=\"class\">$lob_class_id</Variable>\n";
	}

	print <<_XML_;
	<!-- Include Trap Destinations -->
	<xi:include href="$DMCP_SERVER/config/eventdirectors.pl?env=$server_environment&amp;lob=$LOB_ID&amp;region=$region" />

	<!-- Include the files for this specific server -->
_XML_

	my @loadedconfigs = ();
	foreach my $conf_id (sort keys(%{$myfiles})) {
		my $url = undef;
		my $local_manifest = undef;
	
		# Construct the appropriate URL. Override URL takes precedence
		if ($myfiles->{$conf_id}->{'URL'}) {
			$url = $myfiles->{$conf_id}->{'URL'};
		} else {
			$local_manifest = "/manifests/".$myfiles->{$conf_id}->{'PATH'}."/".$myfiles->{$conf_id}->{'NAME'}.".xml";
			$url = $DMCP_SERVER.$local_manifest;
		}
	
		# Perform some checks on the configs being loaded
		if (grep(/^$url$/, @loadedconfigs)) {
			# Has this file already been added? Using a file twice will goose the agent
			print "\t<!-- Fragment '".$url."' has already been loaded -->\n";
		} elsif (defined($local_manifest) and ! -f $ENV{DOCUMENT_ROOT}.$local_manifest) {
			# If this is a published manifest, check it exists on the filesystem
			# If not, make a note of this
			print "\t<!-- Group ID ".$myfiles->{$conf_id}->{'GROUP_ID'}." -->\n";
			print "\t<!-- File '$url' has not been published yet -->\n";
		
		} else {
			print "\t<!-- Group ID ".$myfiles->{$conf_id}->{'GROUP_ID'}." -->\n";
			print "\t<!--" unless $myfiles->{$conf_id}->{'ACTIVE'} eq 'Y';
			print "\t<xi:include href=\"".$url."\" />";
			print " -->" unless $myfiles->{$conf_id}->{'ACTIVE'} eq 'Y';
			print "\n";

			# Only push active configs into @loadedconfigs
			push @loadedconfigs, $url if $myfiles->{$conf_id}->{'ACTIVE'} eq 'Y';
		}
	}

	print <<_XML_;
	<!-- Include Users -->
	<xi:include href="$DMCP_SERVER/config/getusers.pl" />
</Manifest>
_XML_
}

sub getenv {
	my $lob		= shift;
	my $fqdn	= shift;
	my ($host, undef)
			= split '\.', $fqdn;

	my $env;
	my $tag = 0;
	my $temp_env;
	
	# Is this a server requiring no standard monitoring (EXEMPT = 'Y')?
	my $exclusion = $dbh->prepare( 'SELECT exempt FROM servers WHERE hostname = ?' );
	$exclusion->execute($fqdn);
	my ($supportlevel) = $exclusion->fetchrow_array();

	$tag = 10 if $supportlevel eq 'Y';
		
	# Get some server information from iSAC
	my $server_status	= 'UNKNOWN';
	my $server_lfc		= 'UNKNOWN';
	my $inka		= 0;

	$sth = $dbh->prepare( 'SELECT * FROM isac_server_mv WHERE nodename = ?' );
	$sth->execute($host);

	while ( my $row = $sth->fetchrow_hashref() ) {
		$temp_env	= $row->{'IFV_OP_USE'};
		$server_status	= $row->{'IFV_OP_STATUS'};
		$server_lfc 	= $row->{'IFV_LFC'};
		$inka		= $row->{'IFV_INKA'};
	}
	
	# Normalise 'server status' based on 'lifecycle' where null
	if ($server_status eq '') {
		if ($server_lfc eq 'HW IN OPERATION') {
			$server_status = 'OPERATIONAL';
		} else {
			$server_status = 'UNKNOWN';
		}
	}
		
	if ($lob eq 'ib') {

		# Is this a premium server?
		my $premium = $dbh->prepare('SELECT supportlevel FROM support_levels WHERE hostname = ?');
		$premium->execute($host);
		my ($supportlevel) = $premium->fetchrow_array();

		# Premium systems as defined in support_level
		if ($supportlevel > 1) {
			return (5, $server_status, $server_lfc, $inka);
		}

		if ($host =~ /[xs]{1}[a-z]{3}[0-9]{4}[a-z]{3}/ ||               # xldn1052[d]ap
		  $host =~ /[xs]{1}[a-z]{4}[0-9]{3}[a-z]{2}[0-9]{1}/ ||         # sldnc123[d]n1
		  $host =~ /[xs]{1}[a-z]{4}[0-9]{3}[a-z]{3}/ ||                 # sldnc123[d]ap
		  $host =~ /e[a-z]{4}[0-9]{3}[npdb]{1}[a-z0-9]{3}/ ) {          # eldnf123[p]a2c
			$env = substr($host, 8, 1);
		} elsif ($host =~ /[a-z]{2}[0-9]{1}[dp]{1}[0-9]{1}[a-z]{3}/ ||  # ln1[d]1syb
		  $host =~ /[a-z]{2}[0-9]{1}[dp]{1}[0-9]{2}[a-z]{3}/ ||         # ln2[p]12swk
		  $host =~ /[a-z]{2}[0-9]{1}[dp]{1}[0-9]{3}[a-z]{3}/ ||         # ln3[p]123ora
		  $host =~ /[a-z]{2}[0-9]{1}[dp]{1}[0-9]{4}[a-z]{3}/ ) {        # ln4[p]1234cmp
			$env = substr($host, 3, 1);
		} elsif ($host =~ /[a-z]{2}[0-9]{2}[dp]{1}[0-9]{1}[a-z]{3}/ ) { # ln72[p]775swk
			$env = substr($host, 4, 1);
		} elsif ($host =~ /^[a-z]{5}[0-9]{6}[nvpdb]{1}/) {              # eldnc001020[p], sldnc901002vsy
			# Cluster server of some kind
			$env = substr($host, 11, 1);
		} else { #Unknown name convention
			$env = "u";
		}

		# Could be a workstation, treat it like an eng server
		# Also deal with Wintel desktops & laptops
		if ($host =~ /swk|pwk|dwk|nwk/ or
		  $host =~ /[wl]{1}[a-z]{3}[0-9]{7}/ ) {
			$env = "n";
		}

		if ($env eq "v") { # This may be a VM/zone etc, so check again
			if ($host =~ /[xs]{1}[a-z]{3}[0-9]{4}[a-z]{4}/) {       # xldn0118v[d]ap
				$env = substr($host, 9, 1);
			}
		}

		if ( $env =~ /[jsmbp]/ ) {
			return ($tag + 1, $server_status, $server_lfc, $inka);
		} elsif ( $env eq "d" ) {
			return ($tag + 3, $server_status, $server_lfc, $inka);
		} elsif ( $env =~ /[nv]/ ) {
			return ($tag + 4, $server_status, $server_lfc, $inka);
		} else {
			return ($tag + 1, $server_status, $server_lfc, $inka);
		}
		
	} elsif ($lob eq 'wmi') {
		$env = substr($host, 3, 1);	# Take the fourth letter & base the environment on that
		if ($env =~ /[pdus]/) {
			return (1, $server_status, $server_lfc, $inka);
		} elsif ($env eq 't') {
			return (3, $server_status, $server_lfc, $inka);
		} else {
			# Hostname doesn't conform to new standards - send it to PROD
			return (1, $server_status, $server_lfc, $inka);
		}
	
	} elsif ($lob eq 'wmus' or $lob eq 'wmbb') {
		# If server is not operational, give it a config & send everything to development
		if ($server_status ne 'OPERATIONAL') {
			$env = 3;
		} else {
			# Define the environment
			if ($temp_env eq 'PRODUCTION') {
				$env = $tag + 1;
			} elsif ($temp_env eq 'DEVELOPMENT' or $temp_env eq 'TEST') {
				$env = $tag + 3;
			} else {
				# Default to development
				$env = $tag + 3;
			}
		}

		return ($env, $server_status, $server_lfc, $inka);

	} else {
		# Default to engineering (although we should never get here)
		return (4, $server_status, $server_lfc, $inka);
	}
}
