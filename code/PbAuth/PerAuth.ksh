#!/bin/ksh

##############################################################################################################
#
#	PbAuth.ksh    THis script is to grant ESM Monitoring Engineering to the netcool Production Hosta
#	Chris Janes
#
#	V1.0	20090317	janesch		Original 
#
##############################################################################################################


UserName=		# This will be the userid being granted access
ReasonGiven=		# This is the Reason given for requesting access to the Production hosts

# This is the list of the servers that access will be granted to
SERVERLIST='xldn2795pap xldn1014pap xldn1017pap xldn1018pap xldn0628pap xldn2892pap xldn2893pap xldn2376pap xzur0565pap xzur0567pap xsng1282pap xsng1283pap xsng1284pap xsng1285pap xsng1209pap xsng1299pap xstm1770pap xstm1771pap xstm5987pap xstm6143pap xstm1315pap xstm1394pap xstm1521pap '
#SERVERLIST='xldn2795pap '


# Define all functions to be used here.
##############################################################################################################
ContinueOrQuit () {
read CONTINUE?'Press <return> to continue or <CTRL C> to abort.. '
}

##############################################################################################################
SetUser () {
# here we will prompt for the users id, 
read UserName?'User? '
print ""
}
##############################################################################################################
SetReason () {
# here we will prompt for the reason access was requseted, 
read ReasonGiven?'Why is access being requested? '
print ""
}
##############################################################################################################
#This is the main loop that goes through the servers defined above in SERVERLIST
AuthUserLoop () {
for SERVERNAME in ${SERVERLIST}
do
	#Auth Users
	pbrun pbauthorise P_NCO ${UserName} 2 "${ReasonGiven}" ${SERVERNAME}
	#sleep 1
done
}

##############################################################################################################

SetUser
SetReason

AuthUserLoop
