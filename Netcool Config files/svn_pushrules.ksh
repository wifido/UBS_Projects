#!/bin/ksh

#######################################################################################################
# This script is called by the rules/lookup release scripts as part of the rules/lookup push automation.
# Mahesh Kumar 10Feb2009 - Creation
# Mahesh Kumar 06Mar2009 - Modify to use release date from release set.
# Mahesh Kumar 11Mar2009 - Modify to properly deduce release date from release set string
#######################################################################################################

date=`date +%Y%m%d`
SCRIPTDIR=/home/netcool/scripts/rules_push
pushlog=$SCRIPTDIR/push$date.log

# Here we choose appropriate subversion client
if [[ $host = *dap* ]]; then
    subversion=/sbcimp/run/pd/subversion/1.5.4/bin/svn
    echo "Using 1.5.4 version"
else
    subversion=/sbcimp/run/pd/subversion/1.4.3/bin/svn
    echo "Using 1.4.3 version"
fi

# Arguments passed from rules_push.ksh.
server=$1
rel=$2
enviro=$3
#####################################
#rel_set=`echo $url|nawk -F"/"  '{print $10}'`
echo $rel
ruleslength=`echo ${#rel}`
# Rules string length
if [ "$ruleslength" -gt 17 ]; then
    reldate=`echo $rel|cut -c5-14`
else
    reldate=`echo $rel|cut -c5-12`
fi
echo "release date - $reldate"

. /sbclocal/netcool/omnibus/etc/omniprof
if [ -f /home/netcool/omnialiases ]; then
        . /home/netcool/omnialiases
else
        echo "omnialiases file not found...."
        echo "omnialiases file not found....">>$pushlog
	pb-cp $pushlog $pushlog-FAILED
	pb-rm -f $pushlog
	exit 2
fi


OMNIHOME=/sbclocal/netcool/omnibus

# ISM or Probe server?
#is_ism=`grep ISM $OMNIHOME/UBS_OMNI_VERSION`
if [ -d /sbclocal/ism/ism ]
then
    is_ism='TRUE'
fi

#######################################################################################
copy_files ()
{

if [ "$is_ism" != "" ]
	then
       		cd /sbclocal/netcool/omnibus/all_rules
	else
       		cd /sbclocal/netcool/omnibus/all_rules
fi

	echo "Updating $rel\n"
	svn update $rel --username="sso_esmmon" --password="orange18"
        if [ -L ubsw ]; then
            echo "ubsw is a sym link"
            ubsw=`ls -lh ubsw | awk '{print $11}'`
            if [ "$ubsw" = $rel ]; then
                echo "ubsw already sym links to $rel. Please check"
            else
                echo "Changing ownership for $rel"
                pb-chown -R netcool:NCO_Superuser $rel
                echo "ubsw should point to $rel. Changing sym link"
                pb-rm -rf ubsw
                pb-ln -s $rel ubsw
                cd $rel
                echo "lookuptables should point to ubsw_lookuptables. Changing sym link"
                pb-ln -s ubsw_lookuptables lookuptables
                echo "Changing ownership for lookuptables"
                pb-chown -R netcool:NCO_Superuser lookuptables
            fi
        else
            echo "ubsw file either does not exist or is not a sym link. Please check."
            exit
        fi
        cd ../
        pb-chown -R netcool:NCO_Superuser ubsw
	echo "file copying complete for $server">> $pushlog
}
#########################################################################################

restart_ism ()
{
# Here we re-start the ISM DATABRIDGE.
old_bridge_pid=`ps -ef|grep ubs_bridge|head -1|awk '{print $2}'`

if [ "$old_bridge_pid" != "" ]
then
	echo "re-starting ISM DataBridge on $server\n"
	echo "re-starting ISM DataBridge on $server">> $pushlog
	pb-kill $old_bridge_pid
	sleep 20
else
	echo "\033[1;31munable to get the PID of the DataBridge...exitting\033[0;39m"
	echo "unable to get the PID of the DataBridge...exitting">> $pushlog
	pb-cp $pushlog $pushlog-FAILED
        pb-rm -f $pushlog
	exit 2
fi

new_bridge_pid=`ps -ef|grep ubs_bridge|head -1|awk '{print $2}'`

if [ "$old_bridge_pid" != "$new_bridge_pid" ]
then
	echo "DATABRIDGE has restarted, waiting 20 secs to ensure that it stays up.\n"
	sleep 20
else
   	echo "\033[1;31mDATABRIDGE is up,  but didn't restart. please investigate exitting\033[0;39m"
   	echo "DATABRIDGE is up,  but didn't restart. please investigate exitting">> $pushlog
	pb-cp $pushlog $pushlog-FAILED
        pb-rm -f $pushlog
	exit 2
fi

check_bridge_pid=`ps -ef|grep ubs_bridge|head -1|awk '{print $2}'`
if [ "$check_bridge_pid" != "$new_bridge_pid" ]
then
	echo "\033[1;31mDatabridge didn't stay up...Please investigate exitting\033[0;39m"
	echo "Databridge didn't stay up...Please investigate exitting">>$pushlog
	pb-cp $pushlog $pushlog-FAILED
        pb-rm -f $pushlog
	exit 2
else
	echo "\033[1;32mDatabridge has re-started successfully on $server\033[0;39m"
	echo "Databridge has re-started successfully on $server">> $pushlog
fi
}

#############################################################################################

hupper ()
{
# Here we hup the probes and check that the rules files have been sucessfully re-read
probes=`grep $server $SCRIPTDIR/$enviro|awk '{print $2,$3,$4,$5}'`
echo $probes >> $pushlog
# Check if the array has any probe entried at all
# Is first element empty ? (Will revisit the crude logic to use constant 4)
# Blame ksh arrays
if [ "${#probes}" -gt 4  ]; then
for probe in $probes
do
	cd $OMNIHOME/log
        pid=`ps -ef|grep _p_|grep ubs_$probe|awk '{print $2}'`
	if [ "$pid" -gt 0 ]
	then
        Logfile=ubs_$probe.log
	OldLogfile=ubs_$probe.log_old
#	version=`grep probe_loglevel $Logfile|tail -1|awk '{print $NF}'`
		if [ -f $Logfile ]
		then
#			Send event and take version in real time to prevent logfile roll-over issues.
			$SCRIPTDIR/send_event.pl info $server $probe
			sleep 5
			version=`grep probe_loglevel $Logfile|tail -1|awk '{print $NF}'`
			echo "probe log version - $version"
			   if [ "$version" == "" ]
			   then
			      sleep 20
			      version=`grep probe_loglevel $Logfile|tail -1|awk '{print $NF}'`
			      if [ "$version" == "" ]
			      then
			         # Look at old log file in case of roll-over
			         version=`grep probe_loglevel $OldLogfile|tail -1|awk '{print $NF}'`
			      fi
				if [ "$version" == "" ]
				then 
				    echo "Unable to determine old rules version.  NON FATAL ERROR"
				    echo "Unable to determine old rules version.  NON FATAL ERROR">> $pushlog
				fi	
			   fi
			   echo "Hupping $probe on $server"
			   echo "Hupping $probe on $server" >>$pushlog
        	       	   pb-kill -1 $pid
			   sleep 5
		           $SCRIPTDIR/send_event.pl previous $server $probe
			   sleep 5
			   newversion=`grep probe_loglevel $Logfile|tail -1|awk '{print $NF}'`
			   echo "probe log newversion - $newversion"
				if [ "$newversion" != "" ]
				then
					if [ "$newversion" != "$version" ] && [ "$newversion" == "$reldate" ]
					then
						echo "\033[1;32mrules file sucessfully read for \033[0;39m$server $probe"
						echo "rules file sucessfully read for $server $probe" >> $pushlog
						echo "old-version = $version new version = $newversion"
						echo "old-version = $version new version = $newversion">> $pushlog
						echo ""
					elif [ "$newversion" == "$reldate" ]
					then
						echo "\033[1;32mAlready using the correct rules version on \033[0;39m$server $probe"
                                                echo "Already using the correct rules version $server $probe" >> $pushlog
                                                echo "old-version = $version new version = $newversion"
                                                echo "old-version = $version new version = $newversion">> $pushlog
						echo ""
						echo "" >> $pushlog
					else
						echo "waiting another 40 seconds for rules file to be re-read \n"
						sleep 40
			   			newversion=`grep probe_loglevel $Logfile|tail -1|awk '{print $NF}'`
							if [ "$newversion" != "$version" ] && [ "$newversion" == "$reldate" ]
       				                        then
                                                		echo "\033[1;32mrules file sucessfully read for \033[0;39m$server $probe"
                                                		echo "rules file sucessfully read for $server $probe" >> $pushlog
                                                		echo "old-version = $version new version = $newversion"
                                                		echo "old-version = $version new version = $newversion" >> $pushlog
								echo ""
							else
								echo "old-version = $version new version = $newversion"
								echo "\033[1;31munable to verify if rules file for \033[0;39m$probe on $server read,  exitting"	
								echo "munable to verify if rules file for $probe on $server read,  exitting">> $pushlog
								pb-cp $pushlog $pushlog-FAILED
       								pb-rm -f $pushlog
								exit 2
							fi
					fi
				fi
		else
			echo "unable to locate $Logfile on $server"
			echo "unable to locate $Logfile on $server" >> $pushlog
			pb-cp $pushlog $pushlog-FAILED
      			pb-rm -f $pushlog
			exit 2
		fi
	else
		echo "$probe on $server\033[1;31m appears to be dead....exitting \033[0;39m"
		echo "$probe on $server appears to be dead....exitting">>$pushlog
		pb-cp $pushlog $pushlog-FAILED
        	pb-rm -f $pushlog
		exit 2
	fi				
done
fi
}
###############################################################################################################################
#main

echo "Starting push for $server"
echo "Starting push for $server" >>$pushlog

copy_files

#if [ "$is_ism" != "" ]
#then
#	echo "restarting ism"
#	restart_ism	
#else
#	echo "hupping probe"
#	hupper
#fi

if [ "$is_ism" != "" ]
then
	echo "restarting ism"
	restart_ism	
fi
echo "hupping probe"
hupper


echo $server>/home/netcool/scripts/rules_push/marker
exit 0



