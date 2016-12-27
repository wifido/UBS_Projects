#!/bin/ksh

SQL=${OMNIHOME}/bin/nco_sql
OSNAME=		# This will be the Object Server name as configured in omni.dat
SQLPRODUSER=	# THIS IS YOU...
SERVERLIST='LDNOBJPROD1'
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
alter group 'ISC Storage' assign members  'datsomla','stevenro','sharmaac','kennedca','buczekmi','dawsond','kurganse','pamedida','patonean','sandilmi','tamlo','jayakosi','leewia','paatke','angelich','meadean','yangya','eastwoa','theodog','tanro','laic','guptasua','hussaivi','pemmarja','chengbr','zhengpe','shabeemo','yapja','powellsr','mendozel','hughescb','hausamma','leekiema','hallmat','baerisvi','ertlvi','benedibe','lytras','puttkaan','verdesfa','lipsm','yerramru','georgejc','anbazhse','fongyi','nielsemi','kanchiri','muralitr','bueschvo','balastro','shamoofa','bernarpi','iwaszcro','tallurhi','brownis','gollapsu','angara','ghantaki','vadlapra','gollenro','cargilst','saeedam','arulmave','bhanojgu','maddugpr','alaliha','sheikab','riveraac','chaitakr','dangetki','bharadrb','tallurpr','barachma','raora','mallyapr','johnsoni','43279029','calderja','buenfl','courtejo','denhamle','goldgla','krishnjd','forresjo','gopalaka','leslimi','thommere','tomazian';
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
