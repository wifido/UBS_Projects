#!/bin/ksh

SQL=${OMNIHOME}/bin/nco_sql
OSNAME=		# This will be the Object Server name as configured in omni.dat
SQLPRODUSER=	# THIS IS YOU...
SERVERLIST='LDNOBJENG1'
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
if [ ${OSNAME} = "STMOBJPHBT1" ] || [ ${OSNAME} = "LDNOBJPHBT1" ]; then
	SQLUSER=root
	SQLPWD=${SQLROOTPWD}
else
	SQLUSER=${SQLPRODUSER}
	SQLPWD=${SQLPRODPWD}
fi
if [ ${OSNAME} = "STMOBJPROD2" ];
then
	print "All Object Servers except STMOBJPROD2 and STMOBJPHBT1 have now had the extra fields added.."
	print "Holding the script here until Impact servers have been stopped and patched.."
	ContinueOrQuit
	sleep 10
fi
print "Adding new columns to alerts.status in Object Server ${OSNAME} ... Please wait"
${SQL} -server ${OSNAME} -user ${SQLUSER} -passwd ${SQLPWD} <<COF
describe alerts.status;
go
quit
COF
}

##############################################################################################################
AddColumnsLoop () {
for OSNAME in ${SERVERLIST}
do
	AddColumns
	print "New columns added to Object Server ${OSNAME}.."
	sleep 5
done
}

##############################################################################################################

SetPassword
#SetRootPassword
AddColumnsLoop
