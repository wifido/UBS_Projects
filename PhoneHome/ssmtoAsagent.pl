#!/sbcimp/run/pd/perl/5.8.8/bin/perl
# $Id: ssmtoAsagent.pl 882 2010-04-28 10:11:33Z harperri $
# $URL: https://ims-svn.swissbank.com/prod-kerb/AGENTENG/trunk/asagent/migration/ssmtoAsagent.pl $

use lib "/sbcimp/run/pd/cpan/5.8.8-2006.03/lib";

use XML::Element;
use Data::Dumper;
use File::Basename;
use Getopt::Std;

getopts('do:');
my $output_directory = $opt_o;

my @config;
my @directors;

my $event_dir = {
	'description' => '',
	'type' => '',
	'community' => '',
	'refname' => '',
};

my $logmonitor = {
	'logfile' => '',
	'filter' => '',
	'begindelimiter' => '',
	'enddelimiter' => '',
	'updateinterval' => '',
	'displaylimit' => '',
	'windowsize' => '',
	'event' => '',
	'eventstatus' => '',
	'description' => '',
	'defaultlevel' => '',
	'mode' => '',
	'datacontrol' => '',
	'reversefilter' => '',
	'rolledfile' => '',
};

my $procmonitor = {
	'description' => '',
	'filtertype' => '',
	'filter' => '',
	'interval' => '',
	'sampletype' => '',
	'attr' => '',
	'oper' => '',
	'thresh' => '',
	'actioncmd' => '',
	'actionevent' => '',
	'actioneventstatus' => '',
	'actionthresh' => '',
	'buckets' => '',
	'datacontrol' => '',
	'trapmask' => ''
};

my $genalarm = {
	'var' => '',
	'vardescr' => '',
	'interval' => '',
	'type' => '',
	'startup' => '',
	'mode' => '',
	'risethresh' => '',
	'fallthresh' => '',
	'riseduration' => '',
	'fallduration' => '',
	'riseevent' => '',
	'fallevent' => '',
	'riseseverity' => '',
	'fallseverity' => '',
	'risedescr' => '',
	'falldescr' => '',
	'matchvalue' => '',
	'matchduration' => '',
	'matchevent' => '',
	'matchseverity' => '',
	'matchdescr' => '',
	'datacontrol' => '',
	'varbinds' => [],
};

my $genalarm_severities = {
	'critical' => 5,
	'severe' => 4,
	'warning' => 3,
	'info' => 1,
};

my $ranges = {};

my ($process_flag, $snmp_match, $current_var, $filename) = undef;

for my $input (@ARGV) {

	open (CFG, $input);
	$filename = $input;
	my ($this_monitor, $events);
	my $i = 0;

	print "IN FILE: $input\n";

	my $ssm_configuration = {};

	# Use the filename as the component name
	my ($component_name, undef) = split '\.', basename($input);
	my $outfile = $component_name.'.xml';

	while (<CFG>) {
		chomp;
		my $line = $_;
		next if ($line =~ /^\#/ or $line eq '');
		$line =~ s/\r//g;	# Remove DOS line returns


		my ($subagent, @cmd) = split '\s+', $line;
		$command = join(' ', @cmd);
		next if ($subagent eq 'echo' or $subagent eq 'agenttrapdest');

		if ($command =~ /reset/) {
			if ($line =~ /^process/) {
				# Get a new copy of the template
				$this_monitor = $procmonitor;
			} elsif ($line =~ /^logmon/) {
				$this_monitor = $logmonitor;
			} elsif ($line =~ /^event/) {
				$this_monitor = $event_dir;
			} elsif ($line =~ /^genalarm/) {
				$this_monitor = $genalarm;
			}

		} elsif ($command =~ /create/) {
			# What are we creating?

			# Does this line have commands in as well?
			unless ($line =~ /^.*create$/) {
				# Remove the create
				$line =~ s/create //gi;

				($subagent, @cmd) = split '\s+', $line;
				$command = join(' ', @cmd);

				# Process the line
				($param, $value) = split '=', $command;
				$value =~ s/\"|\'//g;
				$param =~ /([a-z]+)/;	# Extract only the words out of the command (key)
				$this_monitor->{lc($1)} = trim($value);	# Trim any whitespace from the value
			}

			# Now do the create
			if ($line =~ /^logmon/) {
				$ssm_configuration->{'logmon'.$i} = write_logmon($this_monitor, $i);
			} elsif ($line =~ /^process/) {
				my $monitor_reference = $this_monitor->{filter};
				$monitor_reference =~ s/[\.\*\+]+/_/g;
				$ssm_configuration->{$monitor_reference} = write_procmon($this_monitor, $ssm_configuration->{$monitor_reference}, $i);
			} elsif ($line =~ /^genalarm/) {
				$ssm_configuration->{$this_monitor->{var}} = write_genalarm($this_monitor, $ssm_configuration->{$this_monitor->{var}}, $i);
			}
			$i++;
		} else {
			if ($subagent =~ /\$\?/) {
				($param, $value) = split '=', $subagent;
				$value =~ s/\"|\'//g;
				$this_monitor->{'refname'} = $param;

				add_to_directors($this_monitor);
			} elsif ($subagent eq 'snmp') {
				$line =~ /^snmp match.+"(.+)"$/;
				$this_monitor->{snmp_match} = $1;
			} elsif ($subagent =~ genalarmvb) {
				(undef, $value) = split '=', $command;
				$value =~ s/\"|\'//g;
				push @{ $this_monitor->{'varbinds'} }, $value;
			} else {
				($param, $value) = split '=', $command;
				$value =~ s/\"|\'//g;
				$param =~ /([a-z]+)/;	# Extract only the words out of the command (key)
				$this_monitor->{lc($1)} = trim($value);	# Trim any whitespace from the value
			}
		}
	}

	close CFG;

	my $new_fragment = WriteFragment($ssm_configuration, $component_name);

	print "OUT FILE: ".$output_directory.$component_name.".xml\n";
	open OUT, ">".$output_directory.$component_name.".xml";

	print OUT $new_fragment->as_HTML();

	close OUT;
}

# BEGIN subs

sub add_to_directors() {
	my $in = shift;
	if (defined($in->{community})) {
		$directors->{'$'.$in->{refname}} = $in->{community};
	}
}

sub write_logmon() {
	my $in = shift;
	my $count = shift;

	my $monitor = {};

	$monitor->{type} = 'agent.mon.logMonitor';
	# Split up the description field
	my ($prefix, $class, $subclass, $systemdesig, $alertgroup) = split ':', $in->{description};
	$monitor->{variables} = {
		class => $class,
		subclass => $subclass,
		alertgroup => $alertgroup,
		alertkey => $in->{logfile},
		sysdesig => $systemdesig,
	};

	$monitor->{periodicity} = $in->{updateinterval};
	$monitor->{name} = "logmon".$count;

	$monitor->{parameters} = {
		regex => $in->{filter},
		samplePerMatch => 'true',
	};

	$prefix =~ /[a-z_]+_([0-9]+)/;
	my $sev = $1;

	$sev = 3 unless $sev;

	my $path_match_function = undef;

	if ($in->{logfile} =~ /[\*\+\[\]\-]+/) {
		$path_match_function = "pathregex";
	} else {
		$path_match_function = "path";
	}

	$monitor->{parameters}->{$path_match_function} = $in->{logfile};

	$monitor->{observations}->{$monitor->{name}.'-obs'} = {
		test_type => 'true',
		test_params => {
			arg0 => 'fvalue(occurrence)',
		},
		message => '%(Facet.occurrence)s',
		severity => $sev,
		trap_dest => $directors->{$in->{event}},
	};

	return $monitor;
}

sub write_procmon() {
	my $in = shift;
	my $monitor = shift;
	my $count = shift;

	$monitor->{type} = 'agent.mon.processMonitor';
	# Split up the description field
	my ($prefix, $class, $subclass, $systemdesig, $alertkey) = split ':', $in->{description};

	# AK = Process name, AG = 'Process' for app alerts, AG = 'Unix Process'
	$monitor->{variables} = {
		class => $class,
		subclass => $subclass,
		alertgroup => 'Process',
		alertkey => $alertkey,
		sysdesig => $systemdesig,
	};

	$monitor->{periodicity} = $in->{interval};
	$monitor->{name} = "procmon".$count;

	if ($in->{filtertype} eq 'commandOldest' or $in->{filtertype} eq 'nameOldest') {
		$filtertype = "cmdOldest";
	} elsif ($in->{filtertype} eq 'groupLeaderCommand' or $in->{filtertype} eq 'groupLeaderName') {
		$filtertype = "groupLeader";
	}

	$monitor->{parameters}->{regex} = $in->{filter};
	$monitor->{parameters}->{$filtertype} = 'true' if ($filtertype);

	$prefix =~ /[a-z_]+_([0-9]+)/;
	my $sev = $1;
	$sev = 3 unless $sev;

	my ($test_parameter) = undef;
	my ($Test, $Message) = undef;

	if ($in->{attr} eq 'alive') {
		if ($in->{thresh} == 1) {
			$monitor->{observations}->{'procUp'.$count} = {
				test_type => 'processUp',
				message => 'Process %(Facet.executable)s is alive',
				severity => 1,
				trap_dest => $directors->{$in->{actionevent}},
			};

		} elsif ($in->{thresh} == -1) {
			$monitor->{observations}->{'procDead'.$count} = {
				test_type => 'processDown',
				message => 'Process %(Facet.executable)s is dead',
				severity => $sev,
				trap_dest => $directors->{$in->{actionevent}},
			};

		} elsif ($in->{thresh} == 0) {
			$monitor->{observations}->{'procDown'.$count} = {
				test_type => 'processDead',
				message => 'Process %(Facet.executable)s is stopped',
				severity => $sev,
				trap_dest => $directors->{$in->{actionevent}},
			};

		}

	} elsif ($in->{attr} eq 'rss') {
		$in->{thresh} = $in->{thresh} * 1024;
		$monitor->{observations}->{'rss'.$count} = {
			test_type => 'compare',
			test_params => {
				arg0 => 'fvalue(residentSize)',
				operator => $in->{oper},
				arg1 => $in->{thresh},
			},
			message => 'RSS memory usage for %(Facet.executable)s has exceeded '.readableNumbers($in->{thresh}),
			severity => $sev,
			trap_dest => $directors->{$in->{actionevent}},
		};

	} elsif ($in->{attr} eq 'size') {
		$in->{thresh} = $in->{thresh} * 1024;
		$monitor->{observations}->{'virtualsize'.$count} = {
			test_type => 'compare',
			test_params => {
				arg0 => 'fvalue(virtualSize)',
				operator => $in->{oper},
				arg1 => $in->{thresh},
			},
			message => 'Virtual memory usage for %(Facet.executable)s has exceeded '.readableNumbers($in->{thresh}),
			severity => $sev,
			trap_dest => $directors->{$in->{actionevent}},
		};

	} elsif ($in->{attr} eq 'age') {
		$monitor->{observations}->{'age'.$count} = {
			test_type => 'compare',
			test_params => {
				arg0 => 'fvalue(sTime)',
				operator => $in->{oper},
				arg1 => $in->{thresh},
			},
			message => '%(Facet.executable)s',
			severity => $sev,
			trap_dest => $directors->{$in->{actionevent}},
		};

	} elsif ($in->{attr} eq 'totalTime') {
		$monitor->{observations}->{'cpuTime'.$count} = {
			test_type => 'compare',
			test_params => {
				arg0 => 'fvalue(time)',
				operator => $in->{oper},
				arg1 => $in->{thresh},
			},
			message => 'Total CPU usage for %(Facet.executable)s has exceeded '.readableNumbers($in->{thresh}),
			severity => $sev,
			trap_dest => $directors->{$in->{actionevent}},
		};

	} elsif ($in->{attr} eq 'averageCpu') {
		$monitor->{observations}->{'cpu'.$count} = {
			test_type => 'compare',
			test_params => {
				arg0 => 'fvalue(percentCpu)',
				operator => $in->{oper},
				arg1 => $in->{thresh},
			},
			message => 'Average CPU usage for %(Facet.executable)s is %(Facet.percentCpu)s%%',
			severity => $sev,
			trap_dest => $directors->{$in->{actionevent}},
		};
	}

	$process_flag = $in->{filter};

	return $monitor;
}

sub write_genalarm {
	my $in = shift;
	my $monitor = shift;
	my $count = shift;

	print Dumper($in) if $opt_d;

	$in->{var} =~ s/\$//g;
	$in->{var} =~ s/\./_/g;
	$monitor->{name} = $in->{var};

	# Replace bits of the summary:
	$in->{risedescr} =~ s/\$\$11/\'$in->{snmp_match}\'/g;
	$in->{risedescr} =~ s/\$\$7/$in->{risethresh}/g;
	$in->{risedescr} =~ s/\$\$6/\%(Facet._FACET_)s/g;

	$in->{falldescr} =~ s/\$\$11/\'$in->{snmp_match}\'/g;
	$in->{falldescr} =~ s/\$\$7/$in->{fallthresh}/g;
	$in->{falldescr} =~ s/\$\$6/\%(Facet._FACET_)s/g;

	$monitor->{periodicity} = $in->{interval};

	# Split up the description field
	my ($prefix, $class, $subclass, $systemdesig, $alertkey) = split ':', $in->{vardescr};
	$monitor->{variables} = {
		class => $class,
		subclass => $subclass,
		alertkey => $alertkey,
		alertgroup => $alertgroup,
		sysdesig => $systemdesig,
	};

	# What OID are we monitoring - this determines the monitor type we need
	if ($in->{var} =~ /srSystemCPUUsage/) {
		$monitor->{type} = "agent.cpu.cpuUsage";
		$monitor->{parameters}->{cpu} = '-1';
		$monitor->{observations}->{'srSystemCPUUsage'.$count.'-'.$in->{riseseverity}} = {
			test_type => 'compare',
			test_params => {
				arg0 => 'fvalue(percentTotal)',
				operator => 'ge',
				arg1 => $in->{risethresh},
			},
			trap_dest => $directors->{$in->{riseevent}},
			message => $in->{risedescr},
			severity => $genalarm_severities->{$in->{riseseverity}},
		};

		# If there is a falling threshold, add this to the observations
		if ($in->{fallthresh}) {
			$monitor->{observations}->{'srSystemCPUUsage'.$count.'-'.$in->{fallseverity}} = {
				test_type => 'compare',
				test_params => {
					arg0 => 'fvalue(percentTotal)',
					operator => 'le',
					arg1 => $in->{fallthresh},
				},
				trap_dest => $directors->{$in->{fallevent}},
				message => $in->{falldescr},
				severity => $genalarm_severities->{$in->{fallseverity}},
			};
		}

	} elsif ($in->{var} =~ /srSystemProcessCount/) {
		$monitor->{type} = "agent.mon.multiProcessMonitor";
		$monitor->{parameters}->{regex} = '.*';
		$monitor->{observations}->{'systemProcessCount'.$count} = {
			test_type => 'compare',
			test_params => {
				arg0 => 'fvalue(count)',
			},
			trap_dest => $directors->{$in->{riseevent}},
			message => $in->{risedescr},
			severity => $genalarm_severities->{$in->{riseseverity}},
		};
	} elsif ($in->{var} =~ /srSystemSwapPercentUsed/) {
		$monitor->{type} = "agent.mem.swapUsage";
		$in->{risedescr} =~ s/_FACET_/percentUsed/g;
		$in->{falldescr} =~ s/_FACET_/percentUsed/g;

		$monitor->{observations}->{'swapUsed'.$count} = {
			test_type => 'compare',
			test_params => {
				arg0 => 'fvalue(percentUsed)',
				operator => 'ge',
				arg1 => $in->{risethresh},
			},
			trap_dest => $directors->{$in->{riseevent}},
			message => $in->{risedescr},
			severity => $genalarm_severities->{$in->{riseseverity}},
		};

		# If there is a falling threshold, add this to the observations
		if ($in->{fallthresh}) {
			$monitor->{observations}->{'swapUsed'.$count.'-'.$in->{fallseverity}} = {
				test_type => 'compare',
				test_params => {
					arg0 => 'fvalue(percentUsed)',
					operator => 'le',
					arg1 => $in->{fallthresh},
				},
				trap_dest => $directors->{$in->{fallevent}},
				message => $in->{falldescr},
				severity => $genalarm_severities->{$in->{fallseverity}},
			};
		}

		$monitor->{variables}->{alertgroup} = 'Swap Usage';
	} elsif ($in->{var} =~ /hrSystemNumUsers/) {
		$monitor->{type}	= "agent.mon.osCmd";
		$monitor->{parameters}->{command} = "/usr/bin/uptime | awk -F, \'{print $3}\' | awk \'{print $1}\'";
		$monitor->{parameters}->{type} = 'int';
		$monitor->{observations}->{'hrSystemNumUsers'.$count} = {
			test_type => 'compare',
			test_params => {
				arg0 => 'fvalue(value)',
			},
			trap_dest => $directors->{$in->{riseevent}},
			message => $in->{risedescr},
			severity => $genalarm_severities->{$in->{riseseverity}},
		};

	} elsif ($in->{var} =~ /srStorageLogicalUsedPercent_([0-9]+)/) {
		$fsType = $1;
		if ($in->{snmp_match} eq 'Physical Memory') {
			$monitor->{type}	= "agent.mem.memUsage";
			$monitor->{variables}->{alertgroup} = 'Memory Usage';

		} else {
			$monitor->{type}	= "agent.disk.diskUsage";
			$monitor->{variables}->{alertgroup} = 'Disk Usage';
			$monitor->{parameters}->{device} = $in->{snmp_match};
			if ($fsType == 10) {
				$monitor->{parameters}->{local} = 'false';
			}
		}

		$in->{risedescr} =~ s/_FACET_/percentUsed/g;
		$in->{falldescr} =~ s/_FACET_/percentUsed/g;

		$monitor->{observations}->{'fsUsed'.$count} = {
			test_type => 'compare',
			test_params => {
				arg0 => 'fvalue(percentUsed)',
				operator => 'ge',
				arg1 => $in->{risethresh},
			},
			trap_dest => $directors->{$in->{riseevent}},
			message => $in->{risedescr},
			severity => $genalarm_severities->{$in->{riseseverity}},
		};

		# If there is a falling threshold, add this to the observations
		if ($in->{fallthresh}) {
			$monitor->{observations}->{'fsUsed'.$count.'-'.$in->{fallseverity}} = {
				test_type => 'compare',
				test_params => {
					arg0 => 'fvalue(percentUsed)',
					operator => 'le',
					arg1 => $in->{fallthresh},
				},
				trap_dest => $directors->{$in->{fallevent}},
				message => $in->{falldescr},
				severity => $genalarm_severities->{$in->{fallseverity}},
			};
		}

	} elsif ($in->{var} =~ /srStorageUsedMegabytes/) {
		if ($in->{snmp_match} eq 'Physical Memory') {
			$monitor->{type}	= "agent.mem.memUsage";
			$monitor->{variables}->{alertgroup} = 'Memory Usage';
		} else {
			$monitor->{type}	= "agent.disk.diskUsage";
			$monitor->{variables}->{alertgroup} = 'Disk Usage';
			$monitor->{parameters}->{device} = $in->{snmp_match};
		}

		$in->{risedescr} =~ s/_FACET_/bytesUsed/g;
		$in->{falldescr} =~ s/_FACET_/bytesUsed/g;

		$monitor->{observations}->{'fsUsed'.$count} = {
			test_type => 'compare',
			test_params => {
				arg0 => 'fvalue(bytesUsed)',
			},
			trap_dest => $directors->{$in->{riseevent}},
			message => $in->{risedescr},
			severity => $genalarm_severities->{$in->{riseseverity}},
		};

		# If there is a falling threshold, add this to the observations
		if ($in->{fallthresh}) {
			$monitor->{observations}->{'fsUsed'.$count.'-'.$in->{fallseverity}} = {
				test_type => 'compare',
				test_params => {
					arg0 => 'fvalue(bytesUsed)',
					operator => 'le',
					arg1 => $in->{fallthresh},
				},
				trap_dest => $directors->{$in->{fallevent}},
				message => $in->{falldescr},
				severity => $genalarm_severities->{$in->{fallseverity}},
			};
		}

	} else {
		print "Unknown monitor: $in->{var}\n";
		return;
	}

# Current unknown monitors
#	if ($in->{var} =~ /srDiskAccessTime/) {
#
#	} elsif ($in->{var} =~ /srDiskUtilization/) {
#
#	} elsif ($in->{var} =~ /srIfHostInUtilization/) {
#
#	} elsif ($in->{var} =~ /srIfHostOutUtilization/) {
#
#	} elsif ($in->{var} =~ /tcpActiveOpens/) {
#
#	} elsif ($in->{var} =~ /tcpPassiveOpens/) {
#
#	} elsif ($in->{var} =~ /tcpRetransSegs/) {
#
#	} elsif ($in->{var} =~ /udpNoPorts/) {
#
#	} elsif ($in->{var} =~ /ipForwDatagrams/) {
#
#	} elsif ($in->{var} =~ /srSystemContextSwitchCount/) {

	return $monitor;
}

sub WriteFragment {
	my $configuration = shift;
	my $name = shift;

	print Dumper($configuration) if $opt_d;

	my $Fragment	= XML::Element->new('Fragment');
	my $Component	= XML::Element->new('Component', 'name' => $name, 'type' => 'GENERIC_EMPTY');
	my $Header	= XML::Element->new('~comment', 'text' => "\$Id\$\n \$URL\$");

	$Fragment->push_content($Header);
	$Fragment->push_content($Component);

	# Variables common to this component
	foreach my $variable ( keys (%{$configuration->{common_variables}}) ) {
		my $Var = XML::Element->new('Variable', 'name' => $variable);
		$Var->push_content($configuration->{common_variables}->{$variable});
		$component->push_content($Var);
	}

	delete $configuration->{common_variables};

	foreach my $item ( keys (%{$configuration}) ) {
		my $Monitor = XML::Element->new('Monitor',
			'name' => $configuration->{$item}->{name},
			'type' => $configuration->{$item}->{type},
			'periodicity' => $configuration->{$item}->{periodicity}
		);

		my $variables = $configuration->{$item}->{variables};
		my $parameters = $configuration->{$item}->{parameters};

		foreach my $variable (keys (%{$variables}) ) {
			my $Var = XML::Element->new('Variable', 'name' => $variable);
			$Var->push_content($variables->{$variable});
			$Monitor->push_content($Var);
		}

		# Add the template for this log monitor
		if ($configuration->{$item}->{template}) {
			my $template = XML::Element->new('Parameter', 'name' => 'template');
			$template->push_content($configuration->{$item}->{template});
			$Monitor->push_content($template);

			my $regex = XML::Element->new('Parameter', 'name' => 'regex');
			$regex->push_content('(.*'.$configuration->{$item}->{parameters}->{regex}.'.*)');
			$Monitor->push_content($regex);
			delete $configuration->{$item}->{parameters}->{regex};
		}

		foreach my $param (keys (%{$parameters}) ) {
			my $Parameter = XML::Element->new('Parameter', 'name' => $param);
			$Parameter->push_content($parameters->{$param});
			$Monitor->push_content($Parameter);
		}

		# Write an observation for this monitor
		my $observations = $configuration->{$item}->{observations};
		foreach my $obs (sort keys (%{$observations}) ) {
			my $Observation = XML::Element->new('Observation', 'name' => $obs);

			my $Test = XML::Element->new('Test', 'type' => $observations->{$obs}->{test_type});

			foreach my $obs_param (keys (%{$observations->{$obs}->{test_params}}) ) {
				my $Param = XML::Element->new('Parameter', 'name' => $obs_param);
				$Param->push_content($observations->{$obs}->{test_params}->{$obs_param});

				$Test->push_content($Param);
			}

			my $Message = XML::Element->new('Message');
			$Message->push_content($observations->{$obs}->{message});

			$Observation->push_content($Test);
			$Observation->push_content($Message);

			if ($observations->{$obs}->{severity}) {
				if ($observations->{$obs}->{trap_dest} =~ /DEV/) {
					$Observation->push_content(WriteTrap('dev-events', $observations->{$obs}->{severity}));
				} else {
					$Observation->push_content(WriteTrap('pri-events', $observations->{$obs}->{severity}));
					$Observation->push_content(WriteTrap('fail-events', $observations->{$obs}->{severity}));
				}
			}

			$Monitor->push_content($Observation);
		}

		$Component->push_content($Monitor);
	}

	return $Fragment;
}

sub copy_template() {
	my $type = shift;
	my $h = undef;
	if ($type eq 'procmon') {
		foreach my $key (%{$procmonitor}) {
			$h->{$key} = '';
		}
	} elsif ($type eq 'logmon') {
		foreach my $key (%{$logmonitor}) {
			$h->{$key} = '';
		}
	} elsif ($type eq 'event') {
		foreach my $key (%{$event_dir}) {
			$h->{$key} = '';
		}
	}
	return $h;
}

sub trim() {
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

sub WriteTrap {
	my ($target, $severity) = @_;
	my $Trap = XML::Element->new('Trap', 'name' => $target);
	if ($severity) {
		my $oid = XML::Element->new('Parameter', 'index' => 8, 'name' => 'object');
		$oid->push_content('.1.3.6.1.4.1.10982.0.200.8;s;'.$severity);
		$Trap->push_content($oid);
	}
	return $Trap;
}

sub readableNumbers {
	my $num = shift;
	if ($num > 1073741824) {
		$nice = $num / 1073741824;
		return $nice."GB";
	} elsif ($num > 1048576) {
		$nice = $num / 1048576;
		return $nice."MB";
	} elsif ($num > 1024) {
		$nice = $num / 1024;
		return $nice."KB";
	}
}
