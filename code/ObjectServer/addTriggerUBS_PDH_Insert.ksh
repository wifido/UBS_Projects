#!/bin/ksh

SQL=${OMNIHOME}/bin/nco_sql
OSNAME=		# This will be the Object Server name as configured in omni.dat
SQLPRODUSER='janesch'	# THIS IS YOU...
#This are the ObjectServers in Dev and Eng
#SERVERLIST='LDNOBJENG1 LDNOBJENG2 STMOBJENG1 STMOBJENG2 STMOBJTEST1'
#This are the ObjectServers in Eng
#SERVERLIST='LDNOBJENG1'
#SERVERLIST='STMOBJPROD1'
#SERVERLIST='LDNOBJPROD1'
#SERVERLIST='SNGOBJPROD1'
#SERVERLIST='ZUROBJPROD1'
#SERVERLIST='SNGOBJPROD2'
#SERVERLIST='STMOBJPROD2'
#This are the ObjectServers on Prod
SERVERLIST='STMOBJPROD1 LDNOBJPROD1 SNGOBJPROD1  ZUROBJPROD1 SNGOBJPROD2 '
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

CREATE TRIGGER UBS_Suppress_PDH_Insert
GROUP UBS_Suppress
DEBUG False
ENABLED False
PRIORITY 1
COMMENT '20070503 Chris Janes GCMS 321653 this trigger inserts a host into PDH when a insert event is recieved'
EVERY 37 SECONDS
EVALUATE select NodeAlias, Class, UserData, UserData1, UserInt2, UserInt1, UserInt, FirstOccurrence,  LastOccurrence ,XtraTime,Identifier, SLA_Time from alerts.status where Class = 1640 and UserInt = 1 BIND AS pdh
DECLARE
isit int;
begin

for each pdhrow in pdh
      begin
	set isit = 0;
	for each row supp in  custom.suppress where supp.KeyField = pdhrow.UserData1 + ' ' + to_char( pdhrow.UserInt1)
	begin
		set isit = 1;
	end;
	
	if isit = 0
	then
	          insert into custom.suppress ( KeyField, NodeAlias, Class,Owner, OwnerGID, StartTime, EndTime, Method, Comments) values(pdhrow.UserData1 + ' ' + to_char( pdhrow.UserInt1), pdhrow.UserData1, pdhrow.Class, pdhrow.UserData, 0, pdhrow.FirstOccurrence, pdhrow.XtraTime, pdhrow.UserInt1, 'UBS_PDH_Insert trigger');
	else
	          update  custom.suppress via  pdhrow.UserData1 + ' ' + to_char( pdhrow.UserInt1)
	               set
		StartTime = pdhrow.FirstOccurrence,
		EndTime = pdhrow.XtraTime;
	end if;

	if pdhrow. LastOccurrence < getdate() - 120
	then
	          update alerts.status via pdhrow.Identifier set UserInt = 2; 
	end if
      end

end
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
