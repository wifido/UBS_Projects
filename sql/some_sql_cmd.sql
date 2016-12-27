select to_char(max(lastoccurrence),'DD-MM-YYYY HH24:MI:SS') from reporter_status;
 select count(1) from reporter_status;

select Node, deletedat from reporter_status WHERE ROWNUM <= 10 and 	 and FirstOccurrence <= to_date('10-06-2009 04:00:00','DD-MM-YYYY HH24:MI:SS') 

select Node, Masterserial deletedat from reporter_status WHERE ROWNUM <= 10 and FirstOccurrence >= to_date('10-06-2009 01:00:00','DD-MM-YYYY HH24:MI:SS') and FirstOccurrence <= to_date('10-06-2009 04:00:00','DD-MM-YYYY HH24:MI:SS') and deletedat is null;

select count(1) from reporter_status WHERE FirstOccurrence >= to_date('12-06-2009 21:00:00','DD-MM-YYYY HH24:MI:SS') and FirstOccurrence <= to_date('13-06-2009 04:00:00','DD-MM-YYYY HH24:MI:SS') and deletedat is null;



ALTER TABLE reporter_status drop CONSTRAINT SYS_C001581;
ALTER TABLE reporter_status  ADD PRIMARY KEY ( ServerSerial, ServerName, FirstOccurrence);

CREATE UNIQUE INDEX RS_INDEX ON reporter_status (ServerSerial,ServerName,LastModified);



select count(1) from reporter_status WHERE FirstOccurrence >= to_date('10-06-2009 01:00:00','DD-MM-YYYY HH24:MI:SS') and FirstOccurrence <= to_date('10-06-2009 04:00:00','DD-MM-YYYY HH24:MI:SS') and deletedat is null;





ALTER TABLE reporter_status disable CONSTRAINT SYS_C001611;
DROP INDEX RS_INDEX;

CREATE UNIQUE INDEX RS_INDEX  ON reporter_status (ServerSerial,	ServerName, FirstOccurrence)


ALTER TABLE reporter_status enable CONSTRAINT SYS_C001611;



select * from ALL_CONSTRAINTS where CONSTRAINT_TYPE = 'P' and TABLE_NAME = 'reporter.reporter_status';



SELECT cols.table_name, cols.column_name, cols.position, cons.status, cons.owner FROM all_constraints cons, all_cons_columns cols WHERE cols.table_name = 'reporter_status' AND cons.constraint_type = 'P' AND cons.constraint_name = cols.constraint_name AND cons.owner = cols.owner ORDER BY cols.table_name, cols.position;





select count(1) from reporter_status WHERE FirstOccurrence >= to_date('12-06-2009 21:00:00','DD-MM-YYYY HH24:MI:SS') and FirstOccurrence <= to_date('13-06-2009 04:00:00','DD-MM-YYYY HH24:MI:SS') and deletedat is null;

  COUNT(1)
----------
      9742

select count(1) from reporter_status WHERE FirstOccurrence >= to_date('13-06-2009 00:00:00','DD-MM-YYYY HH24:MI:SS') and FirstOccurrence <= to_date('14-06-2009 04:00:00','DD-MM-YYYY HH24:MI:SS') and deletedat is null;


delete from reporter_status where FirstOccurrence >= to_date('08-09-2010 16:00:00','DD-MM-YYYY HH24:MI:SS');



ERROR at line 1:
ORA-30036: unable to extend segment by 1024 in undo tablespace 'UNDOTBS1'

alter system set undo_retention=0;


delete from reporter_status where FirstOccurrence >= to_date('01-07-2009 00:00:00', 'DD-MM-YYYY HH24:MI:SS') and FirstOccurrence <= to_date('28-07-2009 14:51:00','DD-MM-YYYY HH24:MI:SS')



select FirstOccurrence,LastOccurrence, deletedat, Type, Severity from reporter_status where Severity = 0 and deletedat > to_date('29-07-2009 18:00:00','DD-MM-YYYY HH24:MI:SS') and FirstOccurrence > to_date('29-07-2009 18:00:00','DD-MM-YYYY HH24:MI:SS')



