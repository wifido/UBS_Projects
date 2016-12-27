#!/sbcimp/run/pd/perl/5.8.7/bin/perl -w

##############################################################################################
#
# This Script inserts into a record in mmadopt.NEW_ADP_REQ table the associated 
# remendy ticket number
#
#	Original	Chris Janes	20081231
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

my $Verbose = 0;

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


sub GetRequestData
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
			$tmpData = $nodeOracle[0] . "," . $nodeOracle[1] . "," . $nodeOracle[2] . "," . $nodeOracle[3] . ",";
			@Data = @nodeOracle;
		}
	}	
	
	$sthOracle->finish;
	$dbh->disconnect();
	
}
#####################################################################################
#
#
#	This is where the main body of code starts
#
#
#####################################################################################


if ($ENV{'REQUEST_METHOD'} eq 'GET') 
{
	@pairs = split(/&/, $ENV{'QUERY_STRING'});
} 
elsif ($ENV{'REQUEST_METHOD'} eq 'POST') 
{
	read (STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
	@pairs = split(/&/, $buffer);

	if ($ENV{'QUERY_STRING'}) 
	{
		@getpairs =split(/&/, $ENV{'QUERY_STRING'});
		push(@pairs,@getpairs);
	}
} 
else 
{
	print "Content-type: text/html\n\n";
	print "<P>Use Post or Get";
}

foreach $pair (@pairs) 
{
	($key, $value) = split (/=/, $pair);
	$key =~ tr/+/ /;
	$key =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
	$value =~ tr/+/ /;
	$value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
	$value =~s/<--(.|\n)*-->//g;

	if ($formdata{$key}) 
	{
		$formdata{$key} .= ", $value";
	} 
	else 
	{
		$formdata{$key} = $value;
	}
}
	
	print "Content-type: text/html\n\n";
	print "<LINK REL=\"stylesheet\" HREF=\"/css/mm.css\" TYPE=\"text/css\">";
	# Print Header
	
#	foreach $key (sort keys(%formdata)) 
#	{
#		print "<P>The field named <B>$key</B> contained <B>$formdata{$key}</B>";
#	}
	$REQUEST_ID = $formdata{REQUEST_ID};
	print $table;
	print "<TR>$tdH Monitoring Adoption Request Status $tdeH </TR>";
	print "</table>";
	
	
	
	$SQL = "select * from new_adp_req where request_id = '" . $REQUEST_ID . "'" ;
	if ($Verbose){print "$SQL\n";}
	GetRequestData;
	

$Request_ID = $Data[0];
$REQUESTOR = $Data[1];
$REQUESTOR_EMAIL = $Data[2];
$APP_REF = $Data[3];
$APP_REF_SOURCE = $Data[4];
$REQUEST_DATE = $Data[5];
$REQUEST_STATUS = $Data[6];
$REM_TICKET_NO = $Data[7];
$APP_NAME = $Data[8];
$UBS_RTBCONTACTNAME = $Data[9];
$APP_CRITICALITY = $Data[10];
$CLASS = $Data[11];
if ($REQUEST_STATUS eq "Completed")
{
	print $table;
	print  "<tr>$td1$tdS Request ID:$tdeS$td$Request_ID$tde</tr>";
	print  "<tr>$td1$tdS REQUEST STATUS:$tdeS$td$REQUEST_STATUS$tde</tr>";
	print  "<tr>$td1$tdS NETCOOL CLASS:$tdeS$td$CLASS$tde</tr>";
	print "</Table>";
	print "<FORM Method Post ACTION=\"/cgi-bin/adoption/AdoptionStatus.cgi\">";
	print "<INPUT TYPE=\"hidden\" NAME=\"CLASS\" VALUE=\"$CLASS\">";
	print "<p align=\"center\"><INPUT TYPE=submit VALUE=\"More Information\"></p>";
	print "</FORM>";



}
else
{

	print $table;
	print  "<tr>$td1$tdS Request_ID:$tdeS$td$Request_ID$tde</tr>";
	print  "<tr>$td1$tdS REQUEST_DATE:$tdeS$td$REQUEST_DATE$tde</tr>";
	print  "<tr>$td1$tdS REQUEST_STATUS:$tdeS$td$REQUEST_STATUS$tde</tr>";
	print  "<tr>$td1$tdS REM_TICKET_NO:$tdeS$td$REM_TICKET_NO$tde</tr>";
	print  "<tr>$td1$tdS Requestor:$tdeS$td$REQUESTOR$tde</tr>";
	print  "<tr>$td1$tdS Application Name:$tdeS$td$APP_NAME$tde</tr>";
	if($APP_REF_SOURCE == 1)
	{
		print  "<tr>$td1$tdS Application Registered in :$tdeS$td CMDB$tde</tr>";
		print  "<tr>$td1$tdS CMDB reference :$tdeS$td$APP_REF$tde</tr>";
	}
	elsif($APP_REF_SOURCE == 1)
	{
		print  "<tr>$td1$tdS Application Registered in :$tdeS$td i-SAC$tde</tr>";
		print  "<tr>$td1$tdS i-SAC reference :$tdeS$td$APP_REF$tde</tr>";
	}
	print  "<tr>$td1$tdS Business Criticality :$tdeS$td$APP_CRITICALITY$tde</tr>";
	print  "<tr>$td1$tdS RTB Application Manager:$tdeS$td$UBS_RTBCONTACTNAME$tde</tr>";
	print "</Table>";
	print $table;
	print "<tr>$td1 $tdSA Should you have any questions about this please contact ESM Netcool Production Support $tdeS</tr>";
	print "</Table>";
	print $table;
	print  "<tr>$td1$tdS Email :$tdeS$td sh-monitoring-support$tde</tr>";
	print  "<tr>$td1$tdS Chat :$tdeS$td #Monitoring_Support$tde</tr>";
	print  "<tr>$td1$tdS Hotline :$tdeS$td 19494 4114$tde</tr>";	
	print "</Table>";
}
