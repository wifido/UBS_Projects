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
	$CLASS = $formdata{CLASS};
	$PAGE = $formdata{PAGE};
	print $table;
	print "<tr>$tdH Monitoring Adoption Request Status$tdeH</tr>";
	print "</table>";
	
	
	
	$SQL = "select * from managed_app where Class = '" . $CLASS . "'" ;
	if ($Verbose){print "$SQL\n";}
	GetRequestData;
	
$CLASS  = $Data[0];
$APPLICATION  = $Data[1];
$SAPNUMBER  = $Data[2];
$APP_CRITICALITY = $Data[3];
$ADOPTION_STATUS = $Data[4];
$ADOPTION_DATE  = $Data[5];
$COMPLETED_DATE = $Data[6];
$AMENDED_DATE = $Data[7];
$REMEDY_GROUP = $Data[8];
$MICROMUSE_ACTIVE_IN_LAST_WEEK  = $Data[9];
$MICROMUSE_ACTIVE_IN_LAST_MONTH  = $Data[10]; 
$RTB_APPLICATION_MANAGER  = $Data[11];
$APPLICATION_LIFECYCLE_STATUS  = $Data[12];
$LAST_ALERT_DATE  = $Data[13];
$ALERT_COUNT_WEEK = $Data[14];
$ALERT_COUNT_MONTH  = $Data[15];
$MICROMUSE_ACTIVE_MONTH1 = $Data[16]; 
$MICROMUSE_ACTIVE_MONTH2 = $Data[17]; 
$MICROMUSE_ACTIVE_MONTH3 = $Data[18]; 
$MICROMUSE_ACTIVE_MONTH4 = $Data[19]; 
$MICROMUSE_ACTIVE_MONTH5 = $Data[20]; 
$MICROMUSE_ACTIVE_MONTH6  = $Data[21]; 
$COMMENTS = $Data[22];
$OWNERGID = $Data[23];
if ( length($OWNERGID)== 0){$OWNERGID=0;}
$STREAM = $Data[24];
$AEN_FLAG = $Data[25];
$STREAMID = $Data[26];
$CMDB_APP_ID = $Data[27]; 
$OP_COM  = $Data[28];
$SUB_OP_COM = $Data[29];
$CMDB_CHECK = $Data[30];
$CMDB_UPDATE  = $Data[31]; 
$REQUESTOR  = $Data[32];
$TTICKETNO  = $Data[33];
$WEBTOP_URL = $Data[34];
$RTB_APP_MANAGER_GPIN = $Data[35];
$APP_NAME = $Data[36];
$SUPPORTGROUP = $Data[37];
$SUPPORT_PHONE = $Data[38];
$SUPPORT_EMAIL  = $Data[39];
$SUPPORT_CHAT = $Data[40];
$ISAC_APP_SW_ID = $Data[41];
$SOURCE = $Data[42];
$ISAC_APP_ID  = $Data[43];

if ($SOURCE == 1) {$SOURCE_TXT = "CMDB"}
elsif ($SOURCE == 2) {$SOURCE_TXT = "i-SAC"}
else  {$SOURCE_TXT = "User"}

if ($REQUEST_STATUS eq "Completed")
{
	print $table;
	print  "<tr>$td1<td>Request ID:</td> <td>$Request_ID</td></tr>";
	print  "<tr>$td1<td width=40> </td><td>REQUEST STATUS:</td> <td>$REQUEST_STATUS</td></tr>";
	print  "<tr>$td1<td width=40> </td><td>NETCOOL CLASS:</td> <td>$CLASS</td></tr>";
	print "</Table>";
	print "<FORM Method Post ACTION=\"/cgi-bin/adoption/AdoptionStatus.cgi\">";
	print "<INPUT TYPE=\"hidden\" NAME=\"CLASS\" VALUE=\"$CLASS\">";
	print "<INPUT TYPE=submit VALUE=\"More Information\">";
	print "</FORM>";



}
else
{

	print $table;
	print "<tr>$td1$tdS APPLICATION:$tdeS$td$APPLICATION$tde</tr>";
	print "</Table>";
	print $table;
	print "<tr>$td1$td$tde</tr>";
	print "</Table>";
	print $table;
	print  "<tr>$td1$tdS CLASS:$tdeS$td$CLASS$tde$tdS REQUESTOR:$tdeS$td$REQUESTOR$tde</tr>";
	print  "<tr>$td1$tdS APPLICATION LIFECYCLE STATUS:$tdeS$td$APPLICATION_LIFECYCLE_STATUS$tde$tdS ADOPTION_STATUS:$tdeS$td$ADOPTION_STATUS$tde</tr>";
	print  "<tr>$td1$tdS $tdeS$td$tde$tdS ADOPTION_DATE:$tdeS$td$ADOPTION_DATE$tde</tr>";
	print  "<tr>$td1$tdS RTB APPLICATION MANAGER:$tdeS$td$RTB_APPLICATION_MANAGER$tde$tdS COMPLETED_DATE:$tdeS$td$COMPLETED_DATE$tde</tr>";
	print  "<tr>$td1$tdS REMEDY_GROUP :$tdeS$td$REMEDY_GROUP $tde$td$tde$td $tde</tr>";
#	print  "<tr>$td1$tdS WEBTOP_URL :$tdeS$td$WEBTOP_URL $tde$td$tde$td $tde</tr>";
	print  "<tr>$td1$tdS APP_CRITICALITY $tdeS$td$APP_CRITICALITY $tde$tdS OWNERGID :$tdeS$td$OWNERGID$tde</tr>";
	print  "<tr>$td1$tdS $tdeS$td$tde$tdS STREAM :$tdeS$td $STREAM$tde</tr>";
	print  "<tr>$td1$tdS SOURCE :$tdeS$td$SOURCE_TXT $tde$tdS AEN_FLAG :$tdeS$td $AEN_FLAG$tde</tr>";
	print "</Table>";
        print $table;
	print  "<tr>$td1$tdS CMDB_APP_ID :$tdeS$td$CMDB_APP_ID$tde</tr>";
	print  "<tr>$td1$tdS ISAC_APP_ID :$tdeS$td$ISAC_APP_ID$tde</tr>";
	print  "<tr>$td1$tdS ISAC_APP_SW_ID :$tdeS$td$ISAC_APP_SW_ID$tde</tr>";
	print  "<tr>$td1$tdS OP_COM :$tdeS$td$OP_COM$tde</tr>";
	print  "<tr>$td1$tdS SUB_OP_COM :$tdeS$td$SUB_OP_COM$tde</tr>";
	print  "<tr>$td1$tdS $tdeS$td$tde</tr>";
	print "</Table>";
}

#############################################################################
#
#	Here we get the support team details
#
#############################################################################
if ($PAGE = "REMEDY")
{
		print $table;
		print  "<tr>$td1$tdSRemedy Details$tdeS$td$tde";
		print "</Table>";

}
else
{
	$SQL = "select count(*) from support_team Where OWNERGID = " . $OWNERGID;
	GetAdoptData;
	if ($Verbose){print "<p>Does Class Exist = $Data[0]";}
	if (defined($Data[0])){}else{$Data[0]=0;}
	if ($Data[0])
	{


		$SQL = "select * from support_team where OWNERGID = " . $OWNERGID  ;
		if ($Verbose){print "$SQL\n";}
		GetRequestData;

		$OWNERGID  = $Data[0];
		$TEAM_NAME  = $Data[1];
		$TEAM_URL  = $Data[2];
		$TEAM_MANAGER  = $Data[3];
		$STREAM  = $Data[4];
		$SUBSTREAM   = $Data[5];
		$STREAM_CONTACT  = $Data[6];
		$TEAM_EMAIL  = $Data[7];
		$PROD_URL  = $Data[8];
		$CONFIRMED_DATE  = $Data[9];
		$COMMENTS  = $Data[10];
		$EMAIL  = $Data[11];



		print $table;
		print  "<tr>$td1$tdS Support Details$tdeS$td$tde";
		print  "<tr>$td1$tdS TEAM_NAME:$tdeS$td$TEAM_NAME$tde</tr>";
		print  "<tr>$td1$tdS TEAM_MANAGER:$tdeS$td$TEAM_MANAGER$tde</tr>";
		print  "<tr>$td1$tdS TEAM_EMAIL:$tdeS$td$TEAM_EMAIL$tde</tr>";
		print  "<tr>$td1$tdS Prod URL:$tdeS$td<A HREF=\"$PROD_URL\">$PROD_URL</A>$tde</tr>";
		print  "<tr>$td1$tdS Dev URL:$tdeS$td<A HREF=\"$TEAM_URL\">$TEAM_URL</A>$tde</tr>";
		print  "<tr>$td1$tdS Netcool Group:$tdeS$td$OWNERGID$tde</tr>";
		print  "<tr>$td1$tdS SUPPORTGROUP:$tdeS$td$SUPPORTGROUP$tde</tr>";
		print  "<tr>$td1$tdS SUPPORT_PHONE:$tdeS$td$SUPPORT_PHONE$tde</tr>";
		print  "<tr>$td1$tdS SUPPORT_EMAIL:$tdeS$td$SUPPORT_EMAIL$tde</tr>";
		print  "<tr>$td1$tdS SUPPORT_CHAT:$tdeS$td$SUPPORT_CHAT$tde</tr>";
		print "</Table>";
	}
	else
	{
		print $table;
		print "<TR>$td1$tdSA Support Team Information not currently available$tdeS";
		print "</Table>";
	}
}









#############################################################################
#
#	Our Support Contact details
#
#############################################################################

	print $support;
