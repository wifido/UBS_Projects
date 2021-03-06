#!/bin/ksh

SQL=${OMNIHOME}/bin/nco_sql
OSNAME=		# This will be the Object Server name as configured in omni.dat
SQLPRODUSER='janesch'	# THIS IS YOU...
#This are the ObjectServers in Dev and Eng
#SERVERLIST='LDNOBJENG1 LDNOBJENG2 STMOBJENG1 STMOBJENG2 STMOBJTEST1'
#This are the ObjectServers in Eng
#SERVERLIST='LDNOBJENG1'
#This are the ObjectServers on Prod
SERVERLIST='STMOBJPROD1 LDNOBJPROD1 SNGOBJPROD1  OPFOBJPROD1 SNGOBJPROD2 STMOBJPROD2'
#SERVERLIST='STMOBJPROD2'
#This are the Heartbeat ObjectServers on Prod
#SERVERLIST='LDNOBJPHBT1 STMOBJPHBT1'
# This is the Bi Gate in Eng
#SERVERLIST='BG_STM-LDN'

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
AddColumns () {
SQLUSER=${SQLPRODUSER}
SQLPWD=${SQLPRODPWD}
print "Creating or Replacing new Trigger in Object Server ${OSNAME} ... Please wait"
${SQL} -server ${OSNAME} -user ${SQLUSER} -passwd ${SQLPWD} <<COF

CREATE TRIGGER UBS_Resync_PEM_Events
GROUP UBS_Ratified
DEBUG False
ENABLED False
PRIORITY 1
COMMENT '20061102 Chris Janes GCMS 289129 this trigger removes all PEM events that have not been raised as a trouble ticket. on receipt of trigger event '
EVERY 1 SECONDS
EVALUATE select NodeAlias from alerts.status where Class=2222228 and Severity >0 BIND AS tt
BEGIN
if %rowcount > 0 then
	update alerts.status set Severity=0 where Class in (2222228,2222229) and OwnerGID=90005 and TTicket_Status=0;
end if;
END

go
quit
COF
}

##############################################################################################################
AddColumnsLoop () {
for OSNAME in ${SERVERLIST}
do
	AddColumns
	print "Trigger Created or Replaced on Object Server ${OSNAME}.."
	sleep 5
done
}

##############################################################################################################

SetPassword
#SetRootPassword
AddColumnsLoop
