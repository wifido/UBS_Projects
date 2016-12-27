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
	
	print "<p>";
	print "<table align=center border=\"0\" cellSpacing=\"1\" cellPadding=\"1\" width=\"100%\" bgcolor=#006699 >";
	print "<tr><td align=center><FONT COLOR=\"WHITE\"><B> Netcool New Application Monitoring Request</B></FONT></tr></td>";
	print "</table>";
	print "<p><p>";
	
	
	$REQUEST_ID= $formdata{REQUEST_ID};
	$REM_TICKET_NO = $formdata{REM_TICKET_NO};

	
	if ($Verbose){print"<p>REQUEST_ID = $REQUEST_ID ";}
	if ($Verbose){print"<p>REM_TICKET_NO = $REM_TICKET_NO ";}
	


	$SQL = "select count(*) from NEW_ADP_REQ where REQUEST_ID = " . $REQUEST_ID . " and REQUEST_STATUS = 'New Request'";
	GetAdoptData;
	if (defined($Data[0])){}else{$Data[0]=0;}
	if ($Verbose){print "<p>Does Record Exist = $Data[0]";}
	if ($Data[0])
	{
		$SQL = "update NEW_ADP_REQ  set REM_TICKET_NO = '" . $REM_TICKET_NO . "', REQUEST_STATUS = 'Ticket Raised' where REQUEST_ID = " . $REQUEST_ID ;
		if ($Verbose){print "$SQL\n";}
		PutReqData;

		print "<P>";
		print "Thank you for registering your ticket with an request";
	}
	else
	{
		print "<P>";
		print "Unable to Register the ticket number with the request $REQUEST_ID<BR>";
		$SQL = "select count(*) from NEW_ADP_REQ where REQUEST_ID = " . $REQUEST_ID;
		GetAdoptData;
		if (defined($Data[0])){}else{$Data[0]=0;}
		if ($Verbose){print "<p>Does Record Exist = $Data[0]";}
		if ($Data[0] == 0)
		{
			print "Error 1001 - Request not valid <BR>";
		}
		else
		{
			$SQL = "select REQUEST_STATUS from NEW_ADP_REQ where REQUEST_ID = " . $REQUEST_ID;
			GetAdoptData;
			if ($Verbose){print "<p>Does Record Exist = $Data[0]";}
			if (defined($Data[0])){}else{$Data[0]="";}
			{
				print "Error 1002 - Request Status not valid ($Data[0]) <BR>";
			}
		}
		print "Please refer this issue with ESM MONITORING SD Team";
		print "<Table>";
		print  "<tr><td width=40> </td><td>Email :</td> <td>sh-monitoring-support</td></tr>";
		print  "<tr><td width=40> </td><td>Chat :</td> <td>#Monitoring_Support</td></tr>";
		print  "<tr><td width=40> </td><td>Hotline :</td> <td>19494 4114</td></tr>";	
		print "</Table>";

	}


