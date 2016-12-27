#!/usr/bin/perl
#
# DisplayEntities.cgi
# ---------------------------
#
# Written by John Owens 02/12/04
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

system "ls -l /sbclocal/netcool/webtop/config/entities/ | grep drw | awk '{print \"<option value=/cgi-bin/ShowEntities.cgi?\$entity_group=\" \$9 \">\" \$9 \"</option>\"}' | sort  > /tmp/entity_groups.txt";


print <<__HTML__;
<html>
<head>

<link rel=stylesheet TYPE="text/css"
                           href="/ubs_style.css" title="Default">

</head>

<title>Display all Entities from an Entity Group</title>
<body class="base">


<table BORDER="0" WIDTH="100%">
<tr>
<td class="tableheading" align="center">Display Entities</td>
</tr>
<tr>
<td align="center">
<br>This tool allows the user to Display the underlying SQL for all the individual enitiies from the selected <strong>Entity Group</strong>.<br>From the list below, select the Entity Group you are interested in to display the results.</p>
</tr>
</td>
<tr>
<td align="center">
<form name=EntityGroups>
<!--<SELECT style="font-size:12px;color:#006699;font-family:verdana;background-color:#ffffff;" ONCHANGE="parent.main.location = this.options[this.selectedIndex].value;">-->
<SELECT style="font-size:12px;color:#006699;font-family:verdana;background-color:#ffffff;" ONCHANGE="location = this.options[this.selectedIndex].value;">
<option value=''>Select an Entity Group</option>
<option value=''>-------------------------------</option>
__HTML__

system "cat /tmp/entity_groups.txt <<__HTML__";

print <<__HTML__;
</select>
<br>
<p align="center"><input type="button" value="Close Window" onclick="window.close()"></p>
</FONT>
</BODY>
</HTML>
__HTML__
