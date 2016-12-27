#!/bin/ksh

SQL=${OMNIHOME}/bin/nco_sql
OSNAME=		# This will be the Object Server name as configured in omni.dat
SQLPRODUSER=	# THIS IS YOU...
SERVERLIST='STMOBJENG1'
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
alter group 'ISC Wintel' assign members  'schroeer','ortizjo','owensta','leungel','acharysa','dasbi','budriean','hoadlepa','jesse','duncanma','higgweso','avillost','matthewb','hupperer','smithjo','hamilda','thakursh','conqueti','stehrean','delemege','imarhima','nordstmi','langre','machecwe','gwees','neoch','tanck','chishoju','kumarmz','anglc','lovattda','sidhuja','milicpe','miahma','beamsch','mohammfb','obrienri','sidhpusa','milehasc','landonst','meixneth','uppalv','placonmi','kungst','limjo','groveras','namboora','moksi','lohma','ndvi','erraboki','tayfa','froggaan','stonepaa','sydops','leejason','stachepa','padhydi','cheahmi','cherayaj','camachge','pipersu','kyriacaa','ranjanpr','palmisda','yannotmi','khannala','lubangro','pahujari','diazjo','huboundi','bersamro','kahnlu','fernanar','clarkeju','dheranaj','knowldro','veerabsr','jhapr','trinidle','mohammel','kanukove','gelliki','trogubst','henryth','rengasan','moffatni','tsangmo','prakasja','martinbd','panwarar','sanapoan','freywi','43105350','thomasba','barrosre','canteima','antinale','ghoshav','potharph','chawhabh','adiropkh','kollursr','maheshvb','sawanan','mamidade','ponangab','farooqha','kurupaha','jakhotde','vinjanra','jainpra','bashaya','shivarar','loganara','williarh','anugusa','muthumra','gullade','kandresu','vallabsr','divira','madhyaka','bandelap','tatira','kondabsr','gavvalpr','katpalsu','dharmama','medipara','royan','felicira','chokshrb','potockri','anandpa','aghadiro','singhta','gottipsa','mojicaby','albertni','yadavdi','koulasve','tendipe','chowlest','balesaim','barnesia','bhogtesa','bodegaa','bued','bustora','cameroon','conkldo','cordelia','costanch','dawsonta','chengjo','egglesj','estebac','evangeda','hannonta','hawkinch','hodsond','hughbri','jainan','jonesmab','kellsam','krienbwe','lial','likia','lile','linetsal','lopezkr','lucasph','mallaral','mansmaja','menceji','middlen','mumtazfa','murphypa','ooimic','patelhe','reddento','roadydb','rollind','vermavia','wongcc','yefetto','wintel','upadhyar','kannegra','tsyrinek','vinnaksr','hananich','bangalve';
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
