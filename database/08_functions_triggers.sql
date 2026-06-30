SET DEFINE OFF
SET ECHO ON
SET SERVEROUTPUT ON


-- =============================================================================
-- PREREQUISITE DDL: GRIEVANCE_AUDIT_LOG
--   Created here (not in 03_tables.sql) because it is exclusively the target
--   of trg_grievance_audit_log and has no business-layer foreign-key users.
--   Wrapped in EXECUTE IMMEDIATE so a re-run is idempotent (ORA-00955 ignored).
-- =============================================================================
PROMPT Creating GRIEVANCE_AUDIT_LOG table (idempotent)...

BEGIN
  EXECUTE IMMEDIATE '
    CREATE TABLE GRIEVANCE_AUDIT_LOG (
      log_id       NUMBER(10)    CONSTRAINT pk_grievance_audit_log PRIMARY KEY,
      grievance_id NUMBER(10)    NOT NULL
                                 CONSTRAINT fk_gal_grievance
                                   REFERENCES GRIEVANCE(grievance_id) ON DELETE CASCADE,
      old_status   VARCHAR2(20),
      new_status   VARCHAR2(20)  NOT NULL,
      changed_at   TIMESTAMP     DEFAULT CURRENT_TIMESTAMP NOT NULL,
      changed_by   VARCHAR2(100) NOT NULL
    )';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE = -955 THEN NULL; ELSE RAISE; END IF;
END;
/

BEGIN
  EXECUTE IMMEDIATE
    'CREATE SEQUENCE GRIEVANCE_AUDIT_LOG_SEQ START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE = -955 THEN NULL; ELSE RAISE; END IF;
END;
/

CREATE OR REPLACE TRIGGER GRIEVANCE_AUDIT_LOG_BI
BEFORE INSERT ON GRIEVANCE_AUDIT_LOG
FOR EACH ROW
BEGIN
  IF :NEW.log_id IS NULL THEN
    SELECT GRIEVANCE_AUDIT_LOG_SEQ.NEXTVAL INTO :NEW.log_id FROM DUAL;
  END IF;
END;
/


-- =============================================================================
-- TRIGGER 1: trg_audit_after_insert
-- =============================================================================
-- Event  : AFTER INSERT on "AUDIT"
-- Purpose: Keep FACTORY.last_audit_date / next_audit_date current and trigger
--          a full compliance-score recompute via sp_update_compliance_status.
--
-- Design note — PRAGMA AUTONOMOUS_TRANSACTION
--   fn_compliance_score (called inside sp_update_compliance_status) issues a
--   SELECT against "AUDIT". Because this is a row-level AFTER trigger on the
--   same "AUDIT" table, Oracle would raise ORA-04091 (mutating table) without
--   an autonomous transaction. The trade-off is that the FACTORY update is
--   committed independently; a subsequent ROLLBACK of the audit INSERT will
--   NOT roll back the FACTORY update. This is an accepted pattern for
--   denormalised summary columns in Oracle 11g (no compound triggers are used
--   to keep the code readable).
-- =============================================================================
PROMPT Creating trg_audit_after_insert...

CREATE OR REPLACE TRIGGER trg_audit_after_insert
AFTER INSERT ON "AUDIT"
FOR EACH ROW
DECLARE
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  -- 1. Sync audit date fields
  UPDATE FACTORY
  SET    last_audit_date = :NEW.audit_date,
         next_audit_date = ADD_MONTHS(:NEW.audit_date, 6)
  WHERE  factory_id = :NEW.factory_id;

  -- 2. Recompute weighted compliance score + status
  pkg_factory_mgmt.sp_update_compliance_status(:NEW.factory_id);

  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    pkg_error_handler.log_error(
      'trg_audit_after_insert', SQLCODE, SQLERRM,
      DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
    );
END trg_audit_after_insert;
/


-- =============================================================================
-- TRIGGER 2: trg_audit_score_status
-- =============================================================================
-- Event  : AFTER UPDATE OF score on "AUDIT"
-- Purpose: When an inspector records or revises an audit score, re-derive
--          FACTORY.compliance_score and FACTORY.compliance_status.
--          Does NOT touch AUDIT.result — that column has its own CHECK
--          constraint ('Passed'|'Failed'|'Conditional'|'Pending') and is
--          managed by the application layer, not by compliance thresholds.
--
-- WHEN clause fires only when the new score is non-NULL, suppressing noise
-- from updates to other audit columns.
-- =============================================================================
PROMPT Creating trg_audit_score_status...

CREATE OR REPLACE TRIGGER trg_audit_score_status
AFTER UPDATE OF score ON "AUDIT"
FOR EACH ROW
WHEN (NEW.score IS NOT NULL)
DECLARE
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  pkg_factory_mgmt.sp_update_compliance_status(:NEW.factory_id);
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    pkg_error_handler.log_error(
      'trg_audit_score_status', SQLCODE, SQLERRM,
      DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
    );
END trg_audit_score_status;
/


-- =============================================================================
-- TRIGGER 3: trg_salary_net_calc
-- =============================================================================
-- Event  : BEFORE INSERT OR UPDATE on SALARY_RECORD
-- Purpose: Enforce the derived relationship
--            net_salary = base_amount + overtime_paid - deductions
--          regardless of the value the caller supplied for net_salary,
--          preventing inconsistencies that bypass sp_process_salary.
--          Result is floored at 0 to satisfy the CHECK constraint.
-- =============================================================================
PROMPT Creating trg_salary_net_calc...

CREATE OR REPLACE TRIGGER trg_salary_net_calc
BEFORE INSERT OR UPDATE ON SALARY_RECORD
FOR EACH ROW
BEGIN
  :NEW.net_salary := NVL(:NEW.base_amount,    0)
                   + NVL(:NEW.overtime_paid,  0)
                   - NVL(:NEW.deductions,     0);

  IF :NEW.net_salary < 0 THEN
    :NEW.net_salary := 0;
  END IF;
END trg_salary_net_calc;
/


-- =============================================================================
-- TRIGGER 4: trg_cert_expiry_guard
-- =============================================================================
-- Event  : BEFORE INSERT on CERTIFICATION
-- Purpose: Reject certifications whose expiry_date is already in the past.
--          TRUNC() is applied so a cert expiring today is still accepted
--          (the working day has not yet ended).
-- Error  : ORA-20004  (matches -20004 reserved in sp_schedule_audit for
--          "audit already exists" — intentional re-use by the user's spec)
-- =============================================================================
PROMPT Creating trg_cert_expiry_guard...

CREATE OR REPLACE TRIGGER trg_cert_expiry_guard
BEFORE INSERT ON CERTIFICATION
FOR EACH ROW
BEGIN
  IF TRUNC(:NEW.expiry_date) < TRUNC(SYSDATE) THEN
    RAISE_APPLICATION_ERROR(
      -20004,
      'CERTIFICATION rejected: expiry_date ('
      || TO_CHAR(:NEW.expiry_date, 'YYYY-MM-DD')
      || ') is in the past.'
    );
  END IF;
END trg_cert_expiry_guard;
/


-- =============================================================================
-- TRIGGER 5: trg_worker_count_sync
-- =============================================================================
-- Event  : AFTER INSERT OR DELETE on WORKER
-- Purpose: Keep FACTORY.total_workers accurately synchronised whenever a
--          worker is added or removed without going through sp_hire_worker
--          (e.g. bulk loads, direct DML in tests).
--          Uses IF INSERTING / IF DELETING to handle both events in one body.
--          GREATEST(..., 0) prevents the count going negative under any
--          circumstance, preserving the CHECK constraint.
-- =============================================================================
PROMPT Creating trg_worker_count_sync...

CREATE OR REPLACE TRIGGER trg_worker_count_sync
AFTER INSERT OR DELETE ON WORKER
FOR EACH ROW
BEGIN
  IF INSERTING THEN
    UPDATE FACTORY
    SET    total_workers = total_workers + 1
    WHERE  factory_id = :NEW.factory_id;

  ELSIF DELETING THEN
    UPDATE FACTORY
    SET    total_workers = GREATEST(total_workers - 1, 0)
    WHERE  factory_id = :OLD.factory_id;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    pkg_error_handler.log_error(
      'trg_worker_count_sync', SQLCODE, SQLERRM,
      DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
    );
    RAISE;
END trg_worker_count_sync;
/


-- =============================================================================
-- TRIGGER 6: trg_grievance_audit_log
-- =============================================================================
-- Event  : AFTER UPDATE on GRIEVANCE
-- Purpose: Record every status transition in GRIEVANCE_AUDIT_LOG, capturing:
--            old_status  — value before the UPDATE
--            new_status  — value after the UPDATE
--            changed_at  — wall-clock TIMESTAMP
--            changed_by  — Oracle session user (SYS_CONTEXT USERENV/SESSION_USER)
--
-- WHEN clause: fires only when status actually changed, suppressing noise
--              from updates to other columns (e.g. resolution_notes edits).
--
-- PRAGMA AUTONOMOUS_TRANSACTION: the audit log entry is committed
--   independently so the trail survives even if the caller rolls back the
--   original GRIEVANCE update (immutable audit requirement).
-- =============================================================================
PROMPT Creating trg_grievance_audit_log...

CREATE OR REPLACE TRIGGER trg_grievance_audit_log
AFTER UPDATE ON GRIEVANCE
FOR EACH ROW
WHEN (NVL(NEW.status, 'X') != NVL(OLD.status, 'X'))
DECLARE
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  INSERT INTO GRIEVANCE_AUDIT_LOG (
    grievance_id,
    old_status,
    new_status,
    changed_at,
    changed_by
  ) VALUES (
    :NEW.grievance_id,
    :OLD.status,
    :NEW.status,
    CURRENT_TIMESTAMP,
    SYS_CONTEXT('USERENV', 'SESSION_USER')
  );

  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    pkg_error_handler.log_error(
      'trg_grievance_audit_log', SQLCODE, SQLERRM,
      DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
    );
END trg_grievance_audit_log;
/


PROMPT ============================================================
PROMPT  GarmentGuard triggers deployed (6 triggers + audit DDL).
PROMPT ============================================================
