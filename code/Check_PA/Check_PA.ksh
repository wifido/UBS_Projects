#!/bin/ksh
if [ -f /sbclocal/netcool/UBS_ENVIRONMENT/omniprof ]; then
	. /sbclocal/netcool/UBS_ENVIRONMENT/omniprof
fi
#OMNIHOME=${MUSE_BASE}/omnibus
#PA_LIST="LDN0064_PA LDN0150_PA LDN0628_PA LDN1014_PA LDN1017_PA LDN1018_PA LDN2376_PA LDN2795_PA LDN2892_PA LDN2893_PA LDN2929_PA OPF0100_PA OPF0101_PA SNG1001_PA SNG1209_PA SNG1282_PA SNG1283_PA SNG1284_PA SNG1285_PA SNG1299_PA STM1315_PA STM1318_PA STM1343_PA STM1394_PA STM1770_PA STM1771_PA STM5987_PA STM6143_PA STM8958_PA ZUR0565_PA ZUR0567_PA"
PA_LIST="LDN1052_PA LDN1054_PA STM1953_PA STM1935_PA STM1979_PA STM9174_PA SNG1281_PA"
#PA_LIST="LDN1052_PA LDN1054_PA"
#LOGFILE=${OMNILOG}/STATS/PA_STATUS.out
LOGFILE=PA_STATUS.out

##############################################################################################################

##############################################################################################################
Check_PA_AGENT() {
	${OMNIHOME}/bin/nco_pa_status -server ${PA_SERVER} -user netcool -password orange18 >> ${LOGFILE}
}
##############################################################################################################

if [ -f ${LOGFILE} ]; then
	mv ${LOGFILE} ${LOGFILE}.old
fi
for PA_SERVER in ${PA_LIST}
do
        print "Now doing server ${PA_SERVER}\n"
	print "================ Start of PA Server ${PA_SERVER}========================================" >> ${LOGFILE}
	Check_PA_AGENT
	print "================ End of PA Server ${PA_SERVER}========================================" >> ${LOGFILE}
	print " " >> ${LOGFILE}

done
