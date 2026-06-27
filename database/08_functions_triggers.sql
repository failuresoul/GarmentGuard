-- =============================================================================
-- 11. FUNCTIONS & TRIGGERS — GarmentGuard Automation Layer
-- Platform : Oracle Database XE 11g
-- Depends  : 03_tables.sql (schema), 07_packages.sql (pkg_error_handler)
-- =============================================================================

SET DEFINE OFF
SET ECHO ON
SET SERVEROUTPUT ON

--------------------------------------------------------------------------------
-- PREREQUISITE: GRIEVANCE_AUDIT_LOG table (used by trg_grievance_audit_log)
--------------------------------------------------------------------------------
PROMPT Creating GRIEVANCE_AUDIT_LOG table...

CREATE TABLE GRIEVANCE_AUDIT_LOG (
  log_id       NUMBER(10)    CONSTRAINT pk_grievance_audit_log PRIMARY KEY,
  grievance_id NUMBER(10)    NOT NULL
                             CONSTRAINT fk_gal_grievance
                               REFERENCES GRIEVANCE(grievance_id) ON DELETE CASCADE,
  old_status   VARCHAR2(20),
  new_status   VARCHAR2(20)  NOT NULL,
  changed_at   TIMESTAMP     DEFAULT CURRENT_TIMESTAMP NOT NULL,
  changed_by   VARCHAR2(100) NOT NULL
);

-- Sequence for the audit-log PK
CREATE SEQUENCE GRIEVANCE_AUDIT_LOG_SEQ START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

-- Auto-PK trigger for GRIEVANCE_AUDIT_LOG
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
-- SECTION 1: PACKAGE SPEC EXTENSIONS
--   Add the new function signatures to the existing package specs so that
--   callers and other PL/SQL units can reference them by name.
-- =============================================================================

--------------------------------------------------------------------------------
-- pkg_factory_mgmt — extended spec
--------------------------------------------------------------------------------
PROMPT Extending pkg_factory_mgmt spec with new functions...

CREATE OR REPLACE PACKAGE pkg_factory_mgmt AS

  -- ── existing procedures ──────────────────────────────────────────────────
  PROCEDURE sp_register_factory(
    p_name           IN VARCHAR2,
    p_reg_no         IN VARCHAR2,
    p_address        IN VARCHAR2,
    p_district       IN VARCHAR2,
    p_workers        IN NUMBER,
    p_contact        IN VARCHAR2,
    p_phone          IN VARCHAR2,
    p_email          IN VARCHAR2,
    p_factory_id     OUT NUMBER
  );

  PROCEDURE sp_schedule_audit(
    p_factory_id     IN NUMBER,
    p_inspector_id   IN NUMBER,
    p_audit_date     IN DATE
  );

  -- ── new functions ────────────────────────────────────────────────────────

  /**
   * fn_compliance_score
   *   Weighted average of the factory's three most-recent audit scores.
   *   Weights: most-recent = 50 %, second = 30 %, third = 20 %.
   *   Returns 0 if the factory has no completed audits.
   */
  FUNCTION fn_compliance_score(p_factory_id IN NUMBER) RETURN NUMBER;

  /**
   * fn_equipment_expiry_alert
   *   Returns a comma-separated list of equipment_type values whose
   *   expiry_date falls within the next 30 days (including today).
   *   Returns the literal string 'ALL OK' when nothing is expiring.
   */
  FUNCTION fn_equipment_expiry_alert(p_factory_id IN NUMBER) RETURN VARCHAR2;

  /**
   * fn_is_cert_valid
   *   Returns 'Y' when the named certification for the factory is Active
   *   and its expiry_date is in the future; 'N' otherwise.
   */
  FUNCTION fn_is_cert_valid(
    p_factory_id IN NUMBER,
    p_cert_name  IN VARCHAR2
  ) RETURN CHAR;

END pkg_factory_mgmt;
/


--------------------------------------------------------------------------------
-- pkg_worker_mgmt — extended spec
--------------------------------------------------------------------------------
PROMPT Extending pkg_worker_mgmt spec with new functions...

CREATE OR REPLACE PACKAGE pkg_worker_mgmt AS

  -- ── existing procedures ──────────────────────────────────────────────────
  PROCEDURE sp_hire_worker(
    p_factory_id     IN NUMBER,
    p_full_name      IN VARCHAR2,
    p_national_id    IN VARCHAR2,
    p_designation    IN VARCHAR2,
    p_join_date      IN DATE,
    p_base_salary    IN NUMBER,
    p_shift          IN VARCHAR2,
    p_status         IN VARCHAR2,
    p_worker_id      OUT NUMBER
  );

  PROCEDURE sp_submit_grievance(
    p_worker_id      IN NUMBER,
    p_category       IN VARCHAR2,
    p_description    IN CLOB,
    p_grievance_id   OUT NUMBER
  );

  PROCEDURE sp_process_salary(
    p_worker_id      IN NUMBER,
    p_month          IN NUMBER,
    p_year           IN NUMBER,
    p_overtime_hours IN NUMBER
  );

  -- ── new functions ────────────────────────────────────────────────────────

  /**
   * fn_worker_ytd_salary
   *   Returns the sum of net_salary paid to a worker for every month
   *   recorded in the given calendar year.  Returns 0 if no records exist.
   */
  FUNCTION fn_worker_ytd_salary(
    p_worker_id IN NUMBER,
    p_year      IN NUMBER
  ) RETURN NUMBER;

  /**
   * fn_grievance_resolution_days
   *   Returns the number of calendar days between submitted_date and
   *   resolved_date for a grievance.  Returns NULL if the grievance is
   *   still open (resolved_date IS NULL).
   */
  FUNCTION fn_grievance_resolution_days(p_grievance_id IN NUMBER) RETURN NUMBER;

END pkg_worker_mgmt;
/


-- =============================================================================
-- SECTION 2: PACKAGE BODY EXTENSIONS
--   Full replacement of both package bodies; new functions appended at the end
--   of each body.  All existing procedure code is preserved verbatim.
-- =============================================================================

--------------------------------------------------------------------------------
-- pkg_factory_mgmt — full body (existing procedures + 3 new functions)
--------------------------------------------------------------------------------
PROMPT Creating pkg_factory_mgmt body...

CREATE OR REPLACE PACKAGE BODY pkg_factory_mgmt AS

  -- ─────────────────────────────────────────────────────────────────────────
  -- sp_register_factory  (unchanged)
  -- ─────────────────────────────────────────────────────────────────────────
  PROCEDURE sp_register_factory(
    p_name           IN VARCHAR2,
    p_reg_no         IN VARCHAR2,
    p_address        IN VARCHAR2,
    p_district       IN VARCHAR2,
    p_workers        IN NUMBER,
    p_contact        IN VARCHAR2,
    p_phone          IN VARCHAR2,
    p_email          IN VARCHAR2,
    p_factory_id     OUT NUMBER
  ) IS
    v_proc_name VARCHAR2(100) := 'pkg_factory_mgmt.sp_register_factory';
  BEGIN
    INSERT INTO FACTORY (
      factory_name, registration_no, address, district, total_workers,
      compliance_status, compliance_score, contact_person, phone, email
    ) VALUES (
      p_name, p_reg_no, p_address, p_district, p_workers,
      'Pending', NULL, p_contact, p_phone, p_email
    ) RETURNING factory_id INTO p_factory_id;
  EXCEPTION
    WHEN OTHERS THEN
      pkg_error_handler.log_error(
        p_procedure_name  => v_proc_name,
        p_error_code      => SQLCODE,
        p_error_message   => SQLERRM,
        p_error_backtrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
      );
      RAISE;
  END sp_register_factory;

  -- ─────────────────────────────────────────────────────────────────────────
  -- sp_schedule_audit  (unchanged)
  -- ─────────────────────────────────────────────────────────────────────────
  PROCEDURE sp_schedule_audit(
    p_factory_id     IN NUMBER,
    p_inspector_id   IN NUMBER,
    p_audit_date     IN DATE
  ) IS
    v_proc_name VARCHAR2(100) := 'pkg_factory_mgmt.sp_schedule_audit';
    v_count     NUMBER;
    v_role      VARCHAR2(50);
  BEGIN
    BEGIN
      SELECT role INTO v_role FROM USER_ WHERE user_id = p_inspector_id;
      IF v_role != 'Inspector' THEN
        RAISE_APPLICATION_ERROR(-20005, 'Inspector ID must belong to a user with Inspector role.');
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20006, 'Inspector does not exist.');
    END;

    SELECT COUNT(*) INTO v_count
    FROM "AUDIT"
    WHERE factory_id = p_factory_id
      AND EXTRACT(YEAR  FROM audit_date) = EXTRACT(YEAR  FROM p_audit_date)
      AND EXTRACT(MONTH FROM audit_date) = EXTRACT(MONTH FROM p_audit_date);

    IF v_count > 0 THEN
      RAISE_APPLICATION_ERROR(-20004, 'An audit is already scheduled for this factory in the specified month.');
    END IF;

    INSERT INTO "AUDIT" (
      factory_id, inspector_id, audit_date, next_scheduled,
      score, result, findings, recommendations
    ) VALUES (
      p_factory_id, p_inspector_id, p_audit_date, NULL,
      NULL, 'Pending', NULL, NULL
    );
  EXCEPTION
    WHEN OTHERS THEN
      pkg_error_handler.log_error(
        p_procedure_name  => v_proc_name,
        p_error_code      => SQLCODE,
        p_error_message   => SQLERRM,
        p_error_backtrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
      );
      RAISE;
  END sp_schedule_audit;

  -- ─────────────────────────────────────────────────────────────────────────
  -- fn_compliance_score  [NEW]
  --   Weighted average of the 3 most-recent audit scores for a factory.
  --   Only audits with a non-NULL score are considered (completed audits).
  --   Weights are applied positionally (RANK 1 = 50 %, 2 = 30 %, 3 = 20 %).
  --   Returns 0 when the factory has no scored audits.
  -- ─────────────────────────────────────────────────────────────────────────
  FUNCTION fn_compliance_score(p_factory_id IN NUMBER) RETURN NUMBER IS
    v_score NUMBER := 0;
  BEGIN
    SELECT
      SUM(weighted_score) / SUM(weight)
    INTO v_score
    FROM (
      SELECT
        score,
        CASE rn
          WHEN 1 THEN 0.50
          WHEN 2 THEN 0.30
          WHEN 3 THEN 0.20
        END AS weight,
        CASE rn
          WHEN 1 THEN score * 0.50
          WHEN 2 THEN score * 0.30
          WHEN 3 THEN score * 0.20
        END AS weighted_score
      FROM (
        SELECT
          score,
          ROW_NUMBER() OVER (ORDER BY audit_date DESC, audit_id DESC) AS rn
        FROM "AUDIT"
        WHERE factory_id = p_factory_id
          AND score IS NOT NULL
      )
      WHERE rn <= 3
    );

    -- SUM() on an empty set returns NULL; convert to 0
    RETURN NVL(v_score, 0);
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;
  END fn_compliance_score;

  -- ─────────────────────────────────────────────────────────────────────────
  -- fn_equipment_expiry_alert  [NEW]
  --   Scans SAFETY_EQUIPMENT for the factory and returns a comma-separated
  --   list of equipment_type values whose expiry_date is between SYSDATE
  --   and SYSDATE + 30 days (inclusive).
  --   Returns 'ALL OK' when no equipment is expiring.
  --   Duplicate equipment_type values are de-duplicated via DISTINCT.
  -- ─────────────────────────────────────────────────────────────────────────
  FUNCTION fn_equipment_expiry_alert(p_factory_id IN NUMBER) RETURN VARCHAR2 IS
    v_list VARCHAR2(4000) := '';
    v_sep  VARCHAR2(2)    := '';

    CURSOR c_expiring IS
      SELECT DISTINCT equipment_type
      FROM   SAFETY_EQUIPMENT
      WHERE  factory_id  = p_factory_id
        AND  expiry_date IS NOT NULL
        AND  expiry_date BETWEEN TRUNC(SYSDATE) AND TRUNC(SYSDATE) + 30
      ORDER BY equipment_type;
  BEGIN
    FOR rec IN c_expiring LOOP
      v_list := v_list || v_sep || rec.equipment_type;
      v_sep  := ', ';
    END LOOP;

    RETURN CASE WHEN v_list IS NULL THEN 'ALL OK' ELSE v_list END;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 'ALL OK';
  END fn_equipment_expiry_alert;

  -- ─────────────────────────────────────────────────────────────────────────
  -- fn_is_cert_valid  [NEW]
  --   Returns 'Y' when an Active certification with the given name exists
  --   for the factory AND its expiry_date is strictly in the future.
  --   Returns 'N' in all other cases (expired, revoked, not found, etc.).
  -- ─────────────────────────────────────────────────────────────────────────
  FUNCTION fn_is_cert_valid(
    p_factory_id IN NUMBER,
    p_cert_name  IN VARCHAR2
  ) RETURN CHAR IS
    v_count NUMBER;
  BEGIN
    SELECT COUNT(*)
    INTO   v_count
    FROM   CERTIFICATION
    WHERE  factory_id  = p_factory_id
      AND  cert_name   = p_cert_name
      AND  status      = 'Active'
      AND  expiry_date > SYSDATE;

    RETURN CASE WHEN v_count > 0 THEN 'Y' ELSE 'N' END;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 'N';
  END fn_is_cert_valid;

END pkg_factory_mgmt;
/


--------------------------------------------------------------------------------
-- pkg_worker_mgmt — full body (existing procedures + 2 new functions)
--------------------------------------------------------------------------------
PROMPT Creating pkg_worker_mgmt body...

CREATE OR REPLACE PACKAGE BODY pkg_worker_mgmt AS

  -- ─────────────────────────────────────────────────────────────────────────
  -- sp_hire_worker  (unchanged)
  -- ─────────────────────────────────────────────────────────────────────────
  PROCEDURE sp_hire_worker(
    p_factory_id     IN NUMBER,
    p_full_name      IN VARCHAR2,
    p_national_id    IN VARCHAR2,
    p_designation    IN VARCHAR2,
    p_join_date      IN DATE,
    p_base_salary    IN NUMBER,
    p_shift          IN VARCHAR2,
    p_status         IN VARCHAR2,
    p_worker_id      OUT NUMBER
  ) IS
    v_proc_name         VARCHAR2(100) := 'pkg_worker_mgmt.sp_hire_worker';
    v_compliance_status VARCHAR2(50);
  BEGIN
    BEGIN
      SELECT compliance_status INTO v_compliance_status
      FROM FACTORY WHERE factory_id = p_factory_id;
      IF v_compliance_status = 'Suspended' THEN
        RAISE_APPLICATION_ERROR(-20001, 'Factory inactive');
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'Factory inactive');
    END;

    INSERT INTO WORKER (
      factory_id, full_name, national_id, designation,
      join_date, base_salary, shift, status
    ) VALUES (
      p_factory_id, p_full_name, p_national_id, p_designation,
      p_join_date, p_base_salary, p_shift, p_status
    ) RETURNING worker_id INTO p_worker_id;

    UPDATE FACTORY SET total_workers = total_workers + 1
    WHERE  factory_id = p_factory_id;
  EXCEPTION
    WHEN OTHERS THEN
      pkg_error_handler.log_error(
        p_procedure_name  => v_proc_name,
        p_error_code      => SQLCODE,
        p_error_message   => SQLERRM,
        p_error_backtrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
      );
      RAISE;
  END sp_hire_worker;

  -- ─────────────────────────────────────────────────────────────────────────
  -- sp_submit_grievance  (unchanged)
  -- ─────────────────────────────────────────────────────────────────────────
  PROCEDURE sp_submit_grievance(
    p_worker_id      IN NUMBER,
    p_category       IN VARCHAR2,
    p_description    IN CLOB,
    p_grievance_id   OUT NUMBER
  ) IS
    v_proc_name VARCHAR2(100) := 'pkg_worker_mgmt.sp_submit_grievance';
  BEGIN
    DECLARE v_dummy NUMBER;
    BEGIN
      SELECT 1 INTO v_dummy FROM WORKER WHERE worker_id = p_worker_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20007, 'Worker does not exist.');
    END;

    INSERT INTO GRIEVANCE (
      worker_id, category, description,
      submitted_date, status, resolved_date, resolution_notes
    ) VALUES (
      p_worker_id, p_category, p_description,
      SYSDATE, 'Open', NULL, NULL
    ) RETURNING grievance_id INTO p_grievance_id;
  EXCEPTION
    WHEN OTHERS THEN
      pkg_error_handler.log_error(
        p_procedure_name  => v_proc_name,
        p_error_code      => SQLCODE,
        p_error_message   => SQLERRM,
        p_error_backtrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
      );
      RAISE;
  END sp_submit_grievance;

  -- ─────────────────────────────────────────────────────────────────────────
  -- sp_process_salary  (unchanged)
  -- ─────────────────────────────────────────────────────────────────────────
  PROCEDURE sp_process_salary(
    p_worker_id      IN NUMBER,
    p_month          IN NUMBER,
    p_year           IN NUMBER,
    p_overtime_hours IN NUMBER
  ) IS
    v_proc_name   VARCHAR2(100) := 'pkg_worker_mgmt.sp_process_salary';
    v_count       NUMBER;
    v_base_salary NUMBER(10,2);
    v_ot_paid     NUMBER(10,2);
    v_net_salary  NUMBER(10,2);
  BEGIN
    IF p_overtime_hours > 60 THEN
      RAISE_APPLICATION_ERROR(-20002, 'Overtime hours exceed Bangladesh Labour Law cap of 60 hours');
    END IF;

    SELECT COUNT(*) INTO v_count
    FROM SALARY_RECORD
    WHERE worker_id = p_worker_id AND month = p_month AND year = p_year;

    IF v_count > 0 THEN
      RAISE_APPLICATION_ERROR(-20003, 'Month already processed for this worker');
    END IF;

    BEGIN
      SELECT base_salary INTO v_base_salary
      FROM WORKER WHERE worker_id = p_worker_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20008, 'Worker does not exist');
    END;

    v_ot_paid    := ROUND((v_base_salary / 26 / 8) * 1.25 * p_overtime_hours, 2);
    v_net_salary := v_base_salary + v_ot_paid;

    INSERT INTO SALARY_RECORD (
      worker_id, month, year, base_amount, overtime_hours,
      overtime_paid, deductions, net_salary, payment_status
    ) VALUES (
      p_worker_id, p_month, p_year, v_base_salary, p_overtime_hours,
      v_ot_paid, 0, v_net_salary, 'Pending'
    );
  EXCEPTION
    WHEN OTHERS THEN
      pkg_error_handler.log_error(
        p_procedure_name  => v_proc_name,
        p_error_code      => SQLCODE,
        p_error_message   => SQLERRM,
        p_error_backtrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
      );
      RAISE;
  END sp_process_salary;

  -- ─────────────────────────────────────────────────────────────────────────
  -- fn_worker_ytd_salary  [NEW]
  --   Sums net_salary across all SALARY_RECORD rows for the worker in the
  --   specified calendar year.  Returns 0 when no records are found.
  -- ─────────────────────────────────────────────────────────────────────────
  FUNCTION fn_worker_ytd_salary(
    p_worker_id IN NUMBER,
    p_year      IN NUMBER
  ) RETURN NUMBER IS
    v_total NUMBER := 0;
  BEGIN
    SELECT NVL(SUM(net_salary), 0)
    INTO   v_total
    FROM   SALARY_RECORD
    WHERE  worker_id = p_worker_id
      AND  year      = p_year;

    RETURN v_total;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;
  END fn_worker_ytd_salary;

  -- ─────────────────────────────────────────────────────────────────────────
  -- fn_grievance_resolution_days  [NEW]
  --   Returns the integer number of days between submitted_date and
  --   resolved_date.  Returns NULL when resolved_date is still NULL
  --   (i.e. the grievance has not yet been closed).
  --   Uses TRUNC to strip time components so only full calendar days count.
  -- ─────────────────────────────────────────────────────────────────────────
  FUNCTION fn_grievance_resolution_days(p_grievance_id IN NUMBER) RETURN NUMBER IS
    v_submitted DATE;
    v_resolved  DATE;
  BEGIN
    SELECT submitted_date, resolved_date
    INTO   v_submitted, v_resolved
    FROM   GRIEVANCE
    WHERE  grievance_id = p_grievance_id;

    IF v_resolved IS NULL THEN
      RETURN NULL;   -- grievance is still open
    END IF;

    RETURN TRUNC(v_resolved) - TRUNC(v_submitted);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;
    WHEN OTHERS THEN
      RETURN NULL;
  END fn_grievance_resolution_days;

END pkg_worker_mgmt;
/


-- =============================================================================
-- SECTION 3: TRIGGERS
-- =============================================================================

--------------------------------------------------------------------------------
-- trg_audit_after_insert
--   AFTER INSERT on AUDIT (quoted because AUDIT is a reserved word in Oracle)
--   Syncs FACTORY.last_audit_date, computes next_audit_date (+6 months),
--   and recalculates compliance_score via fn_compliance_score.
--   Uses PRAGMA AUTONOMOUS_TRANSACTION to allow the DML on FACTORY inside
--   an AFTER row-level trigger without a mutating-table error.
--------------------------------------------------------------------------------
PROMPT Creating trg_audit_after_insert...

CREATE OR REPLACE TRIGGER trg_audit_after_insert
AFTER INSERT ON "AUDIT"
FOR EACH ROW
DECLARE
  PRAGMA AUTONOMOUS_TRANSACTION;
  v_new_score NUMBER;
BEGIN
  -- Recompute weighted compliance score with the freshly inserted audit included
  v_new_score := pkg_factory_mgmt.fn_compliance_score(:NEW.factory_id);

  UPDATE FACTORY
  SET
    last_audit_date  = :NEW.audit_date,
    next_audit_date  = ADD_MONTHS(:NEW.audit_date, 6),
    compliance_score = v_new_score
  WHERE factory_id = :NEW.factory_id;

  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    pkg_error_handler.log_error(
      p_procedure_name  => 'trg_audit_after_insert',
      p_error_code      => SQLCODE,
      p_error_message   => SQLERRM,
      p_error_backtrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
    );
END trg_audit_after_insert;
/


--------------------------------------------------------------------------------
-- trg_audit_score_status
--   AFTER UPDATE OF score on AUDIT
--   Derives compliance_status from the newly entered score and writes it
--   back to the same AUDIT row via an AUTONOMOUS_TRANSACTION.
--   Note: The FACTORY.compliance_score is refreshed separately by
--         trg_audit_after_insert on the initial INSERT.  When an auditor
--         edits the score after the fact this trigger keeps the audit row's
--         own status current and also re-syncs the factory-level score.
--------------------------------------------------------------------------------
PROMPT Creating trg_audit_score_status...

CREATE OR REPLACE TRIGGER trg_audit_score_status
AFTER UPDATE OF score ON "AUDIT"
FOR EACH ROW
WHEN (NEW.score IS NOT NULL)
DECLARE
  PRAGMA AUTONOMOUS_TRANSACTION;
  v_status      VARCHAR2(50);
  v_new_score   NUMBER;
BEGIN
  -- Derive per-audit compliance_status label from score
  v_status :=
    CASE
      WHEN :NEW.score >= 75 THEN 'Compliant'
      WHEN :NEW.score >= 40 THEN 'At Risk'
      ELSE                       'Non-Compliant'
    END;

  -- Persist the label onto the audit row (result column mirrors compliance intent)
  UPDATE "AUDIT"
  SET    result = v_status
  WHERE  audit_id = :NEW.audit_id;

  -- Re-sync factory-level compliance_score now that this audit score changed
  v_new_score := pkg_factory_mgmt.fn_compliance_score(:NEW.factory_id);

  UPDATE FACTORY
  SET    compliance_score  = v_new_score,
         compliance_status = v_status
  WHERE  factory_id = :NEW.factory_id;

  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    pkg_error_handler.log_error(
      p_procedure_name  => 'trg_audit_score_status',
      p_error_code      => SQLCODE,
      p_error_message   => SQLERRM,
      p_error_backtrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
    );
END trg_audit_score_status;
/


--------------------------------------------------------------------------------
-- trg_salary_net_calc
--   BEFORE INSERT OR UPDATE on SALARY_RECORD
--   Computes :NEW.net_salary = base_amount + overtime_paid - deductions
--   before the row is written, ensuring the derived column is always correct
--   regardless of the caller's input for net_salary.
--------------------------------------------------------------------------------
PROMPT Creating trg_salary_net_calc...

CREATE OR REPLACE TRIGGER trg_salary_net_calc
BEFORE INSERT OR UPDATE ON SALARY_RECORD
FOR EACH ROW
BEGIN
  :NEW.net_salary := NVL(:NEW.base_amount, 0)
                   + NVL(:NEW.overtime_paid, 0)
                   - NVL(:NEW.deductions, 0);

  -- Guard against negative net_salary (e.g. excessive deductions)
  IF :NEW.net_salary < 0 THEN
    :NEW.net_salary := 0;
  END IF;
END trg_salary_net_calc;
/


--------------------------------------------------------------------------------
-- trg_cert_expiry_guard
--   BEFORE INSERT on CERTIFICATION
--   Raises ORA-20004 if the supplied expiry_date is in the past (< SYSDATE).
--   Uses TRUNC so a cert expiring today (same calendar date) is still allowed.
--------------------------------------------------------------------------------
PROMPT Creating trg_cert_expiry_guard...

CREATE OR REPLACE TRIGGER trg_cert_expiry_guard
BEFORE INSERT ON CERTIFICATION
FOR EACH ROW
BEGIN
  IF TRUNC(:NEW.expiry_date) < TRUNC(SYSDATE) THEN
    RAISE_APPLICATION_ERROR(
      -20004,
      'Certification expiry_date (' || TO_CHAR(:NEW.expiry_date, 'YYYY-MM-DD')
      || ') must not be in the past.'
    );
  END IF;
END trg_cert_expiry_guard;
/


--------------------------------------------------------------------------------
-- trg_worker_count_sync
--   AFTER INSERT OR DELETE on WORKER
--   Keeps FACTORY.total_workers accurate by incrementing on INSERT and
--   decrementing on DELETE.  Uses IF INSERTING / IF DELETING conditional
--   compilation guards so one trigger body handles both DML events cleanly.
--   total_workers is floored at 0 to satisfy the CHECK constraint.
--------------------------------------------------------------------------------
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
      p_procedure_name  => 'trg_worker_count_sync',
      p_error_code      => SQLCODE,
      p_error_message   => SQLERRM,
      p_error_backtrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
    );
    RAISE;
END trg_worker_count_sync;
/


--------------------------------------------------------------------------------
-- trg_grievance_audit_log
--   AFTER UPDATE on GRIEVANCE
--   Records every status change in GRIEVANCE_AUDIT_LOG, capturing:
--     - old_status  : value before the update
--     - new_status  : value after the update
--     - changed_at  : wall-clock timestamp of the change
--     - changed_by  : Oracle session user (SYS_CONTEXT('USERENV','SESSION_USER'))
--   The insert uses PRAGMA AUTONOMOUS_TRANSACTION so it is committed
--   independently — the audit trail is preserved even if the calling
--   transaction is later rolled back.
--   Only fires when status actually changed to avoid noise from other column
--   updates on the same row.
--------------------------------------------------------------------------------
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
      p_procedure_name  => 'trg_grievance_audit_log',
      p_error_code      => SQLCODE,
      p_error_message   => SQLERRM,
      p_error_backtrace => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
    );
END trg_grievance_audit_log;
/


PROMPT ============================================================
PROMPT  GarmentGuard automation layer (functions + triggers) done.
PROMPT ============================================================
