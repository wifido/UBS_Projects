#!/usr/bin/ksh


SQL=/sbclocal/netcool/omnibus/bin/nco_sql
SQLCODE=$1
#SQLCODE="AlertGroup != %'Autosys' and Manager not in ('SecurityWatch','ConnectionWatch') and (NodeAlias = 'xstm8950pap.stm.swissbank.com' or NodeAlias = 'xstm8950pap' or Node = 'xstm8950pap.stm.swissbank.com' or Node = 'xstm8950pap' )"
SQLFILE=$2
SQLPWD=$3
#LOGFILE=/home/janesch/rules/TempSQLTest.log
LOGFILE=${SQLFILE}/TempSQLTest.log
if [ -f ${LOGFILE} ]; then
        rm -f ${LOGFILE}
fi

${SQL} -server STMOBJTEST1 -user scriptuser -passwd omnibus <<EOF >> ${LOGFILE}
select * from alerts.status where ${SQLCODE} ;
go
quit
EOF
