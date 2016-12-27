#!/sbcimp/run/pd/csm/32-bit/perl/5.12.3/bin/perl
# $Id: patroltoAsagent.pl 1577 2011-10-05 14:48:37Z harperri $
# $URL: https://ims-svn.swissbank.com/prod-kerb/AGENTENG/trunk/asagent/migration/patroltoAsagent.pl $

use strict;
use warnings;

use lib "/sbcimp/run/pd/csm/32-bit/cpan/5.12.3-2011.03/lib";

use XML::LibXML;
use File::Basename;
use File::stat;
use Data::Dumper;
use Getopt::Std;

my $opts = {};

getopts('dho:i:f:l:', $opts);

if ($opts->{h}) {
	print <<_USAGE_;
Patrol to AsAgent Migration Script
Usage: $0 [-d] -o <Output Directory> [-i <Input Directory> | -f <Input File>] [-l <LOB: WMSB|WMA>]
Use -d for Debug mode
_USAGE_
	exit 1;
}

my $output_directory	= $opts->{o};
my $input_directory	= $opts->{i};
my $input_file		= $opts->{f};
my $debug		= $opts->{d};
my $lob			= $opts->{l};

my $monitors = {};
my @files = ();

# Glob the directory contents if the input is a directory
if ($input_directory) {
	opendir(DIR, $input_directory) or print "ERROR: Directory '$input_directory' - $!\n";

	while (defined(my $file = readdir(DIR))) {
		next if $file eq '.' or $file eq '..';
		push @files, "$input_directory/$file";
	}

	closedir DIR;
} else {
	# else push the one file into an array
	push @files, $input_file;
}

# Now process all the files
foreach my $patrol_config (@files) {
	
	my $obs_index = 1;
	
	# Check whether this file exists
	unless ( -f $patrol_config ) {
		print "ERROR: File '$patrol_config' not found\n";
		next;
	}
	
	print "Input file: $patrol_config\n";
	
	# If the file has zero size, ignore it
	unless(stat($patrol_config)->size > 0) {
		print "[LOG] Patrol configuration file '$patrol_config' is empty, skipping\n";
		next;
	}

	# Read the Patrol configuration into the hash
	$/ = undef;
	open CFG, $patrol_config;
	binmode CFG;
	my $file = <CFG>;
	close CFG;

	my @file_lines = split '}\,|\n', $file;

	my ($shortname, $componentname);
	my @filename = split '\.', basename($patrol_config);
	
	if ($opts->{l}) {
		if (lc($opts->{l}) eq 'wma' or lc($opts->{l}) eq 'wmus') {
			$patrol_config =~ s/APP_//;
			($shortname, undef) = split '_', basename($patrol_config);
			$componentname = shift(@filename);
		}
	} else {
		($shortname, undef) = @filename;
		$componentname = $shortname;
	}
	
	# If the component name has any periods in, split and take the first bit
	my $cname = $componentname;
	($cname, undef) = split '\\.', $componentname;	
	$componentname = $cname;
		
	# Define the output file name
	my $output_file = $componentname.".xml";

	foreach my $line (@file_lines) {
		$line =~ s/}?\n//g;

		next unless $line;
		next if $line =~ /PATROL_CONFIG/;
		next if $line =~ /paramSettingsStatusFlag/;

		my ($monitor_name, $configuration_command, $configuration_value, $severity);

		if ($line =~ m!/PMG/CONFIG!) {
			print "[LOG] $line\n";

			# Patrol Log KM monitor
			$line =~ m!^"/PMG/CONFIG/(.+)/(.+)" = \{(.+)!;
			$monitor_name = $1;
			$configuration_command = $2;
			$configuration_value = $3;

			$configuration_value =~ s!\\\"!!g;	#" Sanitise configuration value in case of unwanted characters
			$configuration_value =~ /"(.+)"/;
			$configuration_value = $1;

			$monitors->{$monitor_name}->{variables}->{alertkey}	= "$monitor_name-CEF210_CSCUBS";
			$monitors->{$monitor_name}->{variables}->{object}	= $monitor_name;
			$monitors->{$monitor_name}->{variables}->{subclass}	= "LOGMON";

			$configuration_value =~ s!\\!!g;	# Remove back slash characters

			if ($configuration_command eq 'actName') {
				$monitors->{$monitor_name}->{variables}->{alertgroup}	= "LOGMON-".$configuration_value."-PEM";
				$monitors->{$monitor_name}->{variables}->{parameter}	= $configuration_value;
				
				# Generate a periodicity for this monitor (between 60s & 120s)
				$monitors->{$monitor_name}->{periodicity} = 60 + (int(60 * rand()));

				# Do we need to use path or pathregex?
				if ($configuration_value =~ /\*|\+|\?/) {
					$monitors->{$monitor_name}->{parameters}->{pathregex} = $configuration_value;
				} else {
					$monitors->{$monitor_name}->{parameters}->{path} = $configuration_value;
				}

			} elsif ($configuration_command eq 'actRegExp1') {
				$monitors->{$monitor_name}->{parameters}->{regex} = $configuration_value;

			} elsif ($configuration_command eq 'actAlertEventMessage') {
				$configuration_value =~ s/ %[0-9]+-//g;
				$monitors->{$monitor_name}->{message_prefix} = $configuration_value;
				
			} elsif ($configuration_command eq 'actStateEvent1') {
				# Map Warning -> Minor/Warning, Alarm -> Critical
				if ($configuration_value == 4) {
					$monitors->{$monitor_name}->{severity} = 5;
				} elsif ($configuration_value == 3) {
					$monitors->{$monitor_name}->{severity} = 3;
				} else {
					$monitors->{$monitor_name}->{severity} = 1;	# Clear/Indeterminate alert
				}

			} elsif ($configuration_command eq 'actFileType') {
				if ($configuration_value == 1) {
					$monitors->{$monitor_name}->{type} = 'agent.mon.logMonitor';
					$monitors->{$monitor_name}->{parameters}->{samplePerMatch} = 'true';
					$monitors->{$monitor_name}->{observations}->{$monitor_name.'obs'} = {
						test_type => 'true',
						test_params => {
							arg0 => "fvalue(occurrence)",
						},
						severity => $monitors->{$monitor_name}->{severity},
						trap_dest => 'PROD',
						message => "%(Facet.occurrence)s found in ",
					};
				} elsif ($configuration_value == 2) {
					$monitors->{$monitor_name}->{type} = 'agent.mon.osCmd';
					$monitors->{$monitor_name}->{parameters}->{type} = 'string';
					$monitors->{$monitor_name}->{observations}->{$monitor_name.'obs'} = {
						test_type => 'regex',
						test_params => {
							arg0 => "fvalue(stdout)",
							regex => '',
						},
						severity => $monitors->{$monitor_name}->{severity},
						trap_dest => 'PROD',
						message => '%(Facet.occurrence)s',
					};
				}
			}

		} elsif ($line =~ m!/AS/EVENTSPRING/PARAM_SETTINGS!) {
			print "[THRES] $line\n" if $opts->{d};
			# Metric monitor of some kind. The instance will define what we're monitoring and the
			#  5th '/' field will be the monitor type. The { REPLACE = ... } section defines the
			#  thresholds (warning/major, alarm/critical)
			# "/AS/EVENTSPRING/PARAM_SETTINGS/THRESHOLDS/PROCPRES/webseald10/PROCPPCount" = { REPLACE = "1,0 0 0 0 0 0,0 0 0 0 0 0,1 0 0 0 0 2"
			# Row enable
			# Border Range: '(Enabled) (min) (max) (trigger setting) (trigger period) (alert state)'

			$line =~ m!"/AS/EVENTSPRING/PARAM_SETTINGS/THRESHOLDS/(.+)/(.+)/(.+)" = { [A-Z]+ = "(.+)".*$!;
			my $metric_type		= $1;
			my $monitor_name	= $2;
			my $monitor_facet	= $3;

			if ($monitor_name eq '__ANYINST__') {
				print "[ERROR] Monitors referencing '__ANYINST__' should be manually converted\n";
				next;
			}
			
			$monitors->{$monitor_name}->{variables}->{parameter}	= $monitor_facet;
			$monitors->{$monitor_name}->{variables}->{object}	= $monitor_name;

			print "Monitor type: $metric_type, Monitor Name: $monitor_name, Facet: $monitor_facet\n" if $opts->{d};

			my ($t, $p)	= {};
			my $clear_thres	= 0;
			my $facet;

			# Split the threshold into to appropriate fields
			( $p->{enable},
				$p->{border}->{enable},	$p->{border}->{lower}, $p->{border}->{upper},
				$p->{border}->{trigger}, $p->{border}->{trigger_delay}, $p->{border}->{alertstate},

				$p->{warning}->{enable}, $p->{warning}->{lower}, $p->{warning}->{upper},
				$p->{warning}->{trigger}, $p->{warning}->{trigger_delay}, $p->{warning}->{alertstate},

				$p->{alarm}->{enable}, $p->{alarm}->{lower}, $p->{alarm}->{upper},
				$p->{alarm}->{trigger}, $p->{alarm}->{trigger_delay}, $p->{alarm}->{alertstate}
			) = split ' |,', $4;

			# If none are enabled, forget this line
			next unless $p->{enable};
			next unless ($p->{border}->{enable} or $p->{alarm}->{enable} or $p->{warning}->{enable});

			# Work out which is critical & which is major
			if ($p->{warning}->{alertstate} eq 1) {
				$t->{major} = $p->{warning};
			} elsif ($p->{alarm}->{alertstate} eq 1) {
				$t->{major} = $p->{alarm};
			}
			if ($p->{warning}->{alertstate} eq 2) {
				$t->{critical} = $p->{warning};
			} elsif ($p->{alarm}->{alertstate} eq 2) {
				$t->{critical} = $p->{alarm};
			}
			$t->{border} = $p->{border};

			# Decide which
			if ($metric_type eq 'FILESYSTEM') {
				# Filesystem monitor
				$monitor_name = $monitor_name."Fs";
				
				my ($mount_point);
				$facet	= 'dfPercentUsed';

				# Has a FILESYSTEM.filterList been seen for this?
				if (!$monitors->{$monitor_name}) {
					print "[DBG] No filterList for this entry: $monitor_name, generating it\n";

					$monitors->{$monitor_name}->{type}		= 'agent.disk.diskUsage';
					$monitors->{$monitor_name}->{periodicity}	= 60 + (int(60 * rand()));

					if ($monitor_name eq 'root') {
						$mount_point = '/';
					} else {
						$mount_point = '/'.$monitor_name;
						$mount_point =~ s!-!/!g;
					}

					$monitors->{$monitor_name}->{parameters}->{device}	= $mount_point;
					$monitors->{$monitor_name}->{variables}->{alertgroup}	= "$metric_type-$monitor_facet-PEM";
					$monitors->{$monitor_name}->{variables}->{alertkey}	= "$monitor_name-CEF210_CSCUBS";
					$monitors->{$monitor_name}->{variables}->{prefix}	= "unix_filesystem_local";
					$monitors->{$monitor_name}->{variables}->{subclass}	= "FILESYSTEM";
				}

				$monitors->{$monitor_name}->{observations}->{$monitor_name.'Major'} = {
					test_type => 'threshold',
					test_params => {
						arg0 => 'fvalue($facet)',
						upper => $t->{major}->{upper},
						lower => $t->{major}->{lower},
						inclusive => 'true',
					},
					severity => 3,
					trap_dest => 'PROD',
					message => 'Disk usage for %(alertkey)s has exceeded '.$t->{major}->{lower}.'%% (currently %(Facet.'.$facet.')s%%)',
				} if $t->{major}->{upper};

				$monitors->{$monitor_name}->{observations}->{$monitor_name.'Critical'} = {
					test_type => 'compare',
					test_params => {
						arg0 => 'fvalue($facet)',
						operator => 'ge',
						arg1 => $t->{critical}->{lower},
					},
					severity => 5,
					trap_dest => 'PROD',
					message => 'Disk usage for %(alertkey)s has exceeded '.$t->{critical}->{lower}.'%% (currently %(Facet.'.$facet.')s%%)',
				} if $t->{critical}->{lower};

				if ($t->{warning}->{lower} < $t->{critical}->{lower}) {
					$clear_thres = $t->{warning}->{lower};
				} else {
					$clear_thres = $t->{critical}->{lower};
				}

				$monitors->{$monitor_name}->{observations}->{$monitor_name.'Clear'} = {
					test_type => 'compare',
					test_params => {
						arg0 => "fvalue($facet)",
						operator => 'lt',
						arg1 => $clear_thres,
					},
					severity => 1,
					trap_dest => 'PROD',
					message => 'Disk usage for %(alertkey)s has dropped below '.$clear_thres.'%% (currently %(Facet.'.$facet.')s%%)',
				} if $clear_thres;

				# Has a suppression been defined for each observation?
				if ($t->{major}->{trigger} == 1) {
					$monitors->{$monitor_name}->{observations}->{$monitor_name.'Major'}->{Suppression} = {
						numberOfTimes => $t->{major}->{trigger_delay},
						repeat => 0,
					};
				}
				if ($t->{critical}->{trigger} == 1) {
					$monitors->{$monitor_name}->{observations}->{$monitor_name.'Critical'}->{Suppression} = {
						numberOfTimes => $t->{critical}->{trigger_delay},
						repeat => 0,
					};
				}

			} elsif ($metric_type eq 'SWAP') {
				# Swap Usage monitor
				$monitor_name = "swapUsage";
				$monitors->{$monitor_name}->{type} = 'agent.mem.swapUsage';
				$monitors->{$monitor_name}->{periodicity} = 60 + (int(60 * rand()));
				$monitors->{$monitor_name}->{variables}->{alertkey}	= 'Summary-CEF210_CSCUBS';
				$monitors->{$monitor_name}->{variables}->{object}		= 'Summary';
				$monitors->{$monitor_name}->{variables}->{subclass}	= 'SWAP';

				if ($monitor_facet eq 'SWPTotSwapFreeSpace') {
					$facet = 'bytesFree';
				} elsif ($monitor_facet eq 'SWPTotSwapSize') {
					$facet = 'bytesTotal';
				} elsif ($monitor_facet eq 'SWPTotSwapUsedPercent') {
					$facet = 'percentUsed';
				} else {
					$facet = 'percentUsed';	# Default to % used
				}

				$monitors->{$monitor_name}->{observations}->{$monitor_name.'Major'} = {
					test_type => 'threshold',
					test_params => {
						arg0 => "fvalue($facet)",
						upper => $t->{major}->{upper},
						lower => $t->{major}->{lower},
						inclusive => 'true',
					},
					severity => 3,
					trap_dest => 'PROD',
					message => 'Total swap usage has exceeded '.$t->{major}->{lower}.'%% (currently %(Facet.'.$facet.')s%%)',
				} if $t->{major}->{upper};

				$monitors->{$monitor_name}->{observations}->{$monitor_name.'Critical'} = {
					test_type => 'compare',
					test_params => {
						arg0 => "fvalue($facet)",
						operator => 'ge',
						arg1 => $t->{critical}->{lower},
					},
					severity => 5,
					trap_dest => 'PROD',
					message => 'Total swap usage has exceeded '.$t->{critical}->{lower}.'%% (currently %(Facet.'.$facet.')s%%)',
				} if $t->{critical}->{upper};

				# Determine which threshold to use as the clear
				if ($t->{major}->{lower} < $t->{critical}->{lower}) {
					$clear_thres = $t->{major}->{lower};
				} else {
					$clear_thres = $t->{critical}->{lower};
				}

				# If no clear is defined, see what's available
				if (!$clear_thres) {
					if ($t->{major}->{enable}) {
						$clear_thres = $t->{major}->{lower};
					} elsif ($t->{critical}->{enable}) {
						$clear_thres = $t->{critical}->{lower};
					}
				}

				$monitors->{$monitor_name}->{observations}->{$monitor_name.'Clear'} = {
					test_type => 'compare',
					test_params => {
						arg0 => "fvalue($facet)",
						operator => 'lt',
						arg1 => $clear_thres,
					},
					severity => 1,
					trap_dest => 'PROD',
					message => 'Total swap usage has dropped below '.$clear_thres.'%% (currently %(Facet.'.$facet.')s%%)',
				};

				# Has a suppression been defined for each observation?
				if ($t->{major}->{trigger} == 1) {
					$monitors->{$monitor_name}->{observations}->{$monitor_name.'Major'}->{Suppression} = {
						numberOfTimes => $t->{major}->{trigger_delay},
						repeat => 0,
					};
				}
				if ($t->{critical}->{trigger} == 1) {
					$monitors->{$monitor_name}->{observations}->{$monitor_name.'Critical'}->{Suppression} = {
						numberOfTimes => $t->{critical}->{trigger_delay},
						repeat => 0,
					};
				}
			} elsif ($metric_type eq 'MEMORY') {
				print "[INFO] Memory monitor conversion is not available, please create a manifest manually\n";
				$monitors->{$monitor_name}->{variables}->{subclass}	= 'MEMORY';

			} elsif ($metric_type eq 'CPU') {
				# CPU Usage monitor
				
				my ($message_prefix, $obs_reference);

				if ($monitor_facet eq 'CPUCpuUtil') {
					$facet		= 'percentTotal';
					$message_prefix	= 'Total CPU usage ';
					$obs_reference	= 'TotalCpuUsage';
				} elsif ($monitor_facet eq 'CPUIdleTime') {
					$facet		= 'percentIdle';
					$message_prefix	= 'Idle CPU usage ';
					$obs_reference	= 'IdleCpuUsage';
				} elsif ($monitor_facet eq 'CPUSysTime') {
					$facet		= 'percentSys';
					$message_prefix	= 'System CPU usage ';
					$obs_reference	= 'SysCpuUsage';
				} elsif ($monitor_facet eq 'CPUUserTime') {
					$facet		= 'percentUser';
					$message_prefix	= 'User CPU usage ';
					$obs_reference	= 'UserCpuUsage';
				} else {
					$facet		= 'percentTotal';	# Default to % used
					$message_prefix	= 'Total CPU usage ';
					$obs_reference	= 'UserCpuUsage';
					print "[WARN] CPU metric '$monitor_facet' not support, defaulting to Total % Used\n";
				}

				$monitors->{$monitor_name}->{type}				= 'agent.cpu.cpuUsage';
				$monitors->{$monitor_name}->{periodicity}			= 60 + (int(60 * rand()));
				$monitors->{$monitor_name}->{variables}->{alertkey}	= 'CPU-CEF210_CSCUBS';
				$monitors->{$monitor_name}->{variables}->{subclass}	= 'CPU';

				$monitors->{$monitor_name}->{observations}->{$obs_reference.'Major'} = {
					test_type => 'threshold',
					test_params => {
						arg0 => "fvalue($facet)",
						upper => $t->{major}->{upper},
						lower => $t->{major}->{lower},
						inclusive => 'true',
					},
					severity => 3,
					trap_dest => 'PROD',
					message => $message_prefix.'has exceeded '.$t->{major}->{lower}.'%% (currently %(Facet.'.$facet.')s%%)',
				} if $t->{major}->{upper};

				$monitors->{$monitor_name}->{observations}->{$obs_reference.'Critical'} = {
					test_type => 'compare',
					test_params => {
						arg0 => "fvalue($facet)",
						operator => 'ge',
						arg1 => $t->{critical}->{lower},
					},
					severity => 5,
					trap_dest => 'PROD',
					message => $message_prefix.'has exceeded '.$t->{critical}->{lower}.'%% (currently %(Facet.'.$facet.')s%%)',
				} if $t->{critical}->{upper};

				# Determine which threshold to use as the clear
				if ($t->{major}->{lower} < $t->{critical}->{lower}) {
					$clear_thres = $t->{major}->{lower};
				} else {
					$clear_thres = $t->{critical}->{lower};
				}

				# If no clear is defined, see what's available
				if (!$clear_thres) {
					if ($t->{major}->{enable}) {
						$clear_thres = $t->{major}->{lower};
					} elsif ($t->{critical}->{enable}) {
						$clear_thres = $t->{critical}->{lower};
					}
				}

				$monitors->{$monitor_name}->{observations}->{$obs_reference.'Clear'} = {
					test_type => 'compare',
					test_params => {
						arg0 => "fvalue($facet)",
						operator => 'lt',
						arg1 => $clear_thres,
					},
					severity => 1,
					trap_dest => 'PROD',
					message => $message_prefix.'has dropped below '.$clear_thres.'%% (currently %(Facet.'.$facet.')s%%)',
				};

				# Has a suppression been defined for each observation?
				if ($t->{major}->{trigger} == 1) {
					$monitors->{$monitor_name}->{observations}->{$obs_reference.'Major'}->{Suppression} = {
						numberOfTimes => $t->{major}->{trigger_delay},
						repeat => 0,
					};
				}
				if ($t->{critical}->{trigger} == 1) {
					$monitors->{$monitor_name}->{observations}->{$obs_reference.'Critical'}->{Suppression} = {
						numberOfTimes => $t->{critical}->{trigger_delay},
						repeat => 0,
					};
				}

			} elsif ($metric_type eq 'PROCPRES') {
				$monitors->{$monitor_name}->{variables}->{alertgroup}	= "$metric_type-$monitor_facet-PEM";
				$monitors->{$monitor_name}->{variables}->{parameter}	= $monitor_facet;
				$monitors->{$monitor_name}->{variables}->{alertkey}	= "$monitor_name-CEF210_CSCUBS";
				$monitors->{$monitor_name}->{variables}->{object}	= $monitor_name;
				$monitors->{$monitor_name}->{variables}->{subclass}	= "PROCPRES";
								
				if ($monitor_facet eq 'PROCPPCount') {
					# This is a process count based monitor - set up accordingly
					$monitors->{$monitor_name}->{type} = 'agent.mon.multiProcessMonitor';				
					
					# Process the critical (alarm) alarms
					if ($t->{critical}->{enable} and $t->{critical}->{trigger}) {
						# Send event immediately
						$monitors->{$monitor_name}->{observations}->{$monitor_name.'Critical'} = {
							severity => 5,
							trap_dest => 'PROD',
							message => 'Currently there are %(Facet.count)s %(Parameter.regex)s running',
							test_type => 'false',
							test_params => {
								arg0 => 'fvalue(count)',
							},
							Suppression => {
								numberOfTimes => $t->{critical}->{trigger_delay},
								repeat => -1,
							},
						};	
					}
					
					# Process the warning alarm
					if ($t->{major}->{enable} and $t->{major}->{trigger}) {
						# Send event immediately
						$monitors->{$monitor_name}->{observations}->{$monitor_name.'Warning'} = {
							severity => 5,
							trap_dest => 'PROD',
							message => 'Currently there are %(Facet.count)s %(Parameter.regex)s running',
							test_type => 'false',
							test_params => {
								arg0 => 'fvalue(count)',
							},
							Suppression => {
								numberOfTimes => $t->{major}->{trigger_delay},
								repeat => -1,
							},
						};	
					}

					# Process the border range alarms
					if ($t->{border}->{enable} and $t->{border}->{trigger}) {
						
						if ($t->{border}->{alertstate} == 2) {
							$severity = 5;
						} elsif ($t->{border}->{alertstate} == 1) {
							$severity = 3;
						} elsif ($t->{border}->{alertstate} == 0) {
							$severity = 1;
						}
						
						# If the border range is 1-100, then is count = true or false (ie alarm at 0 count)
						if ($t->{border}->{upper} == 100 and $t->{border}->{lower} == 1 ) { 
							# Send event immediately
							$monitors->{$monitor_name}->{observations}->{$monitor_name.'Up'} = {
								severity => 1,
								trap_dest => 'PROD',
								message => 'Currently there are %(Facet.count)s %(Parameter.regex)s running',
								test_type => 'true',
								test_params => {
									arg0 => 'fvalue(count)',
								},
							};
							$monitors->{$monitor_name}->{observations}->{$monitor_name.'Down'} = {
								severity => $severity,
								trap_dest => 'PROD',
								message => 'Currently there are %(Facet.count)s %(Parameter.regex)s running',
								test_type => 'false',
								test_params => {
									arg0 => 'fvalue(count)',
								},
								Suppression => {
									numberOfTimes => $t->{border}->{trigger_delay},
									repeat => -1,
								},
							};							
						} else {
							# Send event immediately
							$monitors->{$monitor_name}->{observations}->{$monitor_name.'Border'} = {
								severity => $severity,
								trap_dest => 'PROD',
								message => 'Currently there are %(Facet.count)s %(Parameter.regex)s running',
								test_type => 'threshold',
								test_params => {
									arg0 => 'fvalue(count)',
									upper => $t->{border}->{upper},
									lower => $t->{border}->{lower},
									inclusive => 'false',
								},
								Suppression => {
									numberOfTimes => $t->{border}->{trigger_delay},
									repeat => -1,
								},
							};
						}
					}
					
				} else {
					# The PROCPRES rows determine what test type we need to use
					# Warn if no regex definition is found (it's already been created normally)
					if (!$monitors->{$monitor_name}) {
						print "[ERROR] No regex found for this monitor: $monitor_name, skipping\n";
						next;
					}

					$monitor_name = $monitor_name;

					# If we don't see a major or critical alarm, enable the major alert
					unless ($t->{major}->{enable} or $t->{critical}->{enable}) {
						$t->{major}->{enable} = 1;
					}

					if ($t->{major}->{enable}) {
						$monitors->{$monitor_name}->{observations}->{$monitor_name.'Major'} = {
							severity => 3,
							trap_dest => 'PROD',
							message => 'Process '.$monitor_name.' is dead',
						};
						if ($t->{major}->{trigger} == 0) {
							# Send event immediately
							$monitors->{$monitor_name}->{observations}->{$monitor_name.'Major'}->{test_type} = 'processDown';
						} elsif ($t->{major}->{trigger} == 1) {
							# Send event 5 consecutive dead intervals
							$monitors->{$monitor_name}->{observations}->{$monitor_name.'Major'}->{test_type} = 'processDead';
						} else {
							print "ERROR: Trigger state '".$t->{major}->{trigger}."' not supported\n";
						}
					}

					if ($t->{critical}->{enable}) {
						$monitors->{$monitor_name}->{observations}->{$monitor_name.'Critical'} = {
							severity => 5,
							trap_dest => 'PROD',
							message => 'Process '.$monitor_name.' is dead',
						};
						if ($t->{critical}->{trigger} == 0) {
							# Send event immediately
							$monitors->{$monitor_name}->{observations}->{$monitor_name.'Critical'}->{test_type} = 'processDown';
						} elsif ($t->{critical}->{trigger} == 1) {
							# Send event 5 consecutive dead intervals
							$monitors->{$monitor_name}->{observations}->{$monitor_name.'Critical'}->{test_type} = 'processDead';
						} else {
							print "ERROR: Trigger state '".$t->{critical}->{trigger}."' not supported\n";
						}
					}

					# Always create a process up observation so the alert clears down
					$monitors->{$monitor_name}->{observations}->{$monitor_name.'Clear'} = {
						severity => 1,
						trap_dest => 'PROD',
						message => 'Process '.$monitor_name.' is alive',
						test_type => 'processUp'
					};
				}

			} else {
				$monitor_name = $metric_type.$monitor_name;
				print "[ERROR] Unknown monitor type: $metric_type\n";
			}

			# Add in the AlertGroup from the Object Class (if not set already)
			$monitors->{$monitor_name}->{variables}->{alertgroup} = $metric_type unless $monitors->{$monitor_name}->{variables}->{alertgroup};
		} elsif ($line =~ m!/AgentSetup/FILESYSTEM.filterList!) {		
			print "[FS] '$line'\n" if $opts->{d};
			
			my $mount_point;
			
			# Filesystem to monitor and it's reference name
			# "/AgentSetup/FILESYSTEM.filterList" = { MERGE = "<ref name>,<mount point>" },
			if ($line !~ /MERGE/) {
				## Unknown FS monitor definition

			} else {
				$line =~ m!^.+{.+MERGE = "(.+),(.+)".*$!;

				$monitor_name	= $1."Fs";
				$mount_point	= $2;
				$monitors->{$monitor_name}->{type} = 'agent.disk.diskUsage';
				$monitors->{$monitor_name}->{periodicity} = 150 + (int(150 * rand()));
				$monitors->{$monitor_name}->{parameters}->{device} = $mount_point;
			}

		} elsif ($line =~ m!/PUK/PROCPRES/! or $line =~ m!/UNIX/PROCPRES/!) {
			print "[PROC] $line\n" if $opts->{d};
			next if $line =~ /DELETE/;	# DELETE commands are not needed

			# This row defines the process to monitor and associates this to a monitor name
			# "/PUK/PROCPRES/<monitor reference>/info" = { REPLACE = "<monitor reference><regex><settings string>" },
			my ($cmd_str, $process_regex, undef) = split '\002+', $line;
			
			if (!$process_regex) {	# Process definition not split on \002 char, try *
				($cmd_str, $process_regex, undef) = split '\*', $line;
			}

			$cmd_str =~ m!^"/[A-Z]+/PROCPRES/(.+)/info" = { REPLACE = .*$!;
			my $process_reference = $1;

			$monitors->{$process_reference}->{type}				= 'agent.mon.processMonitor';
			$monitors->{$process_reference}->{periodicity}			= 60 + (int(60 * rand()));
			$monitors->{$process_reference}->{variables}->{prefix}		= 'unix_process';

			$monitors->{$process_reference}->{variables}->{alertgroup}	= "Process";
			$monitors->{$process_reference}->{variables}->{parameter}	= "PROCPPCount";
			$monitors->{$process_reference}->{variables}->{alertkey}	= $process_reference;
			$monitors->{$process_reference}->{variables}->{object}		= $process_reference;
			$monitors->{$process_reference}->{variables}->{subclass}	= "PROCESS";

			$monitors->{$process_reference}->{parameters}->{regex}		= $process_regex;

#		} else {
#			print "[UNK] '".$line."'\n";
		}
	}

	# Start writing the fragment
	my $doc = XML::LibXML::Document->new();

	my $Fragment	= $doc->createElement('Fragment');
	$doc->setDocumentElement($Fragment);
	
	my $Header	= $doc->createComment( " \$Id\$ " );
	
	my $Component	= $doc->createElement('Component');
	$Component->setAttribute('name', $componentname);
	$Component->setAttribute('type', 'GENERIC_EMPTY');
	
	$Fragment->appendChild($Header);
	$Fragment->appendChild($Component);

	my $monitor_index = 1;

	# Skip to the next if there is nothing to do
	unless (keys %{$monitors}) {
		print "[INFO] No monitoring found (or unknown monitoring)\n";
		next;
	}

	foreach my $item ( sort keys (%{$monitors}) ) {
		# Skip monitors if something is wrong or incomplete
		# If the name is blank, go to the next monitor
		next unless $item;
		next unless $monitors->{$item}->{type};

		# Fix any oddities
		if ($monitors->{$item}->{type} eq 'agent.mon.osCmd') {
			$monitors->{$item}->{parameters}->{command} = $monitors->{$item}->{parameters}->{path};
			$monitors->{$item}->{observations}->{$item.'obs'}->{test_params}->{regex} =
				$monitors->{$item}->{parameters}->{regex};

			delete $monitors->{$item}->{parameters}->{path};
			delete $monitors->{$item}->{parameters}->{regex};
			delete $monitors->{$item}->{template};
		} elsif ($monitors->{$item}->{type} eq 'agent.mon.logMonitor') {
			$monitors->{$item}->{observations}->{$item.'obs'}->{message} = '%(Facet.occurrence)s found in '.$monitors->{$item}->{parameters}->{path};
			if ($monitors->{$item}->{parameters}->{path} eq '/var/adm/messages') {
				$monitors->{$item}->{variables}->{prefix} = 'syslog';
			} else {
				$monitors->{$item}->{variables}->{prefix} = 'app_logfile';
			}
		} elsif ($monitors->{$item}->{type} eq 'agent.mon.processMonitor') {
			# Check to see if we have any observations for this monitor, if not add some basic processUp/Down ones
			unless ($monitors->{$item}->{observations}) {
				my $process_regex = $monitors->{$item}->{parameter}->{regex};
				print "[INFO] No observations defined for '$item' process monitoring\n";
				$monitors->{$item}->{observations}->{$item.'Clear'} = {
					severity => 1,
					trap_dest => 'PROD',
					message => 'The process '.$item.' is in a clear state',
					test_type => 'processUp'
				};
				$monitors->{$item}->{observations}->{$item.'Down'} = {
					severity => 5,
					trap_dest => 'PROD',
					message => 'The process '.$item.' is in an alarm state',
					test_type => 'processDown'
				};
			}
		}

		my $Monitor = $doc->createElement('Monitor');
		$Monitor->setAttribute('name', $item);
		$Monitor->setAttribute('type', $monitors->{$item}->{type});
		$Monitor->setAttribute('periodicity', $monitors->{$item}->{periodicity});

		my $monitor_type = $doc->createElement('Variable');
		$monitor_type->setAttribute('name', 'monitor');
		$monitor_type->appendText($monitors->{$item}->{type});
		$Monitor->appendChild($monitor_type);
		
		my $variables = $monitors->{$item}->{variables};
		my $parameters = $monitors->{$item}->{parameters};

		foreach my $variable (keys (%{$variables}) ) {
			next unless $variables->{$variable};
			my $Var = $doc->createElement('Variable');
			$Var->setAttribute('name', $variable);
			$Var->appendText($variables->{$variable});
			$Monitor->appendChild($Var);
		}

		# Add the template for this log monitor
		if ($monitors->{$item}->{template}) {
			my $template = $doc->createElement('Parameter');
			$template->setAttribute('name', 'template');
			$template->appendText($monitors->{$item}->{template});
			$Monitor->appendChild($template);

			my $regex = $doc->createElement('Parameter');
			$regex->setAttribute('name', 'regex');
			$regex->appendText('(.*'.$monitors->{$item}->{parameters}->{regex}.'.*)');
			$Monitor->appendChild($regex);
			
			delete $monitors->{$item}->{parameters}->{regex};
		}

		foreach my $param (keys (%{$parameters}) ) {
			my $Parameter = $doc->createElement('Parameter');
			$Parameter->setAttribute('name', $param);
			$Parameter->appendText($parameters->{$param});
			$Monitor->appendChild($Parameter);
		}

		# Write an observation for this monitor
		my $observations = $monitors->{$item}->{observations};
		foreach my $obs ( sort keys (%{$observations}) ) {
			
			# All observations must have a test type
			next unless $observations->{$obs}->{test_type};
		
			$observations->{$obs}->{severity} = $monitors->{$item}->{severity}
				unless ($observations->{$obs}->{severity});

			my $Observation = $doc->createElement('Observation');
			$Observation->setAttribute('name', $obs);
			my $Test;
			
			if ($observations->{$obs}->{test_type} eq 'true') {
				$Test = $doc->createElement('Test');
				$Test->setAttribute('type', $observations->{$obs}->{test_type});
				
				# Don't add the edge attribute to log monitors since these should always fire
				$Test->setAttribute('edge', 'up') if $monitors->{$item}->{type} ne 'agent.mon.logMonitor';
			} else {
				$Test = $doc->createElement('Test');
				$Test->setAttribute('type', $observations->{$obs}->{test_type});
			}

			foreach my $obs_param (keys (%{$observations->{$obs}->{test_params}}) ) {
				my $Param = $doc->createElement('Parameter');
				$Param->setAttribute('name', $obs_param);
				$Param->appendText($observations->{$obs}->{test_params}->{$obs_param});

				$Test->appendChild($Param);
			}

			# Add a suppression if one has been defined
			if ($observations->{$obs}->{Suppression}) {
				my $Suppression = $doc->createElement('Suppression');
				$Suppression->setAttribute('numberOfTimes', $observations->{$obs}->{Suppression}->{numberOfTimes});
				$Suppression->setAttribute('repeat', $observations->{$obs}->{Suppression}->{repeat});

				$Observation->appendChild($Suppression);
			}

			my $Message = $doc->createElement('Message');
			$Message->appendText($observations->{$obs}->{message});

			$Observation->appendChild($Test);
			$Observation->appendChild($Message);

			if ($observations->{$obs}->{severity}) {
				if ($observations->{$obs}->{trap_dest} =~ /DEV/) {
					$Observation->appendChild(WriteTrap($doc, 'dev-events', $observations->{$obs}->{severity}));
				} else {
					$Observation->appendChild(WriteTrap($doc, 'pri-events', $observations->{$obs}->{severity}));
					$Observation->appendChild(WriteTrap($doc, 'fail-events', $observations->{$obs}->{severity}));
				}
			}

			$Monitor->appendChild($Observation);
		}

		$Component->appendChild($Monitor);
		$monitor_index++;
	}

	# Write out the file
	print "Output file: $output_directory/$output_file\n";
	open XML, '>', "$output_directory/$output_file";
	
	my $xml_doc = $doc->toString(1);
	$xml_doc =~ s!<\?xml version="1.0"\?>\n!!g;	# Remove the XML header

	print XML $xml_doc;
	close XML;
	print "\n";
	
	# All done - clear $monitors ready for the next file
	$monitors = {};
}

exit;

sub logObservation {
	my ($dom, $obs_name, $severity) = @_;

	my $Observation = $dom->createElement('Observation');
	$Observation->setAttribute('name', $obs_name);
	
	my $Test = $dom->createElement('Test');
	$Test->setAttribute('type', 'true');
	
	my $test_parameter = $dom->createElement('Parameter');
	$test_parameter->setAttribute('name', 'arg0');

	my $Message = $dom->createElement('Message');
	$Message->appendText('%(Facet.occurrence)s');

	$test_parameter->appendText('$occurrence');
	$Test->appendChild($test_parameter);
	$Observation->appendChild($Test);
	$Observation->appendChild($Message);

	if ($severity > 0) {
		$Observation->appendChild(WriteTrap($dom, 'pri-events', $severity));
		$Observation->appendChild(WriteTrap($dom, 'fail-events', $severity));
	}

	return $Observation;
}

sub WriteTrap {
	my ($dom, $target, $severity) = @_;
	my $Trap = $dom->createElement('Trap');
	$Trap->setAttribute('name', $target);
	if ($severity) {
		my $oid = $dom->createElement('Parameter');
		$oid->setAttribute('index', '8');
		$oid->setAttribute('name', 'object');
		$oid->appendText('.1.3.6.1.4.1.10982.0.200.8;s;'.$severity);
		$Trap->appendChild($oid);
	}
	return $Trap;
}

