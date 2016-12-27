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
	
	
	$APP_REF_SOURCE = $formdata{APP_REF_SOURCE};
	$APP_REF = $formdata{APP_REF};
	$REQUESTOR = $formdata{REQUESTOR};
	$REQUESTOR_EMAIL = $formdata{REQUESTOR_EMAIL};
	
	if ($Verbose){print"<p>APP_REF_SOURCE = $APP_REF_SOURCE ";}
	if ($Verbose){print"<p>APP_REF = $APP_REF ";}
	if ($Verbose){print"<p>REQUESTOR = $REQUESTOR ";}
	if ($Verbose){print"<p>REQUESTOR_EMAIL = $REQUESTOR_EMAIL ";}		
	
	#$SQL = "update NEW_ADP_REQ  set REM_TICKET_NO = '" . $REM_TICKET_NO . "', REQUEST_STATUS = 'Ticket Raised' where REQUEST_ID = " . $REQUEST_ID ;
	#if ($Verbose){print "$SQL\n";}
#	PutReqData;
		print "<FORM Method Post ACTION=\"/cgi-bin/adoption/AdoptReqInsert.cgi\">";

	
	print "<TABLE width=\"800\" bgColor=#99ccff border=0>";
		print "<TR>";
		print "<TD align=center width=300> Please supply the following Additional Information</TD>";
		print "<TR>";
		print "<TR bold>";
		print "<TD align=right bgColor=#ddddff ><STRONG>Application Name :</STRONG></TD>";
		print "<TD align=left ><INPUT TYPE=\"text\" NAME=\"APP_NAME\"> </TD>";
		print "<TR>";
		print "<TR>";
		print "<TD align=right bgColor=#ddddff><STRONG>RTB Application Manager :</STRONG></TD>";
		print "<TD align=left bgColor=#ffffff><INPUT TYPE=\"text\" NAME=\"UBS_RTBCONTACTNAME\"> </TD>";
		print "<TR>";

		print "<TR>";
		print "<TD align=right  bgColor=#ddddff><STRONG>Application Criticality :</STRONG></TD>";
		print "<TD align=left bgColor=#ffffff><SELECT NAME=\"APP_CRITICALITY\">";
		print "<OPTION VALUE=\"UBS Continuity Risk (Int)\">UBS Continuity Risk (Int)";
		print "<OPTION VALUE=\"UBS Survival Risk (Int)\">UBS Survival Risk (Int)";
		print "<OPTION VALUE=\"Business Desirable\">Business Desirable";
		print "<OPTION VALUE=\"Systemic Risk (Ext)\">Systemic Risk (Ext)";
		print "<OPTION VALUE=\"Critical\">Critical";
		print "</SELECT>";
		print "</TD>";
		print "<TR>";
		print "<INPUT TYPE=\"hidden\" NAME=\"REQUESTOR\" VALUE=\"$REQUESTOR\">";
		print "<INPUT TYPE=\"hidden\" NAME=\"REQUESTOR_EMAIL\" VALUE=\"$REQUESTOR_EMAIL\">";
		print "<INPUT TYPE=\"hidden\" NAME=\"APP_REF\" VALUE=\"$APP_REF\">";
		print "<INPUT TYPE=\"hidden\" NAME=\"APP_REF_SOURCE\" VALUE=\"$APP_REF_SOURCE\">";


	print "</TABLE>";
	print "<BR>";
	print "<INPUT TYPE=submit VALUE=\"Submit\">";
	print "<INPUT TYPE=reset VALUE=\"Reset\"";
	print "</FORM>";
