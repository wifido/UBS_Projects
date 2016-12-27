#!/bin/ksh

SQL=${OMNIHOME}/bin/nco_sql
OSNAME=		# This will be the Object Server name as configured in omni.dat
SQLPRODUSER=	# THIS IS YOU...
SERVERLIST='LDNOBJEHBT1 LDNOBJEHBT2'
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

print "Adding new columns to alerts.status in Object Server ${OSNAME} ... Please wait"
${SQL} -server ${OSNAME} -user ${SQLUSER} -passwd ${SQLPWD} <<COF
alter table alerts.status add column Description  varchar(2048);
alter table alerts.status add column SLA_Time  time;
alter table alerts.status add column UserData1  varchar(255);
alter table alerts.status add column UserData2  varchar(255);
alter table alerts.status add column UserInt1 int;
alter table alerts.status add column UserInt2 int;
alter table alerts.status add column AckTime  time;
alter table alerts.status add column SourceKey  varchar(255);
alter table alerts.status add column XtraTime time;
alter table alerts.status add column RemData1 varchar(255);
alter table alerts.status add column RemData2 varchar(255);
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
