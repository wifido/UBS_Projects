#!/sbcimp/run/pd/perl/5.8.7/bin/perl -w

##############################################################################################
#
# This Script inserts a record into mmadopt.NEW_ADP_REQ table
#
#	20081231			Chris Janes	Original
#	20090127	V 1.0	Chris Janes	Initial release
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
my @Data;


sub SendAMail
{
	open (MESSAGE,"| /usr/lib/sendmail -t");
                print MESSAGE "To: sh-monitoring-support\@ubs.com\n";
#               print MESSAGE "To: chris.janes\@ubs.com\n";
                print MESSAGE "CC: $REQUESTOR_EMAIL\n";
                print MESSAGE "BCC: DL-MONITORING-ASSISTANCE\n";
                print MESSAGE "From: $REQUESTOR_EMAIL\n";
                print MESSAGE "Reply-to: $REQUESTOR_EMAIL\n";
                print MESSAGE "Subject: Adoption Request for  $APP_NAME by $REQUESTOR (Request ID $Request_ID)\n";
                print MESSAGE "==================================================================\n";

				print MESSAGE "\n";
				print MESSAGE "Thank you for requesting a Netcool ClassID.\n\n\n";
				print MESSAGE "Your request (Request ID $Request_ID) contains the following information\n";
				print MESSAGE "      Requestor            : $REQUESTOR\n";
				print MESSAGE "      Application Name     : $APP_NAME\n";
				if($APP_REF_SOURCE == 1)
				{
				print MESSAGE "      App Registered in    : CMDB\n";
				print MESSAGE "      CMDB reference       : $APP_REF\n";
				}
				elsif($APP_REF_SOURCE == 1)
				{
				print MESSAGE "      App Registered in    : i-SAC\n";
				print MESSAGE "      i-SAC reference      : $APP_REF\n";
				}
				print MESSAGE "      Business Criticality : $APP_CRITICALITY\n";
				print MESSAGE "      RTB App Manager      : $UBS_RTBCONTACTNAME\n";
				print MESSAGE "\n";
				print MESSAGE "This request will generate a Remedy Ticket and a Netcool ClassID.\n\n";
				print MESSAGE "The ESM Service Delivery Netcool team will confirm the ClassID within 3 business days and will detail the next steps to onboard <application name> into Netcool.\n";
#				print MESSAGE "this is complete you will receive an email guiding you theo the next step\n";
#				print MESSAGE "in this process\n";
				print MESSAGE "\n";
				print MESSAGE "Should you have any questions with regards to this email or alerting into Netcool please contact ESM Service Delivery Support:\n";
				print MESSAGE "      Email   : sh-monitoring-support\n";
				print MESSAGE "      Chat    : #Monitoring_Support\n";
				print MESSAGE "      Hotline : 19494 4114\n";
				print MESSAGE "\n";


        		print MESSAGE "------------------------------------------------------------------\n\n";
	close (MESSAGE);

}


cd 



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
	
	print $table;
	print "<TR>$tdH Netcool New Application Monitoring Request$tdeH</TR>";
	print "</table>";
	
	
	$APP_REF_SOURCE = $formdata{APP_REF_SOURCE};
	$APP_REF = $formdata{APP_REF};
	$REQUESTOR = $formdata{REQUESTOR};
	$REQUESTOR_EMAIL = $formdata{REQUESTOR_EMAIL};
	$APP_NAME = $formdata{APP_NAME};
	$APP_CRITICALITY = $formdata{APP_CRITICALITY};
	$UBS_RTBCONTACTNAME = $formdata{UBS_RTBCONTACTNAME};
	
	$APP_NAME =~ s/'/''/g;
	$UBS_RTBCONTACTNAME =~ s/'/''/g;
	
	if ($Verbose){print"<p>APP_REF_SOURCE = $APP_REF_SOURCE ";}
	if ($Verbose){print"<p>APP_REF = $APP_REF ";}
	if ($Verbose){print"<p>REQUESTOR = $REQUESTOR ";}
	if ($Verbose){print"<p>REQUESTOR_EMAIL = $REQUESTOR_EMAIL ";}
	if ($Verbose){print"<p>APP_NAME = $APP_NAME ";}
	if ($Verbose){print"<p>APP_CRITICALITY = $APP_CRITICALITY ";}
	if ($Verbose){print"<p>UBS_RTBCONTACTNAME = $UBS_RTBCONTACTNAME ";}
	if ($Verbose){print"<p>";}
	
	
	
	$SQL = "insert into NEW_ADP_REQ   ( REQUESTOR, REQUESTOR_EMAIL, APP_REF, APP_REF_SOURCE, REQUEST_DATE, APP_NAME, RTB_APP_MAN, APP_CRITICALITY)values ('" . $REQUESTOR . "', '" . $REQUESTOR_EMAIL . "', '" . $APP_REF . "', '" . $APP_REF_SOURCE . "', sysdate, '" . $APP_NAME . "', '" . $UBS_RTBCONTACTNAME . "', '" . $APP_CRITICALITY . "')";
	if ($Verbose){print "$SQL\n";}
	PutReqData;


	$SQL = "select Request_ID from NEW_ADP_REQ where APP_NAME = '" . $APP_NAME . "'";
	if ($Verbose){print "$SQL\n";}
	GetReqData;
	$Request_ID = $Data[0];

	SendAMail;
	my @Name = split (/ /, $REQUESTOR);
	print $table;
	print "<TR>$td1$tdSA $Name[0] $tdeS</TR>";
	print "<TR>$td1$td Thank you for requesting adoption by ESM Monitoring using Netcool$tde</TR>";
	print "<TR>$td1$td Your request (Request ID $Request_ID) contains the following information$tde</TR>";
	print "</Table>";
	print $table;
	print "<tr>$td1$tdS Requestor:$tdeS$td$REQUESTOR$tde</tr>";
	print  "<tr>$td1$tdS Application Name:$tdeS$td$APP_NAME$tde</tr>";
	if($APP_REF_SOURCE == 1)
	{
		print  "<tr>$td1$tdS Application Registered in :$tdeS$td CMDB$tde</tr>";
		print  "<tr>$td1$tdS CMDB reference :$tdeS$td$APP_REF</td></tr>";
	}
	elsif($APP_REF_SOURCE == 1)
	{
		print  "<tr>$td1$tdS Application Registered in :$tdeS$td i-SAC$tde</tr>";
		print  "<tr>$td1$tdS i-SAC reference :$tdeS$td$APP_REF$tde</tr>";
	}
	print  "<tr>$td1$tdS Business Criticality :$tdeS$td$APP_CRITICALITY$tde</tr>";
	print  "<tr>$td1$tdS RTB Application Manager:$tdeS$td$UBS_RTBCONTACTNAME$tde</tr>";
	print "</Table>";
	print  $table;
	print  "<TR>$td1$td This request will automatically generate a Remedy Ticket, which in turn will generate a Netcool Class. This should happen withing 3 working days. When this is complete you will receive an email guiding you theo the next stepin this process$tde</TR>";
	print "</Table>";
	print  "<P>";
	print $support;
				
	
