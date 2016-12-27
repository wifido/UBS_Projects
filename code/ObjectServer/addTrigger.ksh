#!/bin/ksh

SQL=${OMNIHOME}/bin/nco_sql
OSNAME=		# This will be the Object Server name as configured in omni.dat
SQLPRODUSER='janesch'	# THIS IS YOU...
#This are the ObjectServers in Dev and Eng
#SERVERLIST='LDNOBJENG1 LDNOBJENG2 STMOBJENG1 STMOBJENG2 STMOBJTEST1'
#This are the ObjectServers on Prod
#SERVERLIST='STMOBJPROD1 LDNOBJPROD1 SNGOBJPROD1  OPFOBJPROD1 SNGOBJPROD2 STMOBJPROD2'
#SERVERLIST='STMOBJPROD2'
#This are the Heartbeat ObjectServers on Prod
#SERVERLIST='LDNOBJPHBT1 STMOBJPHBT1'
# This is the Bi Gate in Eng
SERVERLIST='BG_STM-LDN'

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

TRANSFER FROM 'security.users' TO 'transfer.users' DELETE;
go
TRANSFER FROM 'security.groups' TO 'transfer.groups' DELETE;
go
TRANSFER FROM 'security.roles' TO 'transfer.roles' DELETE;
go
TRANSFER FROM 'security.role_grants' TO 'transfer.role_grants' DELETE;
go
TRANSFER FROM 'security.group_members' TO 'transfer.group_members' DELETE;
go
TRANSFER FROM 'catalog.restrictions' TO 'transfer.restrictions' DELETE;
go
TRANSFER FROM 'security.restriction_filters' TO 'transfer.security_restrictions' DELETE;
go
TRANSFER FROM 'security.permissions' TO 'transfer.permissions' DELETE;
go
TRANSFER FROM 'custom.suppress' TO 'custom.suppress' DELETE;
go
TRANSFER FROM 'alerts.colors' TO 'alerts.colors' DELETE;
go
TRANSFER FROM 'alerts.conversions' TO 'alerts.conversions' DELETE;
go
TRANSFER FROM 'alerts.col_visuals' TO 'alerts.col_visuals' DELETE;
go
TRANSFER FROM 'alerts.objclass' TO 'alerts.objclass' DELETE;
go
TRANSFER FROM 'alerts.objmenus' TO 'alerts.objmenus' DELETE;
go
TRANSFER FROM 'alerts.objmenuitems' TO 'alerts.objmenuitems' DELETE;
go
TRANSFER FROM 'alerts.resolutions' TO 'alerts.resolutions' DELETE;
go
TRANSFER FROM 'tools.actions' TO 'tools.actions' DELETE;
go
TRANSFER FROM 'tools.action_access' TO 'tools.action_access' DELETE;
go
TRANSFER FROM 'tools.menus' TO 'tools.menus' DELETE;
go
TRANSFER FROM 'tools.menu_items' TO 'tools.menu_items' DELETE;
go
TRANSFER FROM 'tools.menu_defs' TO 'tools.menu_defs' DELETE;
go
TRANSFER FROM 'tools.prompt_defs' TO 'tools.prompt_defs' DELETE;
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
