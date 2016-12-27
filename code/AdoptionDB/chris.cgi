#!/sbcimp/run/pd/perl/5.8.7/bin/perl -w

##############################################################################################
#
# This Script extract data from cmdb
#
#	Original	Chris Janes	20080925
#
#
##############################################################################################


   
   
   BEGIN {


      $ENV{ ORACLE_HOME } = "/sbcimp/run/tp/oracle/client/v9.2.0.4.0-32bit";
      $ENV{ TNS_ADMIN   } = "/sbcimp/run/pkgs/oracle/config";
      $ENV{LANG} = "C";
      $ENV{OMNIHOME} = qw(/sbclocal/netcool/omnibus);
      $ENV{SYBASE} = qw(/sbcimp/run/tp/sybase/OpenClientServer/v12.5);
      $ENV{SYBASE_OCS} = q(OCS-12_5);
      $ENV{PERL5LIB} = "";

   }


##############################################################################################
#
#	Get the Modules we are using
#
##############################################################################################

use lib "/sbcimp/run/pd/cpan/5.8.5-2004.09/lib";


use DBI;
use DBD::Sybase;
use DateTime;
use Switch;
#use strict;
use Scalar::Util qw(looks_like_number);
use File::Path;
use CGI::Carp;


my $CLASS_ID = "0";
my $Verbose = 0;
my @Data;
my $SQL;

sub PutReqData
{

	my $dbh;
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
	
	my $sthOracle = $dbh->prepare("$SQL") || die $dbh->errstr;
	
	$sthOracle->execute() || die $sthOracle->errstr;
	$sthOracle->finish;
	$dbh->disconnect();
	
}


sub GetAdoptData
{

	my $dbh;
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
	
	my $sthOracle = $dbh->prepare("$SQL") || die $dbh->errstr;
	
	$sthOracle->execute() || die $sthOracle->errstr;

	while (my (@nodeOracle) = $sthOracle->fetchrow_array) 
	{
		if(exists($nodeOracle[0]))
		{
			@Data = @nodeOracle;
		}
	}	
	
	$sthOracle->finish;
	$dbh->disconnect();
	
}


sub GetCmdbData
{

	my $dbh;
	my $SAP_ID;
	my $CMDB_ID;
	
	
##	$dbh = DBI->connect( "dbi:Oracle:database=DCMDBV2;HOST=sldn1339dor.ldn.swissbank.com;PORT=1524;SID=DCMDBV2",
	$dbh = DBI->connect( "dbi:Oracle:database=CMDBP2;HOST=sldn2485por.ldn.swissbank.com;PORT=1530;SID=CMDBP2",
                        "NETCOOL_CMDB",
	                        "Orange18",
	                        {
	                            RaiseError => 1,
	                            AutoCommit => 0
	                        }
	                       ) || die "Database connection not made: $DBI::errstr";
	
	my $sthOracle = $dbh->prepare("$SQL") || die $dbh->errstr;
	
	$sthOracle->execute() || die $sthOracle->errstr;
	while (my (@nodeOracle) = $sthOracle->fetchrow_array) 
	{
		if(exists($nodeOracle[0]))
		{
			@Data = @nodeOracle;
		}
	}
	$sthOracle->finish;
	$dbh->disconnect();
	
}

################################################
#
################################################
if ($ENV{'REQUEST_METHOD'} eq 'GET') {
		@pairs = split(/&/, $ENV{'QUERY_STRING'});
	} elsif ($ENV{'REQUEST_METHOD'} eq 'POST') {
		read (STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
		@pairs = split(/&/, $buffer);
		
		if ($ENV{'QUERY_STRING'}) {
			@getpairs =split(/&/, $ENV{'QUERY_STRING'});
			push(@pairs,@getpairs);
			}
	} else {
		print "Content-type: text/html\n\n";
		print "<P>Use Post or Get";
	}

	foreach $pair (@pairs) {
		($key, $value) = split (/=/, $pair);
		$key =~ tr/+/ /;
		$key =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
		$value =~ tr/+/ /;
		$value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
	
		$value =~s/<--(.|\n)*-->//g;
	
		if ($formdata{$key}) {
			$formdata{$key} .= ", $value";
		} else {
			$formdata{$key} = $value;
		}
	}
	
	print "Content-type: text/html\n\n";
	# Print Header
	
	print "<p>";
	print "<table align=center border=\"0\" cellSpacing=\"1\" cellPadding=\"1\" width=\"100%\" bgcolor=#006699 >";
	print "<tr><td align=center><FONT COLOR=\"WHITE\"><B> Netcool New Application Monitoring Request</B></FONT></tr></td>";
	print "</table>";
	print "<p><p>";
	
	
	if ($Verbose){print "<p>This is a new test script that shows Fields passed to the script\n";}

#	foreach $key (sort keys(%formdata)) 
#	{
#		print "<P>The field named <B>$key</B> contained <B>$formdata{$key}</B>";
#	}
	$APP_REF_SOURCE = $formdata{APP_REF_SOURCE};
	$APP_REF = $formdata{APP_REF};
	$REQUESTOR = $formdata{REQUESTOR};
	$REQUESTOR_EMAIL = $formdata{REQUESTOR_EMAIL};
	
	if ($Verbose){print"<p>APP_REF_SOURCE = $APP_REF_SOURCE ";}
	if ($Verbose){print"<p>APP_REF = $APP_REF ";}
	if ($Verbose){print"<p>REQUESTOR = $REQUESTOR ";}
	if ($Verbose){print"<p>REQUESTOR_EMAIL = $REQUESTOR_EMAIL ";}
	
	if (length($APP_REF) > 0)
	{	
		$SQL = "select count(*) from managed_app Where CMDB_APP_ID = " . $formdata{APP_REF};
		GetAdoptData;




		if ($Verbose){print "<p>Does Class Exist = $Data[0]";}
		if (defined($Data[0])){}else{$Data[0]=0;}
		if ($Data[0])
		{
			$SQL = "select class from managed_app Where CMDB_APP_ID = " . $formdata{APP_REF};
			GetAdoptData;
			print"<p>This Application is already registered for Monitoring as Class $Data[0]\n";
		}


	#	This is for apps registered in cmdb

		elsif ($APP_REF_SOURCE == 1)
		{
			$SQL = "SELECT count(*) FROM aradmin.ubs_esm_cmdb_appsys where APPLICATION_ID = " . $formdata{APP_REF};
			GetCmdbData;
			if ($Verbose){print "<p> Count from cmdb = $Data[0]";}
			if($Data[0])
			{
				$SQL = "SELECT APP_NAME FROM aradmin.ubs_esm_cmdb_appsys where APPLICATION_ID = " . $formdata{APP_REF};
				GetCmdbData;
				print "<TABLE width=\"800\" bgColor=#99ccff border=0>";
				print "<TR>";
				print "<TD align=center  <STRONG>A request has been passed to ESM Service delivery to register the following application</STRONG></TD>";
				print "<TR>";
				print "<TR>";
				print "<TD align=left width=300 bgColor=#ddddff><STRONG>Application Name :</STRONG></TD>";
				print "<TD align=left bgColor=#ffffff border=3>$Data[0] </TD>";
				print "<TR>";
				print "<TR>";
				print "<TD align=left width=300 bgColor=#ddddff><STRONG>CMDB Application Ref :</STRONG></TD>";
				print "<TD align=left bgColor=#ffffff>$APP_REF </TD>";
				print "<TR>";
				print "<TR>";
				print "<TD align=left width=300 bgColor=#ddddff><STRONG>Requestor :</STRONG></TD>";
				print "<TD align=left bgColor=#ffffff>$REQUESTOR </TD>";
				print "<TR>";
				print "<TR>";
				print "<TD align=left width=300 bgColor=#ddddff><STRONG>Requstor Email :</STRONG></TD>";
				print "<TD align=left bgColor=#ffffff>$REQUESTOR_EMAIL </TD>";
				print "<TR>";
				print "</TABLE>";

				$SQL = "insert into NEW_ADP_REQ   ( REQUESTOR, REQUESTOR_EMAIL, APP_REF, APP_REF_SOURCE, REQUEST_DATE)values ('" . $REQUESTOR . "', '" . $REQUESTOR_EMAIL . "', '" . $APP_REF . "', '" . $APP_REF_SOURCE . "', sysdate)";
				if ($Verbose){print "$SQL\n";}
				PutReqData;
				print "<FORM name=bugout action=http://monitoring.swissbank.com/publicauth/dev/main.html method=post>";
				print "<P align=center><INPUT type=submit value=\"Continue\">  </P></FORM>";
			}
			else
			{
				print "<p>This application is not registered in CMDB";
				print "<FORM name=bugout action=http://monitoring.swissbank.com/publicauth/dev/adoption_request.html method=post>";
				print "<P align=center><INPUT type=submit value=\"Continue\">  </P></FORM>";
			}
		}
		elsif ($APP_REF_SOURCE == 2)
		{
			print "<TABLE width=\"800\" bgColor=#99ccff border=0>";
			print "<TR>";
			print "<TD align=center  <STRONG>A request has been passed to ESM Service delivery to register the following application</STRONG></TD>";
			print "<TR>";
			print "<TR>";
			print "<TD align=left width=300 bgColor=#ddddff><STRONG>iSAC Application Ref :</STRONG></TD>";
			print "<TD align=left bgColor=#ffffff>$APP_REF </TD>";
			print "<TR>";
			print "<TR>";
			print "<TD align=left width=300 bgColor=#ddddff><STRONG>Requestor :</STRONG></TD>";
			print "<TD align=left bgColor=#ffffff>$REQUESTOR </TD>";
			print "<TR>";
			print "<TR>";
			print "<TD align=left width=300 bgColor=#ddddff><STRONG>Requstor Email :</STRONG></TD>";
			print "<TD align=left bgColor=#ffffff>$REQUESTOR_EMAIL </TD>";
			print "<TR>";
			print "</TABLE>";			

			$SQL = "insert into NEW_ADP_REQ   ( REQUESTOR, REQUESTOR_EMAIL, APP_REF, APP_REF_SOURCE, REQUEST_DATE)values ('" . $REQUESTOR . "', '" . $REQUESTOR_EMAIL . "', '" . $APP_REF . "', '" . $APP_REF_SOURCE . "', sysdate)";

			if ($Verbose){print "$SQL\n";}
			PutReqData;
			print "<FORM name=bugout action=http://monitoring.swissbank.com/publicauth/dev/main.html method=post>";
			print "<P align=center><INPUT type=submit value=\"Continue\">  </P></FORM>";
		}
		else
		{
			print "<TABLE width=\"800\" bgColor=#99ccff border=0>";
			print "<TR>";
			print "<TD align=center  <STRONG>A request has been passed to ESM Service delivery to register the following application</STRONG></TD>";
			print "<TR>";
			print "<TR>";
			print "<TD align=left width=300 bgColor=#ddddff><STRONG>Application Ref :</STRONG></TD>";
			print "<TD align=left bgColor=#ffffff>$APP_REF </TD>";
			print "<TR>";
			print "<TR>";
			print "<TD align=left width=300 bgColor=#ddddff><STRONG>Requestor :</STRONG></TD>";
			print "<TD align=left bgColor=#ffffff>$REQUESTOR </TD>";
			print "<TR>";
			print "<TR>";
			print "<TD align=left width=300 bgColor=#ddddff><STRONG>Requstor Email :</STRONG></TD>";
			print "<TD align=left bgColor=#ffffff>$REQUESTOR_EMAIL </TD>";
			print "<TR>";
			print "</TABLE>";			


			$SQL = "insert into NEW_ADP_REQ   ( REQUESTOR, REQUESTOR_EMAIL, APP_REF, APP_REF_SOURCE, REQUEST_DATE)values ('" . $REQUESTOR . "', '" . $REQUESTOR_EMAIL . "', '" . $APP_REF . "', '0', sysdate)";

			if ($Verbose){print "$SQL\n";}
			PutReqData;
			print "<FORM name=bugout action=http://monitoring.swissbank.com/publicauth/dev/main.html method=post>";
			print "<P align=center><INPUT type=submit value=\"Continue\">  </P></FORM>";
		}
	}
	else
	{
		print "Please enter Application Reference";
		print "<FORM name=bugout action=http://monitoring.swissbank.com/publicauth/dev/adoption_request.html method=post>";
		print "<P align=center><INPUT type=submit value=\"Continue\">  </P></FORM>";
	}