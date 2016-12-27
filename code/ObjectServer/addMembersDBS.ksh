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
alter group 'ISC DB Services' assign members  'mooresi','millerrc','borissal','stuewepe','dasbi','arklega','grahamcb','hoadlepa','soomrofa','basettni','friedmad','pikean','crawfost','duncanma','higgweso','renusa','greenhma','watsonco','deissb','watkinmi','hermanp','jervisw','shamss','alberyt','robsonba','ferrind','cleaveba','lewisal','golcheja','chandras','cyriacma','jainvi','hokz','lamcl','leerz','kuope','zhongal','chirlasa','mvw','pillair','murphyj','gokmanma','potdarni','yangyi','garciami','epsteija','wuye','appavuut','totejavi','nagayasu','chowanb','safdaram','northma','mehtasr','manasakh','rickarde','kupperpe','43151136','streetan','banoiucr','rajendye','bodojo','mohamesh','subramrc','bhargaan','soodka','jarvisph','jenaam','reddyna','43207213','43181248','wagnerke','rathorat','patelraj','babura','youneskh','ravive','padhydi','pathakpr','shahb','patterma','bassonch','sankarrb','campberi','kalesa','topaloma','varadhyu','tanai','parisian','shejwapu','vijayave','toddda','cioccaad','sampsoto','learmoje','draperma','mallikal','woodcha','swansora','lindsewa','junejaan','inampuso','duraisgo','zhangxu','oakesgr','guryevni','mikicmi','miriyaka','kumarbia','jamadara','jhapr','madanivi','trogubst','divakaar','katakatr','kumarav','monahabr','nagamasa','penubach','shanmusb','sriramka','armbrujo','ranganve','sawantsb','coulsori','palavasu','chettika','govindsd','parkerjb','ezhilara','thulaspr','lynchse','brenchsi','freemagu','forgiest','chaudhbh','bainsman','pawarpr','sharmaji','ausu','aebyla','calvetan','neubauhe','mcguirse','43237264','leungbz','bhanotam','shahshd','chakkael','plewsda','veerargn','uyni','chuabr','mascioco','linderma','giffinda','paleessi','omearash','divira','coci','wrightge','bravoma','peszynmi','ignacida','tingame','kumarvia','simpsost','illesma','donegaju','chatanra','aghadiro','cauganyv','alloomo','adikaine','govindsa','bisquelo','carbyma','tendipe','kundlina','zeake','casenaem','barnesmi','chowlest','campbeaa','godara','saurenhb','muthusse','kotastab','cordelia','albertmi','mumtazfa','upadhyar','harishtu','wuxia','rothke','plummeni','tedjowi','filusje','kannegra','tsyrinek','muthiyvi','vinnaksr','kahofeju','hananich','singhpra','challian','staggri','sivaprra','wijeyesa';
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
