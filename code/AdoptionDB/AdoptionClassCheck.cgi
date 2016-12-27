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


my $Verbose = 1;

sub PutReqData
{

	my $dbh;
	$dbh = DBI->connect( "dbi:Oracle:database=MMSTMP1;HOST=sstm8958por.stm.swissbank.com;PORT=1525;SID=MMSTMP1",
	                        "MMADOPT",
	                        "mmadopt123",
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

sub PutAdoptData
{
	my $dbh;
#	$dbh = DBI->connect( "dbi:Oracle:database=MMSTMP1;HOST=sstm8958por.stm.swissbank.com;PORT=1525;SID=MMSTMP1",
#	                        "MMADOPT",
#	                        "mmadopt123",
	$dbh = DBI->connect( "dbi:Oracle:database=MMLDNP1;HOST=sldn0150por.ldn.swissbank.com;PORT=1525;SID=MMLDNP1",
	                        "MMADOPT",
	                        "mmadopt123",
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


sub ClassNotOK
{
my $ThisClass = $_[0];	
		if ($Verbose){print "<p>ThisClass = $ThisClass";}
#	print  "<tr><td width=40> </td><td>ThisClass = $ThisClass:</td> <td>from ClassOK</td></tr>";
	$SQL = "select count(*) from managed_app Where Class = " . $ThisClass;
#	print  "<tr><td width=40> </td><td>SQL = $SQL:</td> <td>from ClassOK</td></tr>";
	if ($Verbose){print "<p>SQL = $SQL";}
	GetRequestData;
	if (defined($Data[0])){}else{$Data[0]=0;}
		if ($Verbose){print "<p>Data[0] = $Data[0]";}
	return $Data[0];
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
	$SUGGESTEDCLASS = $formdata{SUGGESTEDCLASS};
	print "<p>";
	print "<table align=center border=\"0\" cellSpacing=\"1\" cellPadding=\"1\" width=\"100%\" bgcolor=#006699 >";
	print "<tr><td align=center><FONT COLOR=\"WHITE\"><B>Monitoring Adoption Request Check Class</B></FONT></tr></td>";
	print "</table>";
	print "<p><p>";
	
	
	
	$SQL = "select * from new_adp_req where request_id = '" . $REQUEST_ID . "'" ;
	if ($Verbose){print "$SQL\n";}
	GetRequestData;
	

$Request_ID = $Data[0];
$Requestor = $Data[1];
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
if($APP_REF_SOURCE eq "1")
{
	$CMDB_App_Id = $APP_REF;
	$ISAC_App_ID = "0";
}
elsif ($APP_REF_SOURCE eq "1")
{
	$CMDB_App_Id = "0";
	$ISAC_App_ID = $APP_REF;
}
else
{
	$CMDB_App_Id = "0";
	$ISAC_App_ID = "0";
}


if ($REQUEST_STATUS eq "Completed")
{
	if ($Verbose){print "<p>REQUEST_STATUS eq Completed";}
	print "<P>";
	print "<P>";
	print "<Table>";
	print  "<tr><td width=40> </td><td>Request ID:</td> <td>$Request_ID</td></tr>";
	print  "<tr><td width=40> </td><td>REQUEST STATUS:</td> <td>$REQUEST_STATUS</td></tr>";
	print  "<tr><td width=40> </td><td>NETCOOL CLASS:</td> <td>$CLASS</td></tr>";
	print "</Table>";
	print "<FORM Method Post ACTION=\"/cgi-bin/adoption/AdoptionStatus.cgi\">";
#	print "<FORM Method Post ACTION=\"/cgi-bin/adoption/PrintPassedFields.cgi\">";
	print "<INPUT TYPE=\"hidden\" NAME=\"CLASS\" VALUE=\"$CLASS\">";
	print "<INPUT TYPE=submit VALUE=\"More Information\">";
	print "</FORM>";



}
else
{

	print "<P>";
	print "<P>";
	print "Creating Adoption Record<br>";
	if ($SUGGESTEDCLASS != 0)
	{
		if ($Verbose){print "<p>SUGGESTEDCLASS = $SUGGESTEDCLASS";}
		$ClassNotOkFlag = ClassNotOK($SUGGESTEDCLASS);
		if ($Verbose){print "<p>ClassNotOkFlag = $ClassNotOkFlag";}
		
		if($ClassNotOkFlag)
		{
#	Class is already being used so 
#			print "<FORM Method Post ACTION=\"/cgi-bin/adoption/AdoptionClassCheck.cgi\">";
			print "<FORM Method Post ACTION=\"/cgi-bin/adoption/PrintPassedFields.cgi\">";
			print  "Class $SUGGESTEDCLASS is NOT OK, it is being used by another application<BR>";
			print "Please enter NEW proposed class<br>";
			print " <INPUT TYPE=\"text\" NAME=\"SUGGESTEDCLASS\" >";
			print "<P>";
			print "	<INPUT TYPE=submit VALUE=\"Check Class is Valid\">";
			print "	<INPUT TYPE=reset VALUE=\"Reset\"> ";

		}
		else
		{
			print  "Class $SUGGESTEDCLASS is OK <BR>";
#			print "<FORM Method Post ACTION=\"/cgi-bin/adoption/AdoptionClassCheck.cgi\">";
			print "<FORM Method Post ACTION=\"/cgi-bin/adoption/PrintPassedFields.cgi\">";

############################################################################################
#
#	This is where the code to insert a record(s) into the db goes
			
			print  "Update Adoption Request Record <BR>";
			$SQL = "update NEW_ADP_REQ  set Class = '" . $SUGGESTEDCLASS . "', REQUEST_STATUS = 'Completed' where REQUEST_ID = " . $REQUEST_ID ;
			if ($Verbose){print "$SQL\n";}
			PutReqData;
			

			print  "Insert Managed Application Record <BR>";
			$SQL = "insert into Managed_App   ( Class, Application, APP_NAME, App_Criticality, RTB_Application_Manager, Requestor, TTicketNo, Source, CMDB_App_Id, ISAC_App_ID )values ('" . $SUGGESTEDCLASS . "', '" . $APP_NAME . "', '" . $APP_NAME . "', '" . $APP_CRITICALITY . "',  '" . $UBS_RTBCONTACTNAME . "', '" . $Requestor . "', '" . $REM_TICKET_NO . "', '" . $APP_REF_SOURCE . "', '" . $CMDB_App_Id . "', '" . $ISAC_App_Id . "')";
			if ($Verbose){print "$SQL\n";}
			PutReqData;
	

#
#
############################################################################################

		}
	}
}