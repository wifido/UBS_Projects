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

require "style.plinc" or die("Can't require style.plinc");

my $CLASS_ID = "0";
my $Verbose = 0;
my @Data;
my $SQL;
my $ApplicationName;

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
	print "<LINK REL=\"stylesheet\" HREF=\"/css/mm.css\" TYPE=\"text/css\">";
	# Print Header
	
	print $table;
	print "<tr>$tdH Netcool New Application Monitoring Request$tdeH</tr>";
	print "</table>";
	
	
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
	


	#	This is for apps registered in cmdb

		if ($APP_REF_SOURCE == 1)
		{
			$SQL = "select count(*) from managed_app Where CMDB_APP_ID = " . $formdata{APP_REF};
			GetAdoptData;
			if ($Verbose){print "<p>Does Class Exist = $Data[0]";}
			if (defined($Data[0])){}else{$Data[0]=0;}
			if ($Data[0])
			{
				$SQL = "select class from managed_app Where CMDB_APP_ID = " . $formdata{APP_REF};
				GetAdoptData;
				$CLASS = $Data[0];
				print"<p>This Application is already registered for Monitoring as Class $Data[0]\n";
				print "<FORM Method Post ACTION=\"/cgi-bin/adoption/AdoptionStatus.cgi\">";
				print "<INPUT TYPE=\"hidden\" NAME=\"CLASS\" VALUE=\"$CLASS\">";
				print "<INPUT TYPE=submit VALUE=\"More Information\">";
				print "</FORM>";

			}
			else
			{

				$SQL = "SELECT count(*) FROM aradmin.ubs_esm_cmdb_appsys where APPLICATION_ID = " . $formdata{APP_REF};
				GetCmdbData;
				if ($Verbose){print "<p> Count from cmdb = $Data[0]";}
				if($Data[0])
				{
					$SQL = "SELECT APP_NAME FROM aradmin.ubs_esm_cmdb_appsys where APPLICATION_ID = " . $formdata{APP_REF};
					GetCmdbData;
					$ApplicationName = $Data[0];
					$SQL = "SELECT ubs_rtbcontactname FROM aradmin.ubs_esm_cmdb_appsys where APPLICATION_ID = " . $formdata{APP_REF};
					GetCmdbData;
					$UBS_RTBCONTACTNAME = $Data[0];
					$SQL = "SELECT UBS_BUSINESSCRITICALITY FROM aradmin.ubs_esm_cmdb_appsys where APPLICATION_ID = " . $formdata{APP_REF};
					GetCmdbData;
					$APP_CRITICALITY = $Data[0];
					print $table;
					print "<TR>";
					print "$td1$tdSA This information has been drawn from CMDB Please check and confirm$tdeS";
					print "</TABLE>";
					print $table;
					print "<TR>";
					print "$td1$tdS Application Name :$tdeS";
					print "$td$ApplicationName$tde";
					print "<TR>";
					print "$td1$tdS UBS Business Citicality :$tdeS";
					print "$td$APP_CRITICALITY$tde";
					print "<TR>";
					print "$td1$tdS CMDB Application Ref :$tdeS";
					print "$td$APP_REF$tde";
					print "<TR>";
					print "$td1$tdS RTB Application Manager :$tdeS";
					print "$td$UBS_RTBCONTACTNAME$tde";
					print "<TR>";
					print "$td1$tdS Requestor :$tdeS";
					print "$td$REQUESTOR$tde";
					print "<TR>";
					print "$td1$tdS Requstor Email :$tde";
					print "$td$REQUESTOR_EMAIL$tde";
					print "<TR>";
					print "</TABLE>";


					print "<FORM name=confirm action=http://monitoring.swissbank.com/cgi-bin/adoption/AdoptReqInsert.cgi method=post>";
					print "<INPUT TYPE=\"hidden\" NAME=\"REQUESTOR\" VALUE=\"$REQUESTOR\">";
					print "<INPUT TYPE=\"hidden\" NAME=\"REQUESTOR_EMAIL\" VALUE=\"$REQUESTOR_EMAIL\">";
					print "<INPUT TYPE=\"hidden\" NAME=\"APP_REF\" VALUE=\"$APP_REF\">";
					print "<INPUT TYPE=\"hidden\" NAME=\"APP_REF_SOURCE\" VALUE=\"$APP_REF_SOURCE\">";
					print "<INPUT TYPE=\"hidden\" NAME=\"APP_NAME\" VALUE=\"$ApplicationName\">";
					print "<INPUT TYPE=\"hidden\" NAME=\"UBS_RTBCONTACTNAME\" VALUE=\"$UBS_RTBCONTACTNAME\">";
					print "<INPUT TYPE=\"hidden\" NAME=\"APP_CRITICALITY\" VALUE=\"$APP_CRITICALITY\">";
					print "<P align=center><INPUT type=submit value=\"Confirm\">  </P></FORM>";
				}
				else
				{
					print "<p>This application is not registered in CMDB";
					print "<FORM name=bugout action=http://monitoring.swissbank.com/publicauth/dev/adoption_request.html method=post>";
					print "<P align=center><INPUT type=submit value=\"Continue\">  </P></FORM>";
				}
			}
		}
		elsif ($APP_REF_SOURCE == 2)
		{
			$ISAC_REF = "AS" . $formdata{APP_REF};
			if ($Verbose){print "<p>ISAC_REF = $ISAC_REF";}

#			$SQL = "select count(*) from managed_app Where ISAC_APP_ID = " . $formdata{APP_REF};
			$SQL = "select count(*) from managed_app Where ISAC_APP_ID = '" . $ISAC_REF . "'";
			if ($Verbose){print "<p>SQL = $SQL";}
			GetAdoptData;
			if ($Verbose){print "<p>Does Class Exist = $Data[0]";}
			if (defined($Data[0])){}else{$Data[0]=0;}
			if ($Data[0])
			{
				$SQL = "select class from managed_app Where ISAC_APP_ID = '" . $ISAC_REF . "'";
				GetAdoptData;
				$CLASS = $Data[0];
				print"<p>This Application is already registered for Monitoring as Class $Data[0]\n";
				print "<FORM Method Post ACTION=\"/cgi-bin/adoption/AdoptionStatus.cgi\">";
				print "<INPUT TYPE=\"hidden\" NAME=\"CLASS\" VALUE=\"$CLASS\">";
				print "<INPUT TYPE=submit VALUE=\"More Information\">";
				print "</FORM>";

			}
			else
			{
				print $table;
				print "<TR>";
				print "$td1$tdSA Please confirm the following$tdeS";
				print "</TR>";
				print "</TABLE>";
				print $table;
				print "<TR>";
				print "$td1$tdS iSAC Application Ref :$tdeS";
				print "$td$APP_REF$tde";
				print "</TR>";
				print "<TR>";
				print "$td1$tdS Requestor :$tdeS";
				print "$td$REQUESTOR$tde";
				print "</TR>";
				print "<TR>";
				print "$td1$tdS Requstor Email :$tdeS";
				print "$td$REQUESTOR_EMAIL$tde";
				print "</TR>";
				print "</TABLE>";			
				print "<FORM name=confirm action=http://monitoring.swissbank.com/cgi-bin/adoption/CollectAdoptData.cgi method=post>";
				print "<INPUT TYPE=\"hidden\" NAME=\"REQUESTOR\" VALUE=\"$REQUESTOR\">";
				print "<INPUT TYPE=\"hidden\" NAME=\"REQUESTOR_EMAIL\" VALUE=\"$REQUESTOR_EMAIL\">";
				print "<INPUT TYPE=\"hidden\" NAME=\"APP_REF\" VALUE=\"$APP_REF\">";
				print "<INPUT TYPE=\"hidden\" NAME=\"APP_REF_SOURCE\" VALUE=\"$APP_REF_SOURCE\">";

				print "<P align=center><INPUT type=submit value=\"Confirm\">  </P></FORM>";
			}

		}
		else
		{
			print $table;
                        print "<TR>";
                        print "$td1$tdSA Please confirm the following$tdeS";
                        print "</TR>";
                        print "</TABLE>";
                        print $table;
			print "<TR>";
			print "$td1$tdS Application Ref :$tdeS";
			print "$td$APP_REF$tde";
			print "</TR>";
			print "<TR>";
			print "$td1$tdS Requestor :$tdeS";
			print "$td$REQUESTOR$tde";
			print "</TR>";
			print "<TR>";
			print "$td1$tdS Requstor Email :$tdeS";
			print "$td$REQUESTOR_EMAIL$tde";
			print "</TR>";
			print "</TABLE>";			


			
			print "<FORM name=confirm action=http://monitoring.swissbank.com/cgi-bin/adoption/CollectAdoptData.cgi method=post>";
			print "<INPUT TYPE=\"hidden\" NAME=\"REQUESTOR\" VALUE=\"$REQUESTOR\">";
			print "<INPUT TYPE=\"hidden\" NAME=\"REQUESTOR_EMAIL\" VALUE=\"$REQUESTOR_EMAIL\">";
			print "<INPUT TYPE=\"hidden\" NAME=\"APP_REF\" VALUE=\"0\">";
			print "<INPUT TYPE=\"hidden\" NAME=\"APP_REF_SOURCE\" VALUE=\"$APP_REF_SOURCE\">";
			print "<INPUT TYPE=\"hidden\" NAME=\"APP_NAME\" VALUE=\"$APP_REF\">";
			print "<P align=center><INPUT type=submit value=\"Confirm\">  </P></FORM>";
		}
#	}
#	else
#	{
#		print "Please enter Application Reference";
#		print "<FORM name=bugout action=http://monitoring.swissbank.com/cgi-bin/adoption_request.html method=post>";
#		print "<P align=center><INPUT type=submit value=\"Continue\">  </P></FORM>";
#	}
