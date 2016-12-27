#!/usr/bin/perl
#
# CanIHaveAClass.cgi
# ---------------------------
#
# Written by Chris Janes
#


print "Content-type: text/html\n\n";


$buffer = $ENV{'QUERY_STRING'};

@pairs = split(/&/, $buffer);

foreach $pair (@pairs)
{
    ($name, $value) = split(/=/, $pair);
    # Un-Webify plus signs and %-encoding
    $value =~ tr/+/ /;
    $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
    $name =~ tr/+/ /;
    $name =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg; 
    $FORM{$name} = $value;
}



print <<__HTML__;
<html>
<head>

<link rel=stylesheet TYPE="text/css"
                           href="/ubs_style.css" title="Default">

</head>

<title>Please can I have a Netcool Class</title>
<body class="base">


<table BORDER="0" WIDTH="100%">
<tr>
<td class="tableheading" align="center">Netcool Classes</td>
</tr>
<tr>
<td align="center">
<br>This tool allows the user to request a Netcool Class for use in Monitoring</p>
</tr>
</td>
<tr>
<td align="center">
<form name=NetcoolClass>
<!--<SELECT style="font-size:12px;color:#006699;font-family:verdana;background-color:#ffffff;" ONCHANGE="parent.main.location = this.options[this.selectedIndex].value;">-->
<SELECT style="font-size:12px;color:#006699;font-family:verdana;background-color:#ffffff;" ONCHANGE="location = this.options[this.selectedIndex].value;">
<option value=''>Select an Entity Group</option>
<option value=''>-------------------------------</option>
__HTML__

print"Here it is\n";

print <<__HTML__;
</select>
<br>
<p align="center"><input type="button" value="Close Window" onclick="window.close()"></p>
</FONT>
</BODY>
</HTML>
__HTML__
