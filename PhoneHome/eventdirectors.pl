# $Id: eventdirectors.pl 1579 2011-10-06 13:46:03Z harperri $
# $URL: https://ims-svn.swissbank.com/prod-kerb/AGENTENG/trunk/dmcp/htdocs/config/eventdirectors.pl $
$ENV{ORACLE_HOME} = '/sbcimp/run/tp/oracle/client/v10.2.0.2.0-32bit';

use strict;

use CGI qw(param header);

use lib qw( /sbclocal/dmcp/perllib /sbcimp/run/pd/cpan/5.8.8-2006.03/lib );
use DBI;

# Get the Apache::Registry handlers & Oracle details
my $r		= shift;
my $dmcp_dbname	= $r->dir_config('dmcp_dbname');
my $dmcp_dbuser	= $r->dir_config('dmcp_dbuser');
my $dmcp_dbpass	= $r->dir_config('dmcp_dbpass');

my $q		= new CGI;
my $SERVER_ENV	= $q->param('env');
my $LOB_ID	= $q->param('lob');
my $REGION	= $q->param('region');

# If no host is defined (for some reason), return a valid fragment and finish
unless ($q->param('env')) {
	print header('text/xml');

	print "<Fragment />\n";
	exit;
}

my $no_hbts	= "";
$no_hbts	= $q->param('ov');

my ($dev, $env)				= undef;
my ($lookup_region, $failover_hbts)	= undef;

# Connect to Oracle. This is already done for us by Apache::DBI, but we need to run to pick up the handle
my $dbh	= DBI->connect("DBI:Oracle:$dmcp_dbname", $dmcp_dbuser, $dmcp_dbpass);

print header('text/xml');
print "<Fragment>\n";

my $td_sql = $dbh->prepare(
qq(	SELECT primary_alias, primary_ip, failover_alias, failover_ip, port, community, class_num
		FROM trap_destinations WHERE
		cv_lobs_id = ? AND
		cv_environments_id = ?	AND
		trap_type = ? AND
		region = ?
)) or die "Couldn't prepare statement: " . $dbh->errstr;

# If engineering system, traps go to a common region ('Global')
$REGION = "Global" if $SERVER_ENV == 4;

# Get the shortname for this LOB
my $lob_sql = $dbh->prepare( 'select short_name from cv_lobs where id = ?' );
$lob_sql->execute($LOB_ID);
my ($group) = $lob_sql->fetchrow_array();

if ($LOB_ID == 2 or !$LOB_ID) {	# Default to IB if LOB is not defined
	# IB Server
	$group = "IB" unless $group;

	if ($SERVER_ENV == 3) {
		$dev = 1;
		$SERVER_ENV = 1;
	}
	
	# Default region setting
	$REGION = "EMEA" unless $REGION;

	# Get the Event Destinations
	$td_sql->execute($LOB_ID, $SERVER_ENV, 0, $REGION);

	while (my $ref = $td_sql->fetchrow_hashref()) {
		write_event_trap("pri-events", $ref->{'PRIMARY_IP'}, $ref->{'PORT'}, $ref->{'COMMUNITY'});
		write_event_trap("fail-events", $ref->{'FAILOVER_IP'}, $ref->{'PORT'}, $ref->{'COMMUNITY'});
	}

	# Add development trap destination?
	if ($dev) {
		$td_sql->execute($LOB_ID, 3, 0, $REGION);

		while (my $ref = $td_sql->fetchrow_hashref()) {
			write_event_trap("dev-events", $ref->{'PRIMARY_IP'}, $ref->{'PORT'}, $ref->{'COMMUNITY'});
		}
	}

	# Get the Heartbeat Destinations
	$SERVER_ENV = 1 if ($SERVER_ENV == 3);	# Reset development hosts to heartbeat to production

	$td_sql->execute($LOB_ID, $SERVER_ENV, 1, $REGION);

	while (my $ref = $td_sql->fetchrow_hashref()) {
		write_heartbeat_trap('pri-heartbeats', $ref->{'PRIMARY_IP'}, $ref->{'PORT'}, $ref->{'COMMUNITY'}, $ref->{'CLASS_NUM'});

		if ($ref->{'FAILOVER_IP'} ne '') {
			$failover_hbts = 1;
			write_heartbeat_trap('fail-heartbeats', $ref->{'FAILOVER_IP'}, $ref->{'PORT'}, $ref->{'COMMUNITY'}, $ref->{'CLASS_NUM'});
		}
	}

	write_heartbeat_monitor(60, $failover_hbts) unless $no_hbts;

} elsif ($LOB_ID == 5) {

	# Default region setting
	$REGION = "GON-CH" if $REGION eq '';	

	# Get the Event Destinations
	$td_sql->execute($LOB_ID, $SERVER_ENV, 0, $REGION);

	while (my $ref = $td_sql->fetchrow_hashref()) {
		write_event_trap("pri-events", $ref->{'PRIMARY_IP'}, $ref->{'PORT'}, $ref->{'COMMUNITY'});
		write_event_trap("fail-events", $ref->{'FAILOVER_IP'}, $ref->{'PORT'}, $ref->{'COMMUNITY'});
	}

	# Get heartbeat destinations
	$td_sql->execute($LOB_ID, $SERVER_ENV, 1, $REGION);
	while (my $ref = $td_sql->fetchrow_hashref()) {
		write_heartbeat_trap('pri-heartbeats', $ref->{'PRIMARY_IP'}, $ref->{'PORT'}, $ref->{'COMMUNITY'}, '%(class)s');

		if ($ref->{'FAILOVER_IP'} ne '') {
			$failover_hbts = 1;
			write_heartbeat_trap('fail-heartbeats', $ref->{'FAILOVER_IP'}, $ref->{'PORT'}, $ref->{'COMMUNITY'}, '%(class)s');
		}
	}
	write_heartbeat_monitor(60, $failover_hbts) unless $no_hbts;

} elsif ($LOB_ID == 4) {

	# Default region setting
	$REGION = "London" unless $REGION;

	$td_sql->execute($LOB_ID, $SERVER_ENV, 0, $REGION);

	while (my $ref = $td_sql->fetchrow_hashref()) {
		write_event_trap("pri-events", $ref->{'PRIMARY_IP'}, $ref->{'PORT'}, $ref->{'COMMUNITY'});
		write_event_trap("fail-events", $ref->{'FAILOVER_IP'}, $ref->{'PORT'}, $ref->{'COMMUNITY'});
	}
	$td_sql->execute($LOB_ID, $SERVER_ENV, 1, $REGION);

	while (my $ref = $td_sql->fetchrow_hashref()) {
		write_heartbeat_trap('pri-heartbeats', $ref->{'PRIMARY_IP'}, $ref->{'PORT'}, $ref->{'COMMUNITY'}, $ref->{'CLASS_NUM'});
		if ($ref->{'FAILOVER_ALIAS'} ne '') {
			$failover_hbts = 1;
			write_heartbeat_trap('fail-heartbeats', $ref->{'FAILOVER_IP'}, $ref->{'PORT'}, $ref->{'COMMUNITY'}, $ref->{'CLASS_NUM'});
		}
	}

	write_heartbeat_monitor(60, $failover_hbts) unless $no_hbts;

} elsif ($LOB_ID == 3) {

	# Get the Heartbeat Destinations
	$REGION		= "Americas";	# All WMA machines are in 'Americas'
	$td_sql->execute($LOB_ID, $SERVER_ENV, 0, $REGION);

	while (my $ref = $td_sql->fetchrow_hashref()) {
		write_event_trap("pri-events", $ref->{'PRIMARY_IP'}, $ref->{'PORT'}, $ref->{'COMMUNITY'});
		write_event_trap("fail-events", $ref->{'FAILOVER_IP'}, $ref->{'PORT'}, $ref->{'COMMUNITY'});
	}

	# Get heartbeat destinations from database
	$td_sql->execute($LOB_ID, $SERVER_ENV, 1, $REGION);

	while (my $ref = $td_sql->fetchrow_hashref()) {
		write_heartbeat_trap('pri-heartbeats', $ref->{'PRIMARY_IP'}, $ref->{'PORT'}, $ref->{'COMMUNITY'}, '%(class)s');

		if ($ref->{'FAILOVER_IP'} ne '') {
			$failover_hbts = 1;
			write_heartbeat_trap('fail-heartbeats', $ref->{'FAILOVER_IP'}, $ref->{'PORT'}, $ref->{'COMMUNITY'}, '%(class)s');
		}
	}
	write_heartbeat_monitor(60, $failover_hbts) unless $no_hbts;
} else {
	# Unknown server location, default to IB
}

print "</Fragment>\n";

sub write_heartbeat_trap {
	my ($event_name, $ip, $port, $community, $class) = @_;
	print <<_XML_;
  <Trap name="$event_name">
    <Parameter name="destination">$ip:$port</Parameter>
    <Parameter name="version">1</Parameter>
    <Parameter name="community">$community</Parameter>
    <Parameter name="enterpriseOid">.1.3.6.1.4.1.10982.100</Parameter>
    <Parameter name="genericTrap">6</Parameter>
    <Parameter name="specificTrap">99</Parameter>
    <Parameter name="object" index="1">.1.3.6.1.4.1.10982.0.200.1;s;%(fqdn)s</Parameter>
    <Parameter name="object" index="2">.1.3.6.1.4.1.10982.0.200.2;s;%(version)s</Parameter>
    <Parameter name="object" index="3">.1.3.6.1.4.1.10982.0.200.3;s;$group</Parameter>
    <Parameter name="object" index="4">.1.3.6.1.4.1.10982.0.200.4;s;%(location)s</Parameter>
    <Parameter name="object" index="5">.1.3.6.1.4.1.10982.0.200.5;s;%(region)s</Parameter>
    <Parameter name="object" index="6">.1.3.6.1.4.1.10982.0.200.6;s;$class</Parameter>
    <Parameter name="object" index="7">.1.3.6.1.4.1.10982.0.200.7;s;%(platform)s</Parameter>
    <Parameter name="object" index="8">.1.3.6.1.4.1.10982.0.200.8;s;%(environment)s</Parameter>
  </Trap>

_XML_

}

sub write_event_trap {
	my ($event_name, $ip, $port, $community) = @_;
	print <<_XML_;
  <Trap name="$event_name">
    <Parameter name="destination">$ip:$port</Parameter>
    <Parameter name="version">1</Parameter>
    <Parameter name="community">$community</Parameter>
    <Parameter name="enterpriseOid">.1.3.6.1.4.1.10982.100</Parameter>
    <Parameter name="genericTrap">6</Parameter>
    <Parameter name="specificTrap">1</Parameter>
    <Parameter index="1" name="object">.1.3.6.1.4.1.10982.0.200.1;s;%(monitor)s</Parameter>
    <Parameter index="2" name="object">.1.3.6.1.4.1.10982.0.200.2;s;%(prefix)s</Parameter>
    <Parameter index="3" name="object">.1.3.6.1.4.1.10982.0.200.3;s;%(alertkey)s</Parameter>
    <Parameter index="4" name="object">.1.3.6.1.4.1.10982.0.200.4;s;%(alertgroup)s</Parameter>
    <Parameter index="5" name="object">.1.3.6.1.4.1.10982.0.200.5;s;%(class)s</Parameter>
    <Parameter index="6" name="object">.1.3.6.1.4.1.10982.0.200.6;s;%(subclass)s</Parameter>
    <Parameter index="7" name="object">.1.3.6.1.4.1.10982.0.200.7;s;%(message)s</Parameter>
    <Parameter index="9" name="object">.1.3.6.1.4.1.10982.0.200.9;s;%(environment)s</Parameter>
    <Parameter index="10" name="object">.1.3.6.1.4.1.10982.0.200.10;s;$group</Parameter>
    <Parameter index="11" name="object">.1.3.6.1.4.1.10982.0.200.11;s;%(parameter)s:%(object)s:%(agent)s</Parameter>
    <Parameter index="12" name="object">.1.3.6.1.4.1.10982.0.200.12;s;%(suppression)s</Parameter>
  </Trap>

_XML_
}

sub write_heartbeat_monitor {
	my ($hbt_interval, $failover_hbts) = @_;
	print <<_XML_;
  <Component name="base" type="GENERIC_EMPTY">
    <Monitor name="heartbeating" type="agent.mon.heartbeat" periodicity="$hbt_interval">
      <Observation name="obs">
        <Test type="true">
          <Parameter name="arg0">1</Parameter>
        </Test>
        <Trap name="pri-heartbeats" />
_XML_
	print "        <Trap name=\"fail-heartbeats\" />\n" if $failover_hbts;
	print <<_XML_;
      </Observation>
    </Monitor>
  </Component>

_XML_

}
