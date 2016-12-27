#!/bin/ksh


# Usage addOSTrigger.ksh -u<User Name>

SQL=${OMNIHOME}/bin/nco_sql
OSNAME=		# This will be the Object Server name as configured in omni.dat
SQLPRODUSER='janesch'	# THIS IS YOU...

# SERVERLIST - list of Netcool ObjectServers to be modified
SERVERLIST='LDNOBJPHBT1 STMOBJPHBT1'


while getopts u: opt
do
	case "$opt" in
		u) # Sets User name for OS and GW login
			SQLPRODUSER="${OPTARG}";;
		*) # Unknown argument
			echo "Usage -u<User Name>"
			exit 1;;
		esac
done
shift `expr $OPTIND - 1`
# Define all functions to be used here.
##############################################################################################################
ContinueOrQuit () {
read CONTINUE?'Press <return> to continue or <CTRL C> to abort.. '
}

##############################################################################################################
SetPassword () {
# here we will prompt for the users password, and then clear the screen so that is not left displayed on the screen.
trap 'stty echo; exit' 0 1 2 3 15
stty -echo
read SQLPRODPWD?'Password? '
stty echo
print ""
}

##############################################################################################################
SetRootPassword () {
# here we will prompt for the users password, and then clear the screen so that is not left displayed on the screen.
print "Please enter the Omnibus root password for the Heartbeat Servers"
trap 'stty echo; exit' 0 1 2 3 15
stty -echo
read SQLROOTPWD?'Password? '
stty echo
print ""
}

##############################################################################################################

# This function adds trigger to OS - if in doubt RTFM

AddTrigger () {
SQLUSER=${SQLPRODUSER}
SQLPWD=${SQLPRODPWD}
print "Creating or Replacing new Trigger in Object Server ${OSNAME} ... Please wait"
${SQL} -server ${OSNAME} -user ${SQLUSER} -passwd ${SQLPWD} <<COF

CREATE OR REPLACE TRIGGER UBS_StartStop
GROUP UBS_Ratified
DEBUG False
ENABLED False
PRIORITY 1
COMMENT '20070508 Chris Janes GCMS tba this trigger inserts an event when a resolution stopstart event is received when there has been no previous StopStart problem eventis recieved'
EVERY 37 SECONDS
EVALUATE select NodeAlias, Class, UserData, UserData1, UserInt2, UserInt1, UserInt, FirstOccurrence,  LastOccurrence ,XtraTime,Identifier, Severity, Type, AlertGroup, AlertKey, Node, Location, Region, BusinessStream from alerts.status where AlertGroup = 'Agent' and AlertKey = 'StartStop' and Type = 2 and UserInt = 0 BIND AS StopStart
DECLARE
isit int;
begin

     for each StopStartRow in StopStart
     begin
          update alerts.status via StopStartRow.Identifier set UserInt =1; 

          set isit = 0;
          for each row stat in  alerts.status where stat.NodeAlias = StopStartRow.NodeAlias and stat.AlertGroup = StopStartRow.AlertGroup and stat.AlertKey = StopStartRow.AlertKey and stat.Type = 1 
           begin
	set isit = 1;
	update alerts.status via stat.Identifier set UserInt =1; 

           end;

           if isit = 1
           then
	-- This means that there was a shutdown event so leave alert alone
	update alerts.status via StopStartRow.Identifier set UserInt = 2; 
           else
	-- this mmeans there was NO shutdown event so modify the alert to Critical
	update alerts.status via StopStartRow.Identifier set UserInt = 3;

	insert into alerts.status (Identifier, Node, NodeAlias, AlertGroup, AlertKey,Summary, Severity, Type, ExpireID, ExpireTime, FirstOccurrence, LastOccurrence, Class, Location, Region, Probe_Rule, ProbeHostName, BusinessStream, Agent, Manager, OwnerUID ) values (StopStartRow.Identifier + 'UBS_StartStop',StopStartRow.Node, StopStartRow.NodeAlias, 'UBS_StartStop', StopStartRow.AlertKey,  'Possible Server Crash Please investigate', 5, 1, 65511, 86400, getdate(), getdate(), 123000, StopStartRow.Location , StopStartRow.Region, getservername() + 'Trigger UBS_StopStart' , get_prop_value('Hostname'), StopStartRow.BusinessStream,  'UBS_StartStop', 'Trigger', 65534  ) ; 
	end if

     end
end
go
quit
COF
}

##############################################################################################################
AddTriggersLoop () {
for OSNAME in ${SERVERLIST}
do
	AddTrigger
	print "Trigger Created or Replaced on Object Server ${OSNAME}.."
	sleep 5
done
}

##############################################################################################################

SetPassword
#SetRootPassword
AddTriggersLoop
