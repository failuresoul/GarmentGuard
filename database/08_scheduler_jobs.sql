-- 08. SCHEDULER JOBS AND PROCEDURES
SET DEFINE OFF
SET SQLBLANKLINES ON

PROMPT Creating scheduler helper procedures...

-- sp_bulk_mark_salaries_paid
CREATE OR REPLACE PROCEDURE sp_bulk_mark_salaries_paid(
  p_month IN NUMBER,
  p_year  IN NUMBER
) IS
  TYPE t_ids IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
  v_ids t_ids;
BEGIN
  SELECT record_id
  BULK COLLECT INTO v_ids
  FROM SALARY_RECORD
  WHERE month = p_month
    AND year = p_year
    AND payment_status = 'Pending';

  IF v_ids.COUNT > 0 THEN
    FORALL i IN 1..v_ids.COUNT
      UPDATE SALARY_RECORD
      SET payment_status = 'Paid'
      WHERE record_id = v_ids(i);
  END IF;

  DBMS_OUTPUT.PUT_LINE('SALARIES_PAID_COUNT=' || v_ids.COUNT);
END sp_bulk_mark_salaries_paid;
/

-- sp_check_equipment_expiry
CREATE OR REPLACE PROCEDURE sp_check_equipment_expiry IS
BEGIN
  -- Insert alerts for equipment expiring in <= 30 days
  -- only if there isn't already an 'Active' alert for that equipment.
  INSERT INTO SAFETY_ALERT (factory_id, alert_type, severity, message, status)
  SELECT 
    se.factory_id, 
    'Equipment Expiry',
    'High',
    'Safety equipment ' || se.equipment_type || ' at location ' || NVL(se.location, 'unknown') || ' is expiring on ' || TO_CHAR(se.expiry_date, 'DD-MON-YYYY') || ' (Quantity: ' || se.quantity || ').',
    'Active'
  FROM SAFETY_EQUIPMENT se
  WHERE se.expiry_date <= SYSDATE + 30
    AND NOT EXISTS (
      SELECT 1 
      FROM SAFETY_ALERT sa
      WHERE sa.factory_id = se.factory_id
        AND sa.message LIKE '%' || se.equipment_type || '%'
        AND sa.status = 'Active'
    );
  
  COMMIT;
END sp_check_equipment_expiry;
/

PROMPT Creating scheduled dbms_scheduler jobs...

BEGIN
  -- Drop existing jobs if they exist to avoid duplicate creation errors
  BEGIN DBMS_SCHEDULER.DROP_JOB('job_equipment_alerts'); EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN DBMS_SCHEDULER.DROP_JOB('job_monthly_review'); EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN DBMS_SCHEDULER.DROP_JOB('job_error_log_purge'); EXCEPTION WHEN OTHERS THEN NULL; END;

  -- 1. Create job_equipment_alerts
  DBMS_SCHEDULER.CREATE_JOB (
    job_name        => 'job_equipment_alerts',
    job_type        => 'PLSQL_BLOCK',
    job_action      => 'BEGIN sp_check_equipment_expiry; END;',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=DAILY;BYHOUR=2;BYMINUTE=0;BYSECOND=0',
    enabled         => TRUE,
    comments        => 'Nightly job at 2 AM to check safety equipment expiry and log alerts'
  );

  -- 2. Create job_monthly_review
  DBMS_SCHEDULER.CREATE_JOB (
    job_name        => 'job_monthly_review',
    job_type        => 'PLSQL_BLOCK',
    job_action      => 'BEGIN UPDATE FACTORY SET compliance_status = ''Review Needed'' WHERE last_audit_date < SYSDATE - 180; END;',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=MONTHLY;BYMONTHDAY=1;BYHOUR=0;BYMINUTE=0;BYSECOND=0',
    enabled         => TRUE,
    comments        => 'Monthly job on 1st of month to set compliance status to Review Needed for factories with last audit > 180 days ago'
  );

  -- 3. Create job_error_log_purge
  DBMS_SCHEDULER.CREATE_JOB (
    job_name        => 'job_error_log_purge',
    job_type        => 'PLSQL_BLOCK',
    job_action      => 'BEGIN DELETE FROM ERROR_LOG WHERE log_timestamp < SYSDATE - 90; END;',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=WEEKLY;BYDAY=SUN;BYHOUR=0;BYMINUTE=0;BYSECOND=0',
    enabled         => TRUE,
    comments        => 'Weekly job on Sundays to delete error logs older than 90 days'
  );
END;
/
