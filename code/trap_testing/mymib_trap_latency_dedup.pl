#!/sbcimp/run/pd/perl/5.8.3/bin/perl -w

#use Net::Domain qw(hostname hostfqdn hostdomain);
use Net::SNMP qw(:ALL);
use Time::HiRes qw(gettimeofday);
use strict;

#my $trap_source = hostfqdn ();
my $counter = 0;
#my $trap_dest = "151.191.119.235";	# xstm1935dap
#my $trap_dest = "151.191.98.138";	# xstm9838dap
my $trap_dest = "151.191.119.183";	# xstm1953dap
my $trap_community = 'public';
#my $trap_port = 1620;
my $trap_port = 50162;

#my ($node,$nodealias)=getHostInfo(hostname());

#sub getHostInfo{
	#my $host = shift;
	#my ($name, $aliases, $addrtype,$length,@addrs)=gethostbyname($host);
	#my @addr= unpack('C4',$addrs[0]);
	#return(join(".", @addr), $name);
	#}

# This bit starts the timer to determine the elapsed time
my $t0 = gettimeofday;

print STDOUT "Traps being transmitted at $t0\n";

# Here we start the loop. The logic will be a bit ovelry complicated as we need to create new sessions for each trap.

while ($counter < 99 ) {
	#my ($session, $error) = Net::SNMP->session(
		#-hostname 	=>  $trap_source,
		#-community 	=> $trap_community,
		#-port		=> $trap_port,);

	my ($session, $error) = Net::SNMP->session(
		-hostname 	=>  $trap_dest,
		-community 	=> $trap_community,
		-port		=> $trap_port,);



	if (!defined($session)) {
		printf("ERROR: %s.\n", $error);
		exit 1;
	}

	# Here we build the trap properly for UBS standard.
 
	my $time = time();
	my $result = $session->trap(
		-enterprise	=>	'1.3.6.1.4.1.666.1',
		-generictrap	=>	'6',
		-specifictrap	=>	'9999',
		-timestamp	=>	$time,
		-varbindlist	=>	[
		'1.3.6.1.4.1.666.1.1.1.0', OCTET_STRING, 'Not Used',
		'1.3.6.1.4.1.666.1.1.2.0', OCTET_STRING, 'Not Used',
		'1.3.6.1.4.1.666.1.1.3.0', OCTET_STRING, 'Not Used',
		'1.3.6.1.4.1.666.1.1.4.0', OCTET_STRING, 'na',
		'1.3.6.1.4.1.666.1.1.5.0', OCTET_STRING, 'micromuse',
		'1.3.6.1.4.1.666.1.1.6.0', OCTET_STRING, 'Test Trap',
		'1.3.6.1.4.1.666.1.1.7.0', INTEGER, '4',
		'1.3.6.1.4.1.666.1.1.8.0', OCTET_STRING, "This is a test trap Number $counter"
		]
	);
	if (!defined($result)) {
		printf("ERROR: %s.\n", $session->error());

	}
	#else
	#{
		#printf("Trap-PDU sent.\n");
		#}

	$session->close();
	$counter++;
}

my $t1 = gettimeofday;
my $elapsed =$t1 - $t0;

print STDOUT "Traps all sent by $t1\n";
print STDOUT "$counter traps tooks $elapsed Seconds\n";
exit 0;
