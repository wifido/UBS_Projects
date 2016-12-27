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
#	V0.5	Chris Janes		20110510	Initial Tidy up#############################################################################

$DIRNAME='/home/shivnasa/perlss/script1';
@FILES=`ls -1 $DIRNAME/*.log`;
$Filename = @FILES;

my @unique = ();
my %seen   = ();
my %Fhash = ();
my %Mhash = ();
my %Vhash = ();

foreach $Filename (@FILES)
{
open (INFILE ,$Filename);
open(OUTFILE, ">>/home/shivnasa/perlss/script1/Result_WebGui_usage_Script.log");
@file=<INFILE>;

$hostname = `hostname`;
($Second, $Minute, $Hour, $Day, $Month, $Year, $WeekDay, $DayOfYear, $IsDST) = localtime(time);
$Year += 1900;
$Month++;
$date = "$Day/$Month/$Year";
#$Mapcounter = 0;
#$Filtercounter = 0;
#$Viewcounter = 0;

		foreach $line (@file)
		{

			if ($line =~ m/map=(.*?); /)

				{


				@Mapvalue = split(/ /,$1);
				$MResult = @Mapvalue[0];
				$Mhash{ $MResult } = $date;
				#print $1."\n";
				#print $MResult."\n";
				#sleep 3;
				#$Mapcounter = $Mapcounter +1;
				}

			else
			{

				if ($line =~ m/filtername=(.*?) /)
				{

				#looking for Filternames#
				#next if $Seen{ $1 }++;
				#push @unique, $1;

				$ViewFound = $1;
				@filtervalue = split(/&/,$ViewFound);
				$FResult = @filtervalue[0];

				@filtervalue1 = split(/"/,$FResult);
				$FResult1 = @filtervalue1[0];

				$Fhash{ $FResult1 } = $date;
				#$Filtercounter = $Filtercounter + 1;

				#print OUTFILE  "searched Filter string = $1.\n";
				#print OUTFILE  "Filtername = $FResult.\n";
				#print "ViewFound string before if = $ViewFound.\n";
				#print OUTFILE  $FResult."\n";
				#sleep 3;

				#looking for Viewnames#
				#1_HFS_DMS_App&viewtype=global&viewname=AutoConf&datasources=NCOMS&commands=&timestamp=0.


						if ($ViewFound =~ m/viewname=(.*?)\&/ )
						{

							 if (length($1) != NULL)
								{

								#print "ViewFound string = $ViewFound.\n";
								#print "Viewname = $1.\n";
								$VResult1 = $1;
								#print OUTFILE "viewname = $VResult1 \n";
								$Vhash{ $VResult1 } = $date;  ## Saving the View names into Hash array
								#print "after viewname = $VResult1.\n";
								#sleep 5;
								#$Viewcounter = $Viewcounter + 1;
								}



						}
						else
						{
						#print "view not found .\n";
						}



				}
			}
		}


#close(OUTFILE);
}

$Mapsize = scalar(keys %Mhash);
$Filtersize = scalar(keys %Fhash);
$Viewsize = scalar(keys %Vhash);

print OUTFILE "******************************\n";
print " Total Maps Found in logs are = $Mapsize \n";
print OUTFILE "Maps Found \n";

foreach (keys %Mhash)
{
print OUTFILE "$_ => $Mhash{$_}\n";
}
print OUTFILE "\*******************************\n";

print "Total View Found in logs are = $Filtersize \n";
print OUTFILE "\*******************************\n";
print OUTFILE "Filters Found \n";
foreach (keys %Fhash)
{
print OUTFILE "$_ => $Fhash{$_}\n";
}
print OUTFILE "\*******************************\n";

print OUTFILE "\*******************************\n";
print "Total Filter Found in logs  = $Viewsize \n";
print OUTFILE "Views Found \n";
foreach (keys %Vhash)
{
print OUTFILE "$_ => $Vhash{$_}\n";
}
print OUTFILE "\*******************************\n";

close(OUTFILE);
