#!/sbclocal/netcool/omnibus/utils/perllib/5.8.7/bin/perl


#!C:\Perl\bin\perl.exe

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

  BEGIN {

     $ENV{ ORACLE_HOME } = "/sbcimp/run/tp/oracle/client/v10.2.0.2.0-32bit";
	  $ENV{ TNS_ADMIN   } = "/sbcimp/shared/config/dbservices/oracle";
      $ENV{LANG} = "C";
      $ENV{OMNIHOME} = qw(/sbclocal/netcool/omnibus);
      $ENV{SYBASE} = qw(/sbcimp/run/tp/sybase/OpenClientServer/v12.5.1ebf13682);
      $ENV{SYBASE_OCS} = q(OCS-12_5);
      $ENV{PERL5LIB} = "";
   }

#############################################################################
#
#	Here we declare Librarys we need
#
#############################################################################
use lib "/sbcimp/run/pd/cpan/5.8.7-2005.09/lib";
use strict;
use DBI;
use DBD::Sybase;
use Time::Local;
use lib "/home/janesch/perl/lib";
use GetConfig;
use strict;
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
$Date = $Day . "/" . $Month . "/" . $Year . ":" . $Hour . ":" . $Minute . ":" . $Second;

do "/home/janesch/scripts/WebGuiCleanUp/WebGuiCleanUp.cfg";


my $MAPfileaccessed = 0;
my $SystemViewcounter = 0;
my $GlobalViewcounter = 0;
my $SystemFilterCounter = 0;
my $SysFilterDepCounter = 0;
my $GlobalFilterCounter = 0;
my $GFFDcounter = 0;
my %MapHash = ();
my %SystemViewHash = ();
my %GlobalViewHash = ();
my %SystemFilterHash = ();
my %SysFilterDepHash = ();
my %GlobalFilterHash = ();
my %GlobFilterDepHash = ();
$SystemFilterXML = new XML::Simple (KeyAttr=>[],Variables=>{name => value},ForceArray =>1);
$GlobalFilterXML = new XML::Simple (KeyAttr=>[],Variables=>{name => value},ForceArray =>1);
#$xml = new XML::Simple (ForceArray =>['dependency']);


#############################################################################
#
#	Subroutines go here
#
#############################################################################

sub GetSystemView
{
	open (INFILE ,$SystemViewFile);
	@file=<INFILE>;
	foreach $Line (@file)
	{
		if ($Line =~ m/viewName=(".*")/)
		{
			$SVResult = $1;
			@SViewvalue = split(/\"/,$SVResult);
			$SVResult1 = @SViewvalue[1];
			$SystemViewHash{ $SVResult1 } = $Date;
			#print "$VResult1\n";
			$SystemViewcounter = $SystemViewcounter + 1;
		}
	}

	print  "Configured System View Found \n";
	foreach $keys (keys %SystemViewHash)
	{
		print  "$keys => $SystemViewHash{$keys}\n";
	}
	print "Total System View found $SystemViewcounter\n";
	print  "Total System View found $SystemViewcounter\n";
}

sub GetGlobalViews
{
	open (INFILE ,"/sbclocal/tivoli/webgui/etc/data/global/view.xml");
	@file=<INFILE>;

	foreach $line (@file)
	{
		if ($line =~ m/viewName=(".*")/)
		{
			$GVResult = $1;
			@GViewvalue = split(/\"/,$GVResult);
			$GVResult1 = @GViewvalue[1];
			$GlobalViewHash{ $GVResult1 } = $Date;
			#print "$VResult1\n";
			$GlobalViewcounter = $GlobalViewcounter + 1;
		}
	}

	print  "Configured Global View Found \n";

	foreach $keys (keys %GlobalViewHash)
	{
		print  "$keys => $GlobalViewHash{$keys}\n";
	}
	print "Total Global View found $GlobalViewcounter\n";
	print  "Total Global  View found $GlobalViewcounter\n";

}

sub GetMapData
{
	opendir(LOGDIR, $MapDirName);
	@MAPFILES=readdir(LOGDIR);
	closedir(LOGDIR);
	
	$NumMapFiles = @MAPFILES;

	foreach $MAPFilename (@MAPFILES)
	{
		open (INFILE ,$MAPFilename);
		@MAPfile1=<INFILE>;

		$size = @MAPfile1;
		print  "Number of lines in this file are = $size \n" ;
		$MAPfileaccessed = $MAPfileaccessed + 1;
		foreach $line (@MAPfile1)
		{
			# getting the map name rather then whole path
			@Mapvalue1 = split(/\//,$MAPFilename);
			@Mapvalue2 = split(/\./,$Mapvalue1[6]);
			$MAPNameResult2 = @Mapvalue2[0];
			if ($line =~ m/entity="(.*?)"/)
			{
				$EntityName = $1;
				if (length($EntityName) != NULL)
				{
					$MapHash{ $EntityName } = $MAPNameResult2;	#$MapHash{ entity name for that this map } = mapname;
				}
			}
			else
			{
				if ($line =~ m/filter="(.*?)"/)
				{
					$FilterName = $1;
					if (length($FilterName) != NULL)
					{
						$MapHash{ $FilterName } = $MAPNameResult2;	#$MapHash{ entity name for that this map } = mapname;
					}
				}
			}
		}

	}
	foreach $keys (keys %MapHash)
	{
		print  "$_ => $MapHash{$keys}\n";

	}

	$count = keys %MapHash;
	print "Total MAPS Found = $NumMapFiles\n";
	print "Total MAPS accessed = $MAPfileaccessed  and found total filters = $count \n";


}

sub GetSytemFilterData
{
	foreach $e (@{$SystemFilterData->{filter}})
	{
		$SystemFilterHash{$e->{'name'}} = $e->{'view'} ;  	#$FVhash{ Filtername  } = Viewname dependency ;
	    $SystemFilterCounter = $SystemFilterCounter + 1;

			foreach $FilterDep (@{$e->{dependency}})
				{
					$SysFilterDepHash{$FilterDep->{'name'}} = $e->{'name'} ;  #$FFDhash{ Filtername Dependency  } = Filtername;
					$SysFilterDepCounter = $SysFilterDepCounter + 1;
		    	}
	}
	print  "#####Filter and view ###############\n";
	print "Total System Filter with View Dependency = $SystemFilterCounter \n";
	foreach $keys (keys %SystemFilterHash)
	{
		print  "$keys => $SystemFilterHash{$keys}\n";
	}
	print  "#####System Filter and Filter Dependency ###############\n";
	print "Total System Filter with Filter Dependency = $SysFilterDepCounter \n";

	foreach $keys (keys %SysFilterDepHash)
	{
		print  " $SysFilterDepHash{$keys} => $keys \n";
	}
}


sub GetGlobalFilter
(


############################################################################
#
#Searching for Global : Filter and Filters to View dependency
#
#########################################################################


	open(, ">>/home/shivnasa/perlss/script2/databaseScript.log");

	foreach $Filter (@{$GlobalFilterData->{filter}})
	{
		#print "Filter Name: $Filter->{name} \n";
		#print "Filter View: $Filter->{view} \n";
		$GlobalFilterHash{$Filter->{'name'}} = $Filter->{'view'} ;  	#$FVhash{ Filtername  } = Viewname dependency ;
		$GlobalFilterCounter = $GlobalFilterCounter + 1;
		foreach $FilterDep (@{$Filter->{dependency}})
		{
			#print "Filter Dependency Name: $FilterDep->{name} \n";
			$GlobFilterDepHash{$FilterDep->{'name'}} = $Filter->{'name'} ;  #$FFDhash{ Filtername Dependency  } = Filtername;
			$GFFDcounter = $GFFDcounter + 1;
		}
	}

	print  "Total Global Filter with View Dependency = $GlobalFilterCounter \n";
	foreach $keys (keys %GlobalFilterHash)
	{
		print  "$keys => $GlobalFilterHash{$keys}\n";
		#sleep 3;
	}
	print  "#####Global Filter and Filter Dependency ###############\n";
	print  "Total Global Filter with Filter Dependency = $GFFDcounter \n";
	foreach $keys (keys %GlobFilterDepHash)
	{
		print  " $GlobFilterDepHash{$keys} => $keys \n";
	}



}

##############################################################################################
#
#	sub dbConnect makes a connection to a DB and returns a DB Handle
#		Called with Hash that contains the connection details as it's only parameter
#		Returns a DB Handle
#
##############################################################################################
sub dbConnect
{
# Here we make the connect string using detaails from db.cfg
	my %DB_dbConnect = %{$_[0]};
	my $ConnectString;

	$ConnectString = "dbi:Oracle:database=" . $DB_dbConnect{'Database'} . ";HOST=" . $DB_dbConnect{'Host'} . ";PORT=" . $DB_dbConnect{'Port'} . ";SID=". $DB_dbConnect{'SID'};
# Connect to the DB (Create DB handle)
my	$dbhi = DBI->connect( $ConnectString,
						$DB_dbConnect{'User'}, 		# DB User
						$DB_dbConnect{'Password'}, 	# DB User Password
						{
							RaiseError => 1,
							AutoCommit => 1
						}
			   ) || die "Database connection not made: $DBI::errstr";
	return($dbhi);
}

##############################################################################################
#
#	sub dbDisconnect disconnects a DB handle
#		Called with the DB Handle as it's only parameter
#
##############################################################################################
sub dbDisconnect
{
	my $dbhi = $_[0];
	$dbhi->disconnect();
}




#############################################################################
#
#	Main Code Starts Here
#
#############################################################################


$SystemFilterFile="c:/Users/chrisjanes/Documents/Abilitec/WebGuiCleanUp/resource/system/filter.xml";
$GlobalFilterFile="c:/Users/chrisjanes/Documents/Abilitec/WebGuiCleanUp/resource/global/filter.xml";


die "Can't find file \"$SystemFilterFile\"" unless -f $SystemFilterFile;
die "Can't find file \"$GlobalFilterFile\"" unless -f $GlobalFilterFile;
$SystemFilterData = $SystemFilterXML->XMLin($SystemFilterFile) ;
$GlobalFilterData = $GlobalFilterXML->XMLin($GlobalFilterFile);









