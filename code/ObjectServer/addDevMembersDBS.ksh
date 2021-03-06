#!/bin/ksh

SQL=${OMNIHOME}/bin/nco_sql
OSNAME=		# This will be the Object Server name as configured in omni.dat
SQLPRODUSER=	# THIS IS YOU...
SERVERLIST='STMTEST'
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
AddMembers () {
SQLUSER=${SQLPRODUSER}
SQLPWD=${SQLPRODPWD}
print "Adding new Member to  Object Server ${OSNAME} ... Please wait"
${SQL} -server ${OSNAME} -user ${SQLUSER} -passwd ${SQLPWD} <<COF
alter group 'ISC DB Services' assign members  'chowanb','safdaram','northma','mehtasr','albertmi','manasakh','chaudhbh','bodojo','mohamesh','subramrc','bhargaan','arklega','gajjardi','srinivbc','padhydi','greenhma','pathakpr','patterma','43151136','hoadlepa','bassonch','hananich','mvw','lindaa','sankarra','sankarrb','kalesa','bangalve','varadhyu','swansora','monahabr','duraisgo','crawfost','mikicmi','kumarbia','richarac','sadanava','ezhilara','kumarav','staggri','jamadara','madanivi','trogubst','rathorat','tanai','sharmaat','pawarpr','sharmaji','baliyane','ausu','43237264','chengkea','mcguirse','forgiest','giffinda','linderma','divira','coci','ignacida','jayakosi','zeake','alberyt','casenaem','prustpe','bisquelo','royan','godara','paleessi','plewsda','omearash','wrightge','parkerjb','peszynmi','toddda','harishtu','tedjowi','kannegra','tsyrinek','mumtazfa','vinnaksr','chandras','chowlest','cordelia','singhpra','deshpama','potdarni','cleaveba','woodcha','mallikal','jarvisph','lewisal','leerz','lamcl','hokz','cyriacma','soomrofa','bawash','vangarka','pikean','higgweso','chirlasa','totejavi','nagayasu';
go
quit
COF
}

##############################################################################################################
AddColumnsLoop () {
for OSNAME in ${SERVERLIST}
do
	AddMembers
	print "New Members added to Object Server ${OSNAME}.."
	sleep 5
done
}

##############################################################################################################

SetPassword
#SetRootPassword
AddColumnsLoop
