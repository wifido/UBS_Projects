#!C:\Perl\bin\perl.exe

#!/sbclocal/netcool/omnibus/utils/perllib/5.8.7/bin/perl

#############################################################################
#
#
# NAME:	WebGui_usage_Script.pl
# USER:	Sagar Shivnani
# VER:	0.4
# Date: 18 April 2011
# DESCRIPTION
#
#The script will be used to regularly read the WebGUI log file, and to detect entries that denote that a user has accessed an particular elements like maps,views and #filters.
#
#	Change Control
#	V0.4	Sagar Shivnani	20110506	Original
#	V0.5	Chris Janes		20110510	Initial Tidy up
#############################################################################



#############################################################################
#
#	Here we declare Librarys we need
#
#############################################################################

use strict;

#############################################################################
#
#	Here we declare the Global Variables
#
#############################################################################


my @unique = ();
my %seen   = ();
my %FilterHash = ();
my %MapHash = ();
my %ViewHash = ();
my %HtmlHash = ();
my $LogFileDir;
my @FILES;
my $Filename;
my $date;
my $LogLine;
my @Datevalue;
my @LogLines;
my $Html;
my $MapResult;
my @MapValue;
my @FilterValue;
my $ViewFound;
my $FilterResult;
my $FilterResult1;
my @FilterValue1;
my $ViewResult1;
my $Mapsize ;
my $Filtersize ;
my $Viewsize ;
my $Htmlsize ;
my $Map;
#############################################################################
#
#	Subroutines go here
#
#############################################################################


#############################################################################
#
#	Main Code Starts Here
#
#############################################################################


do "/home/janesch/scripts/WebGuiCleanUp/WebGuiCleanUp.cfg";


opendir(LOGDIR, ".");
@FILES=readdir(LOGDIR);
closedir(LOGDIR);


my $hostname = `hostname`;

foreach $Filename (@FILES)
{
	open (INFILE ,$Filename);
	@LogLines=<INFILE>;

	foreach $LogLine (@LogLines)
	{
		@Datevalue = split(/ /,$LogLine);
		$date = substr($Datevalue[3],1);
		$Html = $Datevalue[6];
		if($Html =~ /\/ibm\/console\/webtop\/.*\/.*\.html/)
		{
			if ($Html =~ m/.*html\?/)
			{}
			else
			{
				$HtmlHash{ $Html } = $date;
			}
		}

		if ($LogLine =~ m/map=(.*?); /)
		{
			@MapValue = split(/ /,$1);
			$MapResult = $MapValue[0];
			$MapHash{ $MapResult } = $date;
		}

		elsif ($LogLine =~ m/filtername=(.*?) /)
		{
			$ViewFound = $1;
			@FilterValue = split(/&/,$ViewFound);
			$FilterResult = $FilterValue[0];
			@FilterValue1 = split(/"/,$FilterResult);
			$FilterResult1 = $FilterValue1[0];
			$FilterHash{ $FilterResult1 } = $date;
		}
		elsif ($ViewFound =~ m/viewname=(.*?)\&/ )
		{
			 if (length($1) != 0)
			{
				$ViewResult1 = $1;
				$ViewHash{ $ViewResult1 } = $date;  ## Saving the View names into Hash array
			}
		}
	}
}

$Mapsize = scalar(keys %MapHash);
$Filtersize = scalar(keys %FilterHash);
$Viewsize = scalar(keys %ViewHash);
$Htmlsize = scalar(keys %HtmlHash);

open(OUTFILE, ">>/home/janesch/scripts/WebGuiCleanUp/Result_WebGui_usage_Script.log");

print " Total Maps Found in logs are = $Mapsize \n";
print  "Maps Found \n";

foreach my $key (keys %MapHash)
{
	print  "$key => $MapHash{$key}\n";
}

print "Total View Found in logs are = $Filtersize \n";

print  "Filters Found \n";
foreach (keys %FilterHash)
{
	print  "$_ => $FilterHash{$_}\n";
}



print "Total Filter Found in logs  = $Viewsize \n";
print  "Views Found \n";
foreach (keys %ViewHash)
{
	print  "$_ => $ViewHash{$_}\n";
}

print "Total HTML Pages Found in logs  = $Htmlsize \n";
print  "HTML Pages Found \n";
foreach (keys %HtmlHash)
{
	print  "$_ => $HtmlHash{$_}\n";
}

close(OUTFILE);
