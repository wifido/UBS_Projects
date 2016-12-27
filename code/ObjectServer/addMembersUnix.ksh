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
alter group 'ISC UNIX' assign members  'kurelst','reddyve','johrira','dibleyna','huqj','ahmads','guhadomu','kellyjg','joker','leachc','martins','pipermj','maddulha','sundrapa','saitst','smithcl','austinan','tamurak','paratodo','tremlema','kempd','lamtu','johannur','brankot','mosh','michlr','imfeldma','agnihoga','pantovad','cliffoch','lillywpe','tanigush','huntne','tanakake','bolligur','boydj','kanakar','mcquilt','lamev','lunto','sitne','tangde','wangh','chattear','chullisk','desaivb','deshpabh','fualan','raovis','teocm','wangl','gillarru','weber','patelrt','sparksch','boganagi','huige','daviescl','mclaugde','bull','julu','shimkus','morila','clohesbi','dinshabo','morreat','chekurra','romanmi','katkovya','dhindgu','nordstmi','dhamurpr','mahalasa','sharmanb','kotramu','singhsub','sahoopr','mainph','owensjo','bansalia','selvadce','kiewke','krailima','unix_test','caoke','kumarsan','kohad','kothapan','mcdonajb','barkered','bergsiha','gurunach','hammonpa','forstee','ravalni','harrisbb','puriam','willers','steinmad','dovastbe','pearsojo','khanar','potabagu','khatrimi','zwisslro','becketca','bhardwsb','zenkerth','laffrare','wuerzfe','fasolasa','gopalha','corazzfa','mazzolda','gordonco','isipno','thompsal','oisose','macinahe','cherukve','dhruvpr','nelsonab','dasgupgo','nysenma','bucklast','kattaph','simatra','koraa','audenist','kumaram','pillaiad','narayava','raghuraj','puumalju','rychcida','symonsjo','sieklupi','dixonba','maxwelke','43237264','sadowspe','nepolesa','gadeki','asunciav','krishnvb','deolivja','moorthma','ferrerrh','dsouzaa','luleyhe','mckenzro','potharph','chawhabh','adiropkh','kollursr','maheshvb','sawanan','williarh','anugusa','muthumra','gullade','kandresu','vallabsr','panzaau','madhyaka','bandelap','tatira','kondabsr','gavvalpr','katpalsu','dharmama','medipara','valentsa','moralal','diffeype','rlj','singhta','gottipsa','liangch','dubeysa','ekmo','albertni','pandeyrb','schubea','silangro','martinpc','yadavdi','perezch','koulasve','maciuspr','kanagave','ramachay','kotastab','sumawaem','peirisma','raosu','kloseal','finlaygr','babbmo','leefe','zimmerpb','damarama','leunghi','fordeda','reddyra';
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
