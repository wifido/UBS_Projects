#!C:\Perl\bin\perl.exe

#!/sbclocal/netcool/omnibus/utils/perllib/5.8.7/bin/perl


#############################################################################
# NAME:	Database_population_Script.pl
# USER:	Sagar Shivnani
# VER:	0.4
# Date: 05 May 2011
# DESCRIPTION
#
#this script will read the existing WebGUI configuration, and to load initial information about the configuration into the database.
# WebGUI Configuration:
#1)System View : /sbclocal/tivoli/webgui/etc/data/system/view.xml
#2)Global View : /sbclocal/tivoli/webgui/etc/data/global/view.xml
#3)Maps: /sbclocal/tivoli/webgui/etc/maps
#4)System Filter: /sbclocal/tivoli/webgui/etc/data/system/filter.xml
#5)Global Filter : /sbclocal/tivoli/webgui/etc/data/global/filter.xml
#
#	Change Control
#	V0.2	Sagar Shivnani	20110506	Original
#	V0.4	Chris Janes		20110510	Initial Tidy up
#############################################################################


#############################################################################
#
#	Here we declare Librarys we need
#
#############################################################################


use XML::Simple;
use Data::Dumper;

#############################################################################
#
#	Here we declare the Global Variables
#
#############################################################################
$hostname = `hostname`;
($Second, $Minute, $Hour, $Day, $Month, $Year, $WeekDay, $DayOfYear, $IsDST) = localtime(time);
$Year += 1900;
$Month++;
$date = "$Day/$Month/$Year";

do "/home/janesch/scripts/WebGuiCleanUp/WebGuiCleanUp.cfg";



opendir(LOGDIR, $MapDirName);
@MAPFILES=readdir(LOGDIR);
closedir(LOGDIR);


my $MAPfileaccessed = 0;
my $SViewcounter = 0;
my $GViewcounter = 0;
my $SFViewcounter = 0;
my $SFFDcounter = 0;
my $GFViewcounter = 0;
my $GFFDcounter = 0;
my %Mhash = ();
my %SVhash = ();
my %GVhash = ();
my %SFVhash = ();
my %SFFDhash = ();
my %GFVhash = ();
my %GFFDhash = ();

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
$SystemFilterXML = new XML::Simple (KeyAttr=>[],Variables=>{name => value},ForceArray =>1);
$GlobalFilterXML = new XML::Simple (KeyAttr=>[],Variables=>{name => value},ForceArray =>1);
#$xml = new XML::Simple (ForceArray =>['dependency']);

$SystemFilterFile="c:/Users/chrisjanes/Documents/Abilitec/WebGuiCleanUp/resource/system/filter.xml";
$GlobalFilterFile="c:/Users/chrisjanes/Documents/Abilitec/WebGuiCleanUp/resource/global/filter.xml";


die "Can't find file \"$SystemFilterFile\"" unless -f $SystemFilterFile;
die "Can't find file \"$GlobalFilterFile\"" unless -f $GlobalFilterFile;
$SystemFilterData = $SystemFilterXML->XMLin($SystemFilterFile) ;
$GlobalFilterData = $GlobalFilterXML->XMLin($GlobalFilterFile);



#############################################################################
#
# Searching for System Views
#
#########################################################################
open (INFILE ,$SystemViewFile);

@file=<INFILE>;

foreach $line (@file)
{
	if ($line =~ m/viewName=(".*")/)
	{
		$SVResult = $1;
		@SViewvalue = split(/\"/,$SVResult);
		$SVResult1 = @SViewvalue[1];
		$SVhash{ $SVResult1 } = $date;
		#print "$VResult1\n";
		$SViewcounter = $SViewcounter + 1;
	}
}
		
open(OUTFILE, ">>" . $AppLogFile);
print OUTFILE "******************************\n";
print OUTFILE "Configured System View Found \n";

foreach (keys %SVhash)
{
	print OUTFILE "$_ => $SVhash{$_}\n";
}

print OUTFILE "\*******************************\n";
print "Total System View found $SViewcounter\n";
print OUTFILE "Total System View found $SViewcounter\n";

close(OUTFILE);

############################################################################
############################################################################
#
# Searching for Global Views
#
############################################################################
open (INFILE ,"/sbclocal/tivoli/webgui/etc/data/global/view.xml");

@file=<INFILE>;

foreach $line (@file)
{
	if ($line =~ m/viewName=(".*")/)
	{
		$GVResult = $1;
		@GViewvalue = split(/\"/,$GVResult);
		$GVResult1 = @GViewvalue[1];
		$GVhash{ $GVResult1 } = $date;
		#print "$VResult1\n";
		$GViewcounter = $GViewcounter + 1;
	}
}

open(OUTFILE, ">>" . $AppLogFile);
print OUTFILE "******************************\n";
print OUTFILE "Configured Global View Found \n";

foreach (keys %GVhash)
{
	print OUTFILE "$_ => $GVhash{$_}\n";
}

print OUTFILE "\*******************************\n";
print "Total Global View found $GViewcounter\n";
print OUTFILE "Total Global  View found $GViewcounter\n";

close(OUTFILE);

############################################################################
#
#
#  Searching for MAPS and Maps to Filter dependency
#
############################################################################

$MAPFilename = @MAPFILES;
#print  "Total MAPS Found = $MAPFilename\n";

foreach $MAPFilename (@MAPFILES)
{
	open (INFILE ,$MAPFilename);
	@MAPfile1=<INFILE>;
#	print OUTFILE "####################\n";
#	print OUTFILE "Total Fileaccessed so far = $MAPfileaccessed \n";
#	print OUTFILE "started with filename = $MAPFilename \n" ;
	$size = @MAPfile1;
	print OUTFILE "Number of lines in this file are = $size \n" ;
	$MAPfileaccessed = $MAPfileaccessed + 1;
	foreach $line (@MAPfile1)
	{
		#print OUTFILE "step 1 filename = $MAPFilename\n";
		# getting the map name rather then whole path
		@Mapvalue1 = split(/\//,$MAPFilename);
		#$MAPNameResult1 = @Mapvalue1[6];
		#print $Mname1."\n";
		@Mapvalue2 = split(/\./,$Mapvalue1[6]);
		$MAPNameResult2 = @Mapvalue2[0];
		if ($line =~ m/entity="(.*?)"/)
		{
			if (length($1) != NULL)
			{
				$MResult1 = $1;
				#$Mhash{ $MResult1 } = $MAPFilename;
				$Mhash{ $MResult1 } = $MAPNameResult2;	#$Mhash{ entity name for that this map } = mapname;
			}
		}
		else
		{
			if ($line =~ m/filter="(.*?)"/)
			{
				if (length($1) != NULL)
				{
					$MResult1 = $1;
					#$Mhash{ $MResult1 } = $MAPFilename;
					$Mhash{ $MResult1 } = $MAPNameResult2;	#$Mhash{ entity name for that this map } = mapname;
				 }
			}
		}
	}
#print OUTFILE "finished with filename = $MAPFilename \n" ;
#print OUTFILE "####################\n";
}
open(OUTFILE, ">>" . $AppLogFile);
foreach (keys %Mhash)
{
	print OUTFILE "$_ => $Mhash{$_}\n";
	#sleep 3;
}

$count = keys %Mhash;
print "Total MAPS Found = $MAPFilename\n";
print "Total MAPS accessed = $MAPfileaccessed  and found total filters = $count \n";
print OUTFILE "Total MAPS Found = $MAPFilename\n";
print OUTFILE "Total MAPS accessed = $MAPfileaccessed  and found total filters = $count \n";
close(OUTFILE);

############################################################################
#
#Searching for System : Filter and Filters to View dependency
#
############################################################################


open(OUTFILE, ">>/home/shivnasa/perlss/script2/databaseScript.log");

	foreach $e (@{$SystemFilterData->{filter}})
	{
		#print "Filter Name: $e->{name} \n";
		#print "Filter View: $e->{view} \n";
		$SFVhash{$e->{'name'}} = $e->{'view'} ;  	#$FVhash{ Filtername  } = Viewname dependency ;
	    $SFViewcounter = $SFViewcounter + 1;

			foreach $a (@{$e->{dependency}})
				{
					#print "Filter Dependency Name: $a->{name} \n";
					$SFFDhash{$a->{'name'}} = $e->{'name'} ;  #$FFDhash{ Filtername Dependency  } = Filtername;
					$SFFDcounter = $SFFDcounter + 1;
		    	}
	}


print OUTFILE "#####Filter and view ###############\n";

print OUTFILE "Total System Filter with View Dependency = $SFViewcounter \n";
print "Total System Filter with View Dependency = $SFViewcounter \n";
print OUTFILE "#####Begin ###############\n";

foreach (keys %SFVhash)
	{
	print OUTFILE "$_ => $SFVhash{$_}\n";
	#sleep 3;
	}

print OUTFILE "#####End ###############\n";
print OUTFILE "\n";

print OUTFILE "#####System Filter and Filter Dependency ###############\n";

print OUTFILE "Total System Filter with Filter Dependency = $SFFDcounter \n";
print "Total System Filter with Filter Dependency = $SFFDcounter \n";
print OUTFILE "#####Begin ###############\n";
foreach (keys %SFFDhash)
	{
	#print OUTFILE "$_ => $SFFDhash{$_}\n";
	print OUTFILE " $SFFDhash{$_} => $_ \n";
	#sleep 3;
	}
print OUTFILE "#####End ###############\n";
close(OUTFILE);

#print "\n see now\n";
#print Dumper($data);


############################################################################

############################################################################
#
#Searching for Global : Filter and Filters to View dependency
#
#########################################################################


open(OUTFILE, ">>/home/shivnasa/perlss/script2/databaseScript.log");

	foreach $e (@{$GlobalFilterData->{filter}})
	{
		#print "Filter Name: $e->{name} \n";
		#print "Filter View: $e->{view} \n";
		$GFVhash{$e->{'name'}} = $e->{'view'} ;  	#$FVhash{ Filtername  } = Viewname dependency ;
	    $GFViewcounter = $GFViewcounter + 1;
			foreach $a (@{$e->{dependency}})
				{
					#print "Filter Dependency Name: $a->{name} \n";
					$GFFDhash{$a->{'name'}} = $e->{'name'} ;  #$FFDhash{ Filtername Dependency  } = Filtername;
					$GFFDcounter = $GFFDcounter + 1;
		    	}
	}


print OUTFILE "#####Global Filter and view ###############\n";

print OUTFILE "Total Global Filter with View Dependency = $GFViewcounter \n";
print "Total Global Filter with View Dependency = $GFViewcounter \n";
print OUTFILE "#####Begin ###############\n";

foreach (keys %GFVhash)
{
	print OUTFILE "$_ => $GFVhash{$_}\n";
	#sleep 3;
}

print OUTFILE "#####End ###############\n";
print OUTFILE "\n";

print OUTFILE "#####Global Filter and Filter Dependency ###############\n";

print OUTFILE "Total Global Filter with Filter Dependency = $GFFDcounter \n";
print "Total Global Filter with Filter Dependency = $GFFDcounter \n";
print OUTFILE "#####Begin ###############\n";
foreach (keys %GFFDhash)
{
	#print OUTFILE "$_ => $GFFDhash{$_}\n";
	print OUTFILE " $GFFDhash{$_} => $_ \n";
	#sleep 3;
}
print OUTFILE "#####End ###############\n";
close(OUTFILE);

#print "\n see now\n";
#print Dumper($data);


############################################################################
