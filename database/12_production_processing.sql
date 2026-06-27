-- 12_production_processing.sql
-- Production-level data processing routines, new tables, procedures, and scheduler jobs.

PROMPT Creating SAFETY_ALERT table and support structures...

CREATE TABLE SAFETY_ALERT (
  alert_id NUMBER(10) CONSTRAINT pk_safety_alert PRIMARY KEY,
  equipment_id NUMBER(10) NOT NULL CONSTRAINT fk_sa_equipment REFERENCES SAFETY_EQUIPMENT(equipment_id) ON DELETE CASCADE,
  factory_id NUMBER(10) NOT NULL CONSTRAINT fk_sa_factory REFERENCES FACTORY(factory_id) ON DELETE CASCADE,
  alert_date DATE DEFAULT SYSDATE NOT NULL,
  message VARCHAR2(1000) NOT NULL,
  status VARCHAR2(50) DEFAULT 'Active' NOT NULL CONSTRAINT chk_sa_status CHECK (status IN ('Active', 'Resolved'))
);

CREATE INDEX idx_safety_alert_factory ON SAFETY_ALERT(factory_id);
CREATE INDEX idx_safety_alert_equipment ON SAFETY_ALERT(equipment_id);

COMMENT ON TABLE SAFETY_ALERT IS 'Stores system-generated alerts regarding equipment safety and expiration status.';
COMMENT ON COLUMN SAFETY_ALERT.alert_id IS 'Unique identifier for the safety alert.';
COMMENT ON COLUMN SAFETY_ALERT.equipment_id IS 'Reference to the expiring or faulty safety equipment.';
COMMENT ON COLUMN SAFETY_ALERT.factory_id IS 'Reference to the factory where the alert is active.';
COMMENT ON COLUMN SAFETY_ALERT.alert_date IS 'Timestamp of when the safety alert was generated.';
COMMENT ON COLUMN SAFETY_ALERT.message IS 'Alert description detailing the expiration or issue.';
COMMENT ON COLUMN SAFETY_ALERT.status IS 'Active/Resolved status of the alert.';

CREATE SEQUENCE SAFETY_ALERT_SEQ START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE OR REPLACE TRIGGER SAFETY_ALERT_BI
BEFORE INSERT ON SAFETY_ALERT
FOR EACH ROW
BEGIN
  IF :NEW.alert_id IS NULL THEN
    SELECT SAFETY_ALERT_SEQ.NEXTVAL INTO :NEW.alert_id FROM DUAL;
  END IF;
END;
/

PROMPT Creating bulk processing salary procedure...

CREATE OR REPLACE PROCEDURE sp_bulk_mark_salaries_paid (
  p_month IN NUMBER,
  p_year  IN NUMBER
) IS
  TYPE t_record_ids IS TABLE OF SALARY_RECORD.record_id%TYPE;
  v_ids t_record_ids;
BEGIN
  -- BULK COLLECT all matching record IDs where status is Pending
  SELECT record_id
  BULK COLLECT INTO v_ids
  FROM SALARY_RECORD
  WHERE month = p_month
    AND year = p_year
    AND payment_status = 'Pending';

  -- If any matching records are found, update using FORALL
  IF v_ids.COUNT > 0 THEN
    FORALL i IN 1..v_ids.COUNT
      UPDATE SALARY_RECORD
      SET payment_status = 'Paid'
      WHERE record_id = v_ids(i);
  END IF;

  DBMS_OUTPUT.PUT_LINE('SALARIES_PAID_COUNT=' || v_ids.COUNT);
END sp_bulk_mark_salaries_paid;
/

PROMPT Creating equipment expiry safety check procedure...

CREATE OR REPLACE PROCEDURE sp_check_equipment_expiry IS
BEGIN
  -- Insert alerts for equipment expiring in <= 30 days
  -- only if there isn't already an 'Active' alert for that equipment.
  INSERT INTO SAFETY_ALERT (equipment_id, factory_id, message, status)
  SELECT 
    se.equipment_id, 
    se.factory_id, 
    'Safety equipment ' || se.equipment_type || ' at location ' || NVL(se.location, 'unknown') || ' is expiring on ' || TO_CHAR(se.expiry_date, 'DD-MON-YYYY') || ' (Quantity: ' || se.quantity || ').',
    'Active'
  FROM SAFETY_EQUIPMENT se
  WHERE se.expiry_date <= SYSDATE + 30
    AND NOT EXISTS (
      SELECT 1 
      FROM SAFETY_ALERT sa
      WHERE sa.equipment_id = se.equipment_id
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
