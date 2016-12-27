#!/sbcimp/run/pd/perl/prod/bin/perl -w

if ($ENV{'REQUEST_METHOD'} eq 'POST')
{
	read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'} + 2);
        @pairs = split(/&/, $buffer);
        foreach $pair (@pairs)
	{
        	($name, $value) = split(/=/, $pair);
                $value =~ tr/+/ /;
                $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
                $FORM{$name} = $value;
        }

	$Requestor = $FORM{"Requestor"};
	$Requestoremail = $FORM{"Requestoremail"};
	$change = $FORM{"change"};
	$Request = $FORM{"Request"};
	$Comments = $FORM{"Comments"};
	$count = 1;
	$number = $FORM{number};

	# Then sends the email

	open (MESSAGE,"| /usr/lib/sendmail -t");
                print MESSAGE "To: sh-monitoring-support\@ubs.com\n";
                print MESSAGE "CC: $FORM{Requestoremail}\n";
                print MESSAGE "From: $FORM{Requestoremail}\n";
                print MESSAGE "Reply-to: $FORM{Requestoremail}\n";
                print MESSAGE "Subject: Autosys Lookup Push Request For $FORM{Requestor} \n\n\n";
                print MESSAGE "Requestor           : $FORM{Requestor}\n";
                print MESSAGE "Add / Modify Info   : $FORM{change}\n";
                print MESSAGE "==============================================================================\n";

                print MESSAGE "Add the following to the autosysJobClassGIDSysDesig table in the Autosys_ClassGroup.lookup \n\n";
                $count = 1;
                while ($count <= $number) {
                                $jobname = "\$FORM{jobname$count}";
                                $evaljobname = eval $jobname;
                                $class = "\$FORM{class$count}";
                                $evalclass = eval $class;
                                $ownergid = "\$FORM{ownergid$count}";
                                $evalownergid = eval $ownergid;
				$environment = "\$FORM{environment$count}";
                                $evalenvironment = eval $environment;
				$evalenvironment =~ m/([0-9])/;
				$env = $1;


                                print MESSAGE "\{\"$evaljobname\",\"$evalclass\",\"$evalownergid\",\"$env\"\}\n";
				push(@lookup,"\{\"$evaljobname\",\"$evalclass\",\"$evalownergid\",\"$env\"\}<br>");
                        $count++;

                }

        	print MESSAGE "------------------------------------------------------------------------------\n\n";
	        print MESSAGE "Comments            : $FORM{Comments}\n";
	close (MESSAGE);
}


print <<EndHTML;

<html>
<head>
<title>Lookuppush Request</title>
</head>

<body bgcolor=#FFFFFF text="#000000" link="#003399" vlink="#003399" alink="#003399">
	<table border="0" cellSpacing="1" cellPadding="8" width="800" bgcolor=#003366>
	<tr class="headline" bgColor=#0066cc>
		<TD class=headlinetext align=middle><FONT color=white><STRONG>AUTOSYS LOOKUP PUSH REQUEST SUBMITTED</STRONG></FONT></TD>
	</tr>
	<tr>
		<td class="reportTitle">
                <P align=center><FONT color=white><STRONG>An automated email has been sent to the Monitoring support team requesting Lookuppush</FONT></STRONG>
		<P align=left><FONT color=white><STRONG>If any of the following details are incorrect please wait for the email with the change number and reply accordingly.</FONT></STRONG>
		<table bgColor=#99ccff border="0" width=100%>
		<tr>
			<td width=300 bgColor=#ddddff><STRONG>Requestor Name :</STRONG></td>
			<td> <B>$Requestor</B></td>
		</tr>
                <tr>
                        <td width=300 bgColor=#ddddff><STRONG>Requestor Email :</STRONG></td>
			<td> <B>$Requestoremail</B></td>
                </tr>
                <tr>
                        <td width=300 bgColor=#ddddff><STRONG>Add / Modify :</STRONG></td>
			<td> <B>$change</B></td>
                </tr>
		</table
                <P align=left><FONT color=white><STRONG>The following lookups have been requested</FONT></STRONG>
                <table bgColor=#99ccff border="0" width=100%>

                <tr>
                        <td width=200 bgColor=#ddddff><STRONG>The following lookups have been requested :</STRONG></td>
                        <td><B>@lookup</B></td>
                </tr>
		<tr>
                        <td width=200 bgColor=#ddddff><STRONG>Additional Comments :</STRONG></td>
                        <td> <B>$Comments</B></td>
                </tr>

		</table>
	</tr>
	</table>
	</P></FONT></I><a href="http://monitoring/monitoring_information/autosys/index.shtml" target="_self">Click Here for Another Lookuppush Request</a>
</table>
</body>
</html>
EndHTML
