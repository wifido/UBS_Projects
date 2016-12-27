#!/sbcimp/run/pd/perl/5.8.7/bin/perl -w

use Net::SNMP qw(:ALL);
use Time::HiRes qw(gettimeofday);
#use strict;

my $trap_community = 'OSXAGENT_HB';


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
$loop = $loop + 1;
$string2 = "ssm_logmonx_include.rules" . $loop;
	# Here we build the trap properly for UBS standard.
 
	my $time = time();
	my $result = $session->trap(
		-enterprise	=>	'.1.3.6.1.4.1.1977',
		-generictrap	=>	'6',
		-specifictrap	=>	'46',
		-timestamp	=>	$time,
		-varbindlist	=>	[
		'.1.3.6.1.4.1.1977.30.1.1.3.28', OCTET_STRING, $string2, 
		'.1.3.6.1.4.1.1977.30.3.1.3.28.1.2', OCTET_STRING, $string, 
		'.1.3.6.1.4.1.1977.30.3.1.4.28.1.2', OCTET_STRING, '3', 
		'.1.3.6.1.4.1.1977.30.1.1.14.28', OCTET_STRING, 'OracleError' 
		]
	);
	if (!defined($result)) 
	{
		printf("ERROR: %s.\n", $session->error());

	}


	$session->close();
	print "Trap Dest > $trap_dest    Port > $trap_port \n";
}

my $loop = 0;
	$string = "[ 20061110000017 Fri10-00:00-SGSIDED3:Oracle:-n:major:Instance SGSIDED3 Fail to report exceeds 00.03.00]";
	do_trap("151.191.98.138", "50162");

$string = "[ 20061110000017 Fri10-00:00-SGSIDED3:Oracle:-n:major:Instance SGSIDED3 Fail to report exceeds 00.03.00]";
	do_trap("151.191.98.138", "50162");
$string = "[ 20061110105200 Fri10-10:52-stky1286dor:Oracle:dbs_oramonitor:major:ggsrepmon is not active and heartbeat exceeds 720Minutes]";
	do_trap("151.191.98.138", "50162");
$string = "[ 20061110195252 Fri10-19:52-TKA4DT:Oracle:bolog:major:ORA-1654: unable to extend index TKA4_DBO.PK_LOGSCRAPERMSG by 8 in tablespace DBO_TKA4]";
	do_trap("151.191.98.138", "50162");
$string = "[ 20061110185201 Fri10-18:52-ssng1268dor:Oracle:dbs_oramonitor:major:ggsrepmon is not active and heartbeat exceeds 720Minutes]";
	do_trap("151.191.98.138", "50162");
$string = "[ 20061110185251 Fri10-18:52-LEERZT1:Oracle:IPING1043:major:Instance LEERZT1 Fail to Connect]";
	do_trap("151.191.98.138", "50162");
$string = "[ 20061110185211 Fri10-18:52-SGWMCPD1:Oracle:-n:major:Instance SGWMCPD1 Fail to report exceeds 00.03.00]";
	do_trap("151.191.98.138", "50162");
$string = "[ 20061110021028 Fri10-02:10-PANDAD1:Oracle:TOOLS:minor:Database PANDAD1 Tablespace TOOLS exceeds 93%]";
	do_trap("151.191.98.138", "50162");
$string = "[ 20061110104732 Fri10-10:47-SYDRAPQ2:Oracle:bolog:major:ORA-20500 dars audit trail content too old]";
	do_trap("151.191.98.138", "50162");
$string = "[ 20061109172801 Thu09-17:28-LNOIDE3:Oracle:bolog:major:ORA-27037: unable to obtain file status]";
	do_trap("151.191.98.138", "50162");
$string = "[ 20061110105027 Fri10-10:50-GGLDWS9:Oracle:bolog:major:ORA-01110: data file 12: /sbclocal/app/oracle/product/9.2.0.6.0.1/dbs/MISSING00012]";
	do_trap("151.191.98.138", "50162");
$string = "[ 20061109213316 Thu09-21:33-IBADWQ01:Oracle:bolog:major:ORA-01013: user requested cancel of current operation]";
	do_trap("151.191.98.138", "50162");
$string = "[ 20061110105329 Fri10-10:53-GONZD0:Oracle:IPING1043:major:Instance GONZD0 Fail to Connect]";
	do_trap("151.191.98.138", "50162");
$string = "[ 20061110105302 Fri10-10:53-LNOIDE6:Oracle:OIDREPLD1:major:OID replication health check failed. See the logfile /sbclocal/app/oracle/local/logs/oraoidrepld_LNOIDE6.log]";

	do_trap("151.191.98.138", "50162");
$string = "[ 20061110185146 Fri10-18:51-SSTSD2:Oracle:bolog:major:ORA-20500 dars audit trail content too old]";	

	do_trap("151.191.98.138", "50162");
	do_trap("151.191.98.138", "50162");
$string = "[ 20061110105246 Fri10-10:52-LDCDRD1:Oracle:bolog:major:ORA-1653: unable to extend table MDA.MDA_COLLECT_SESSION_LOGOFF by 64 in tablespace MDA_DATA]";
	do_trap("151.191.98.138", "50162");
$string = "[ 20061110105337 Fri10-10:53-ENCOREP2:Oracle:LISTENER_ENCOREP2DR1043:major:Instance ENCOREP2 listener LISTENER_ENCOREP2DR is not responding]";
	do_trap("151.191.98.138", "50162");
$string = "[ 20061109230009 Thu09-23:00-SKET01:Oracle:bolog:major:ORA-1654: unable to extend index SKEMAIN.ORDERLOGS_CREATED_IX by 1024 in tablespace SKE_LOGS_IND]";
	do_trap("151.191.98.138", "50162");
$string = "[ 20061110103207 Fri10-10:32-LNGRWU2:Oracle:dbs_oralistenerd:minor:Instance LNGRWU2 dbs_oralistenerd Fail to report exceeds 00.01.00]";
	do_trap("151.191.98.138", "50162");
$string = "[ 20061109223147 Thu09-22:31-BATDEV:Oracle:bolog:major:ORA-00942: table or view does not exist]";
	do_trap("151.191.98.138", "50162");
$string = "[ 20061110105316 Fri10-10:53-T24U3:Oracle:TOOLS:major:Database T24U3 TOOLS next 5 extents deficit [40960K 5056K] Details in: /sbclocal/app/oracle/local/logs/.dbs_oranextextd_T24U3.rpt]";
	do_trap("151.191.98.138", "50162");
$string = "[ 20061110105330 Fri10-10:53-GGLAXP2:Oracle:IPING1043:major:Instance GGLAXP2 Fail to Connect]";
	do_trap("151.191.98.138", "50162");
$string = "[ 20061110105308 Fri10-10:53-T24U7:Oracle:IPING1043:major:Instance T24U7 Fail to Connect]";
	do_trap("151.191.98.138", "50162");
$string = "[ 20061110104547 Fri10-10:45-ASHMART1:Oracle:bolog:major:ORA-20500 dars audit trail content too old]";
	do_trap("151.191.98.138", "50162");
$string = "[ 20061110105133 Fri10-10:51-LNRODU1:Oracle:OIDREPLD1:major:OID replication health check failed. See the logfile]";
	do_trap("151.191.98.138", "50162");
$string = "[ 20061110105200 Fri10-10:52-sldn2004dor:Oracle:dbs_oramonitor:major:ggsrepmon is not active and heartbeat exceeds 720Minutes]";
	do_trap("151.191.98.138", "50162");
$string = "[ 20061110105201 Fri10-10:52-T24D2:Oracle:dbs_oraconnectd:major:Instance T24D2 dbs_oraconnectd Fail to report exceeds 00.01.00]";
	do_trap("151.191.98.138", "50162");
$string = "[ 20061110105347 Fri10-10:53-NGPU4:Oracle:IPING1043:major:Instance NGPU4 Fail to Connect]";
	do_trap("151.191.98.138", "50162");
$string = "[ 20061110105339 Fri10-10:53-GGLDWS2:Oracle:LISTENER_GGLDWS210:minor:Instance GGLDWS2 Fail to start listener LISTENER_GGLDWS2]";
	do_trap("151.191.98.138", "50162");
$string = "[ 20061109214020 Thu09-21:40-HKBRLTU1:Oracle:bolog:major:ORA-1653: unable to extend table TRADE_CACHE_DBO.TRADESYNC_AUDIT by 1024 in tablespace TRADE_CACHE]";
	do_trap("151.191.98.138", "50162");
$string = "[ 20061110105354 Fri10-10:53-EQUX019D:Oracle:LISTENER_EQUX019D1043:major:Instance EQUX019D Fail to start listener LISTENER_EQUX019D]";
	do_trap("151.191.98.138", "50162");
$string = "[ 20061110105201 Fri10-10:52-sldn1479dor:Oracle:dbs_oramonitor:major:ggsrepmon is not active and heartbeat exceeds 720Minutes]";
	do_trap("151.191.98.138", "50162");
$string = "[ 20061110101727 Fri10-10:17-GSDATAD2:Oracle:SD_INDX:minor:Database GSDATAD2 Tablespace SD_INDX exceeds 94%]";
	do_trap("151.191.98.138", "50162");
$string = "[ 20061110105335 Fri10-10:53-MEMIRCD3:Oracle:LISTENER_MEMIRCD31043:major:Instance MEMIRCD3 Fail to start listener LISTENER_MEMIRCD3]";
	do_trap("151.191.98.138", "50162");
$string = "[ 20061110104607 Fri10-10:46-SKCU1:Oracle:MANAGEDSBY1:major:Managed standby db is not funtional.see logfile /sbclocal/app/oracle/local/logs/managed_standby_SKCU1.log]";
	do_trap("151.191.98.138", "50162");
$string = "[ 20061110105236 Fri10-10:52-:Oracle:dbs_oramonitor:minor:ggsrepmon is not active and heartbeat exceeds 720Minutes]";
	do_trap("151.191.98.138", "50162");
$string = "[ 20061110105401 Fri10-10:54-sldn1315dor:Oracle:dbs_oramonitor:major:ggsrepmon is not active and heartbeat exceeds 720Minutes]";
	do_trap("151.191.98.138", "50162");
$string = "[ 20061110105403 Fri10-10:54-GGLDWT1:Oracle:LISTENER_GGLDWT110:minor:Instance GGLDWT1 Fail to start listener LISTENER_GGLDWT1]";
	do_trap("151.191.98.138", "50162");
$string = "[ 20061110105413 Fri10-10:54-GGLMIG1:Oracle:IPING1043:major:Instance GGLMIG1 Fail to Connect]";
	do_trap("151.191.98.138", "50162");
$string = "[ 20061110105400 Fri10-10:54-SKETEBP1:Oracle:oramanagedsbyd:major:Instance SKETEBP1 oramanagedsbyd Fail to report exceeds 00.10.00]";
	do_trap("151.191.98.138", "50162");
$string = "[ 20061110105334 Fri10-10:53-RADARD11:Oracle:bolog:major:ORA-04031: unable to allocate 4160 bytes of shared memory (shared pool,unknown object,sga heap(1,0),kglsim heap)]";
	do_trap("151.191.98.138", "50162");
$string = "[ 20061110105241 Fri10-10:52-CRCX1053:Oracle:bolog:major:ORA-1653: unable to extend table CRCX1053.DMI_QUEUE_ITEM_S by 7 in tablespace CRCX1053]";
	do_trap("151.191.98.138", "50162");
$string = "[ 20061110105315 Fri10-10:53-HELIXD1:Oracle:HELIXD1nolsnrtab:major:Missing lsnrtab entries for HELIXD1]";
	do_trap("151.191.98.138", "50162");

exit 0;