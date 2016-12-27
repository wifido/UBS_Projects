CREATE OR REPLACE PROCEDURE REPORTER.db_synch (start_date IN DATE, end_date IN DATE)
IS

row_num NUMBER;
err_num NUMBER;
err_msg VARCHAR2(1000);

PRAGMA AUTONOMOUS_TRANSACTION;
   
BEGIN

/* Log actions */

INSERT INTO DB_SYNCH_LOG values ( SYS_EXTRACT_UTC( SYSTIMESTAMP ), 'Starting DBSynch from ' || to_char( start_date, 'dd mon yyyy HH24:mi:ss' ) || ' to ' || to_char( end_date, 'dd mon yyyy HH24:mi:ss' ) );

COMMIT;

/* Identify all the source events that first occurred between the gap */
   INSERT      /*+ APPEND */INTO DB_SYNCH_new
      SELECT serverserial, servername
        FROM reporter_status@stamford
       WHERE firstoccurrence BETWEEN start_date AND end_date;

   COMMIT;

/* Identify those new source events missing from the target */
   INSERT      /*+ APPEND */INTO DB_SYNCH_missing
      SELECT gn.serverserial, gn.servername
        FROM DB_SYNCH_new gn
       WHERE NOT EXISTS (
                SELECT rs.serverserial, rs.servername
                  FROM reporter_status rs
                 WHERE gn.servername = rs.servername
                   AND gn.serverserial = rs.serverserial);

   COMMIT;

/* Identify all the source events deleted between the gap */
   INSERT      /*+ APPEND */INTO DB_SYNCH_deleted
      SELECT serverserial, servername
        FROM reporter_status@stamford
       WHERE deletedat BETWEEN start_date AND end_date;

   COMMIT;

/* Identify those deleted source events left hanging in the target */
   INSERT      /*+ APPEND */INTO DB_SYNCH_hanging
      SELECT /*+ index( rs RS_INDEX_PK )*/
             rs.serverserial, rs.servername
        FROM reporter_status rs, DB_SYNCH_deleted gd
       WHERE gd.servername = rs.servername
         AND gd.serverserial = rs.serverserial
         AND rs.deletedat IS NULL;

   COMMIT;

/* Append the hanging-deleted to the list of missing-new on the source */
   INSERT      /*+ APPEND */INTO DB_SYNCH_missing
      SELECT *
        FROM DB_SYNCH_hanging;

   COMMIT;

/* Copy the complete missing list to the target to improve performance of later query */
   INSERT      /*+ APPEND */INTO DB_SYNCH_missing@stamford
      SELECT *
        FROM DB_SYNCH_missing;

   COMMIT;

/* Remove the hanging events from the target */

   DELETE FROM reporter_status rs
         WHERE (serverserial, servername) IN (SELECT serverserial, servername
                                                FROM DB_SYNCH_hanging);

/* Log actions */

row_num := SQL%ROWCOUNT;

INSERT INTO DB_SYNCH_LOG values ( SYS_EXTRACT_UTC( SYSTIMESTAMP ), 'Deleted ' || row_num || ' hanging rows' );
            
/* Copy across the missing events to the target */

   INSERT INTO reporter_status
      SELECT *
        FROM reporter_status@stamford
       WHERE (serverserial, servername) IN (SELECT serverserial, servername
                                              FROM DB_SYNCH_missing@stamford);
             
/* Log actions */

row_num := SQL%ROWCOUNT;

INSERT INTO DB_SYNCH_LOG values ( SYS_EXTRACT_UTC( SYSTIMESTAMP ), 'Inserted ' || row_num || ' missing rows' );

/* Remove the Audit Trails created by the trigger due to the INSERT on the target */
   DELETE      /*+ index( reporter_journal RJ_INDEX_PK )*/FROM reporter_journal
         WHERE (serverserial, servername) IN (SELECT serverserial, servername
                                                FROM DB_SYNCH_missing);

   DELETE      /*+ index( rep_audit_owneruid RAU_INDEX_PK )*/FROM rep_audit_owneruid
         WHERE (serverserial, servername) IN (SELECT serverserial, servername
                                                FROM DB_SYNCH_missing);

   DELETE      /*+ index( rep_audit_ownergid RAG_INDEX_PK )*/FROM rep_audit_ownergid
         WHERE (serverserial, servername) IN (SELECT serverserial, servername
                                                FROM DB_SYNCH_missing);

   DELETE      /*+ index( rep_audit_sev_clr RASCLR_INDEX_PK )*/FROM rep_audit_sev_clr
         WHERE (serverserial, servername) IN (SELECT serverserial, servername
                                                FROM DB_SYNCH_missing);

   DELETE      /*+ index( rep_audit_severity RAS_INDEX_PK )*/FROM rep_audit_severity
         WHERE (serverserial, servername) IN (SELECT serverserial, servername
                                                FROM DB_SYNCH_missing);

   DELETE      /*+ index( rep_audit_ack RAA_INDEX_PK )*/FROM rep_audit_ack
         WHERE (serverserial, servername) IN (SELECT serverserial, servername
                                                FROM DB_SYNCH_missing);

/* Copy over the Audit Trails for the missing-new and hanging-deleted events to the target */
   INSERT INTO reporter_journal
      SELECT /*+ index( reporter_journal RJ_INDEX_PK )*/
             *
        FROM reporter_journal@stamford
       WHERE (serverserial, servername) IN (SELECT serverserial, servername
                                              FROM DB_SYNCH_missing@stamford);

   INSERT INTO rep_audit_owneruid
      SELECT /*+ index( rep_audit_owneruid RAU_INDEX_PK )*/
             *
        FROM rep_audit_owneruid@stamford
       WHERE (serverserial, servername) IN (SELECT serverserial, servername
                                              FROM DB_SYNCH_missing@stamford);

   INSERT INTO rep_audit_ownergid
      SELECT /*+ index( rep_audit_ownergid RAG_INDEX_PK )*/
             *
        FROM rep_audit_ownergid@stamford
       WHERE (serverserial, servername) IN (SELECT serverserial, servername
                                              FROM DB_SYNCH_missing@stamford);

   INSERT INTO rep_audit_sev_clr
      SELECT /*+ index( rep_audit_sev_clr RASCLR_INDEX_PK )*/
             *
        FROM rep_audit_sev_clr@stamford
       WHERE (serverserial, servername) IN (SELECT serverserial, servername
                                              FROM DB_SYNCH_missing@stamford);

   INSERT INTO rep_audit_severity
      SELECT /*+ index( rep_audit_severity RAS_INDEX_PK )*/
             *
        FROM rep_audit_severity@stamford
       WHERE (serverserial, servername) IN (SELECT serverserial, servername
                                              FROM DB_SYNCH_missing@stamford);

   INSERT INTO rep_audit_ack
      SELECT /*+ index( rep_audit_ack RAA_INDEX_PK )*/
             *
        FROM rep_audit_ack@stamford
       WHERE (serverserial, servername) IN (SELECT serverserial, servername
                                              FROM DB_SYNCH_missing@stamford);

/* Log actions */

err_msg := SUBSTR(SQLERRM, 1, 1000);
INSERT INTO DB_SYNCH_LOG values ( SYS_EXTRACT_UTC( SYSTIMESTAMP ), 'Transaction committed: ' || err_msg );

COMMIT;

EXCEPTION
WHEN OTHERS THEN
BEGIN
	 ROLLBACK;

	 err_msg := SUBSTR(SQLERRM, 1, 1000);
	 INSERT INTO DB_SYNCH_LOG values ( SYS_EXTRACT_UTC( SYSTIMESTAMP ), 'Transaction rolled back: ' || err_msg );
	 
	 COMMIT;
END;


END db_synch;
/