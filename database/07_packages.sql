SET DEFINE OFF
SET ECHO ON
SET SERVEROUTPUT ON

PROMPT [1/7] pkg_error_handler spec...

CREATE OR REPLACE PACKAGE pkg_error_handler AS
  PROCEDURE log_error(
    p_proc_name IN VARCHAR2,
    p_sqlcode   IN NUMBER,
    p_sqlerrm   IN VARCHAR2,
    p_stack     IN VARCHAR2 DEFAULT NULL
  );
END pkg_error_handler;
/

PROMPT [2/7] pkg_error_handler body...

CREATE OR REPLACE PACKAGE BODY pkg_error_handler AS

  -- ── Private: create ERROR_LOG if it does not already exist ──────────────
  PROCEDURE ensure_error_log_table IS
    v_count NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_count FROM user_tables WHERE table_name = 'ERROR_LOG';
    IF v_count = 0 THEN
      EXECUTE IMMEDIATE '
        CREATE TABLE ERROR_LOG (
          log_id          NUMBER(10)     CONSTRAINT pk_error_log PRIMARY KEY,
          log_timestamp   TIMESTAMP      DEFAULT CURRENT_TIMESTAMP NOT NULL,
          username        VARCHAR2(100)  NOT NULL,
          procedure_name  VARCHAR2(150)  NOT NULL,
          error_code      NUMBER(10)     NOT NULL,
          error_message   VARCHAR2(4000) NOT NULL,
          error_backtrace VARCHAR2(4000)
        )';
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      -- ORA-00955: name already used by an existing object — safe to ignore
      IF SQLCODE = -955 THEN NULL;
      ELSE RAISE;
      END IF;
  END ensure_error_log_table;

  -- ── Public: log_error ────────────────────────────────────────────────────
  PROCEDURE log_error(
    p_proc_name IN VARCHAR2,
    p_sqlcode   IN NUMBER,
    p_sqlerrm   IN VARCHAR2,
    p_stack     IN VARCHAR2 DEFAULT NULL
  ) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    INSERT INTO ERROR_LOG (
      procedure_name,
      error_code,
      error_message,
      error_backtrace,
      username
    ) VALUES (
      p_proc_name,
      p_sqlcode,
      p_sqlerrm,
      p_stack,
      SYS_CONTEXT('USERENV', 'SESSION_USER')
    );
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      -- Last-resort: never let the error logger raise back to the caller
      DBMS_OUTPUT.PUT_LINE('!! pkg_error_handler.log_error failed: ' || SQLERRM);
      ROLLBACK;
  END log_error;

-- ── Package initialisation: guarantee ERROR_LOG exists at first use ────────
BEGIN
  ensure_error_log_table;
END pkg_error_handler;
/


-- =============================================================================
-- 3.  pkg_reporting  SPEC
--     Compiled before pkg_factory_mgmt / pkg_worker_mgmt bodies so those
--     bodies can reference the package-level constants by name.
-- =============================================================================
PROMPT [3/7] pkg_reporting spec...

CREATE OR REPLACE PACKAGE pkg_reporting AS

  -- ── Shared compliance thresholds ────────────────────────────────────────
  c_compliant_threshold CONSTANT NUMBER := 75;   -- score >= 75  => Compliant
  c_at_risk_threshold   CONSTANT NUMBER := 40;   -- score >= 40  => Partially Compliant
  c_ot_cap              CONSTANT NUMBER := 60;   -- Bangladesh Labour Law OT cap (hours/month)

  /**
   * sp_generate_factory_report
   *   Prints a formatted compliance summary for a factory to DBMS_OUTPUT.
   *   Call with SET SERVEROUTPUT ON in SQL*Plus / SQLcl.
   */
  PROCEDURE sp_generate_factory_report(p_factory_id IN NUMBER);

  /**
   * sp_get_factory_workers
   *   Opens a REF CURSOR of all workers for the given factory.
   *   Designed for consumption by the Node.js API layer (oracledb).
   *
   *   Columns: worker_id, full_name, national_id, designation,
   *            join_date, base_salary, shift, status
   */
  PROCEDURE sp_get_factory_workers(
    p_factory_id IN  NUMBER,
    p_cursor     OUT SYS_REFCURSOR
  );

  /**
   * sp_get_audit_history
   *   Opens a REF CURSOR of chronological audit history for a factory.
   *
   *   Columns: audit_id, audit_date, score, result, next_scheduled,
   *            inspector_name, inspector_email, findings, recommendations
   */
  PROCEDURE sp_get_audit_history(
    p_factory_id IN  NUMBER,
    p_cursor     OUT SYS_REFCURSOR
  );

END pkg_reporting;
/


-- =============================================================================
-- 4.  pkg_factory_mgmt  SPEC
-- =============================================================================
PROMPT [4/7] pkg_factory_mgmt spec...

CREATE OR REPLACE PACKAGE pkg_factory_mgmt AS

  /**
   * sp_register_factory
   *   Inserts a new FACTORY row (compliance_status = 'Pending', score NULL).
   *   Returns the generated factory_id via p_factory_id.
   */
  PROCEDURE sp_register_factory(
    p_name       IN  VARCHAR2,
    p_reg_no     IN  VARCHAR2,
    p_address    IN  VARCHAR2,
    p_district   IN  VARCHAR2,
    p_workers    IN  NUMBER,
    p_contact    IN  VARCHAR2,
    p_phone      IN  VARCHAR2,
    p_email      IN  VARCHAR2,
    p_factory_id OUT NUMBER
  );

  /**
   * sp_update_compliance_status
   *   Recomputes compliance_score via fn_compliance_score and derives
   *   compliance_status using pkg_reporting thresholds.
   *   Called by trg_audit_after_insert and trg_audit_score_status.
   *
   *   Status mapping:
   *     score >= c_compliant_threshold => 'Compliant'
   *     score >= c_at_risk_threshold   => 'Partially Compliant'
   *     otherwise                      => 'Non-Compliant'
   */
  PROCEDURE sp_update_compliance_status(p_factory_id IN NUMBER);

  /**
   * fn_compliance_score
   *   Returns the weighted average of the factory's last 3 completed
   *   (non-NULL score) audit scores.
   *   Weights:  most-recent = 50 %  /  2nd = 30 %  /  3rd = 20 %.
   *   Returns 0 when no scored audits exist.
   *   Internally uses the private helper get_last_n_audit_scores.
   */
  FUNCTION fn_compliance_score(p_factory_id IN NUMBER) RETURN NUMBER;

  /**
   * fn_is_cert_valid
   *   Returns 'Y' when a certification named p_cert_name exists for
   *   p_factory_id with status = 'Active' and expiry_date > SYSDATE.
   *   Returns 'N' in all other cases.
   */
  FUNCTION fn_is_cert_valid(
    p_factory_id IN NUMBER,
    p_cert_name  IN VARCHAR2
  ) RETURN CHAR;

  /**
   * fn_equipment_expiry_alert
   *   Returns a comma-separated list of DISTINCT equipment_type values
   *   from SAFETY_EQUIPMENT whose expiry_date falls within the next 30
   *   calendar days (inclusive of today).
   *   Returns 'ALL OK' when nothing is expiring.
   */
  FUNCTION fn_equipment_expiry_alert(p_factory_id IN NUMBER) RETURN VARCHAR2;

END pkg_factory_mgmt;
/


-- =============================================================================
-- 5.  pkg_worker_mgmt  SPEC
-- =============================================================================
PROMPT [5/7] pkg_worker_mgmt spec...

CREATE OR REPLACE PACKAGE pkg_worker_mgmt AS

  /**
   * sp_hire_worker
   *   Validates the factory (must not be Suspended), inserts a WORKER row,
   *   and returns the generated worker_id.
   *   NOTE: FACTORY.total_workers is maintained by trg_worker_count_sync.
   */
  PROCEDURE sp_hire_worker(
    p_factory_id  IN  NUMBER,
    p_full_name   IN  VARCHAR2,
    p_national_id IN  VARCHAR2,
    p_designation IN  VARCHAR2,
    p_join_date   IN  DATE,
    p_base_salary IN  NUMBER,
    p_shift       IN  VARCHAR2,
    p_status      IN  VARCHAR2,
    p_worker_id   OUT NUMBER
  );

  /**
   * sp_process_salary
   *   Validates overtime via fn_is_overtime_valid (private), computes
   *   overtime_paid using Bangladesh Labour Law formula, and inserts a
   *   SALARY_RECORD row.  net_salary is also recomputed by trg_salary_net_calc.
   *
   *   OT formula: (base_salary / 26 working-days / 8 hours) * 1.25 * ot_hours
   */
  PROCEDURE sp_process_salary(
    p_worker_id      IN NUMBER,
    p_month          IN NUMBER,
    p_year           IN NUMBER,
    p_overtime_hours IN NUMBER
  );

  /**
   * sp_submit_grievance
   *   Validates the worker exists and inserts a GRIEVANCE row (status = 'Open').
   *   Returns the generated grievance_id.
   */
  PROCEDURE sp_submit_grievance(
    p_worker_id    IN  NUMBER,
    p_category     IN  VARCHAR2,
    p_description  IN  CLOB,
    p_grievance_id OUT NUMBER
  );

  /**
   * fn_worker_ytd_salary
   *   Returns SUM(net_salary) from SALARY_RECORD for p_worker_id in p_year.
   *   Returns 0 when no records exist.
   */
  FUNCTION fn_worker_ytd_salary(
    p_worker_id IN NUMBER,
    p_year      IN NUMBER
  ) RETURN NUMBER;

  /**
   * fn_grievance_resolution_days
   *   Returns TRUNC(resolved_date) - TRUNC(submitted_date) for a grievance.
   *   Returns NULL when resolved_date IS NULL (grievance still open).
   */
  FUNCTION fn_grievance_resolution_days(p_grievance_id IN NUMBER) RETURN NUMBER;

END pkg_worker_mgmt;
/


-- =============================================================================
-- 6.  pkg_factory_mgmt  BODY
-- =============================================================================
PROMPT [6/7] pkg_factory_mgmt body...

CREATE OR REPLACE PACKAGE BODY pkg_factory_mgmt AS

  -- ── Private forward declaration ──────────────────────────────────────────
  --   get_last_n_audit_scores is used inside fn_compliance_score.
  --   The full definition appears at the bottom of this body (private section).
  FUNCTION get_last_n_audit_scores(
    p_factory_id IN NUMBER,
    p_n          IN NUMBER
  ) RETURN SYS.ODCINUMBERLIST;

  -- ==========================================================================
  -- PUBLIC subprograms
  -- ==========================================================================

  -- --------------------------------------------------------------------------
  -- sp_register_factory
  -- --------------------------------------------------------------------------
  PROCEDURE sp_register_factory(
    p_name       IN  VARCHAR2,
    p_reg_no     IN  VARCHAR2,
    p_address    IN  VARCHAR2,
    p_district   IN  VARCHAR2,
    p_workers    IN  NUMBER,
    p_contact    IN  VARCHAR2,
    p_phone      IN  VARCHAR2,
    p_email      IN  VARCHAR2,
    p_factory_id OUT NUMBER
  ) IS
    v_proc VARCHAR2(100) := 'pkg_factory_mgmt.sp_register_factory';
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
      pkg_error_handler.log_error(v_proc, SQLCODE, SQLERRM,
        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      RAISE;
  END sp_register_factory;

  -- --------------------------------------------------------------------------
  -- sp_update_compliance_status
  --   Called by triggers after an audit INSERT or score UPDATE.
  --   Maps weighted score to one of the three CHECK-constrained status values.
  -- --------------------------------------------------------------------------
  PROCEDURE sp_update_compliance_status(p_factory_id IN NUMBER) IS
    v_proc   VARCHAR2(100) := 'pkg_factory_mgmt.sp_update_compliance_status';
    v_score  NUMBER;
    v_status VARCHAR2(50);
  BEGIN
    v_score := fn_compliance_score(p_factory_id);

    -- Map to FACTORY.compliance_status CHECK constraint values:
    --   'Compliant' | 'Partially Compliant' | 'Non-Compliant'
    v_status := CASE
      WHEN v_score >= pkg_reporting.c_compliant_threshold THEN 'Compliant'
      WHEN v_score >= pkg_reporting.c_at_risk_threshold   THEN 'Partially Compliant'
      ELSE 'Non-Compliant'
    END;

    UPDATE FACTORY
    SET    compliance_score  = v_score,
           compliance_status = v_status
    WHERE  factory_id = p_factory_id;
  EXCEPTION
    WHEN OTHERS THEN
      pkg_error_handler.log_error(v_proc, SQLCODE, SQLERRM,
        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      RAISE;
  END sp_update_compliance_status;

  -- --------------------------------------------------------------------------
  -- fn_compliance_score
  --   Delegates score retrieval to the private get_last_n_audit_scores helper,
  --   then applies positional weights 50 / 30 / 20 percent.
  --   If fewer than 3 audits exist the denominator uses only the weights
  --   of the audits actually present (normalised weighted average).
  -- --------------------------------------------------------------------------
  FUNCTION fn_compliance_score(p_factory_id IN NUMBER) RETURN NUMBER IS
    v_scores  SYS.ODCINUMBERLIST;
    v_weights SYS.ODCINUMBERLIST := SYS.ODCINUMBERLIST(0.50, 0.30, 0.20);
    v_wtotal  NUMBER := 0;
    v_wsum    NUMBER := 0;
  BEGIN
    v_scores := get_last_n_audit_scores(p_factory_id, 3);

    IF v_scores IS NULL OR v_scores.COUNT = 0 THEN
      RETURN 0;
    END IF;

    FOR i IN 1 .. v_scores.COUNT LOOP
      v_wtotal := v_wtotal + v_scores(i) * v_weights(i);
      v_wsum   := v_wsum   + v_weights(i);
    END LOOP;

    RETURN ROUND(v_wtotal / v_wsum, 2);
  EXCEPTION
    WHEN OTHERS THEN RETURN 0;
  END fn_compliance_score;

  -- --------------------------------------------------------------------------
  -- fn_is_cert_valid
  -- --------------------------------------------------------------------------
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
    WHEN OTHERS THEN RETURN 'N';
  END fn_is_cert_valid;

  -- --------------------------------------------------------------------------
  -- fn_equipment_expiry_alert
  -- --------------------------------------------------------------------------
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
    WHEN OTHERS THEN RETURN 'ALL OK';
  END fn_equipment_expiry_alert;

  -- ==========================================================================
  -- PRIVATE subprograms
  -- ==========================================================================

  /**
   * get_last_n_audit_scores  [PRIVATE]
   *   Returns up to p_n most-recent non-NULL audit scores for the factory,
   *   ordered most-recent first, as a SYS.ODCINUMBERLIST collection.
   *
   *   Oracle 11g compatible: uses ROWNUM in a subquery instead of
   *   FETCH FIRST n ROWS ONLY (which requires 12c+).
   */
  FUNCTION get_last_n_audit_scores(
    p_factory_id IN NUMBER,
    p_n          IN NUMBER
  ) RETURN SYS.ODCINUMBERLIST IS
    v_result SYS.ODCINUMBERLIST := SYS.ODCINUMBERLIST();
    v_idx    PLS_INTEGER := 0;

    CURSOR c_scores IS
      SELECT score
      FROM (
        SELECT score
        FROM   "AUDIT"
        WHERE  factory_id = p_factory_id
          AND  score IS NOT NULL
        ORDER BY audit_date DESC, audit_id DESC
      )
      WHERE ROWNUM <= p_n;
  BEGIN
    FOR rec IN c_scores LOOP
      v_idx := v_idx + 1;
      v_result.EXTEND;
      v_result(v_idx) := rec.score;
    END LOOP;

    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN SYS.ODCINUMBERLIST();   -- return empty collection on error
  END get_last_n_audit_scores;

END pkg_factory_mgmt;
/


-- =============================================================================
-- 7.  pkg_worker_mgmt  BODY
-- =============================================================================
PROMPT [7/7-a] pkg_worker_mgmt body...

CREATE OR REPLACE PACKAGE BODY pkg_worker_mgmt AS

  -- ── Private forward declaration ──────────────────────────────────────────
  FUNCTION fn_is_overtime_valid(
    p_worker_id IN NUMBER,
    p_month     IN NUMBER,
    p_year      IN NUMBER,
    p_hours     IN NUMBER
  ) RETURN BOOLEAN;

  -- ==========================================================================
  -- PUBLIC subprograms
  -- ==========================================================================

  -- --------------------------------------------------------------------------
  -- sp_hire_worker
  -- --------------------------------------------------------------------------
  PROCEDURE sp_hire_worker(
    p_factory_id  IN  NUMBER,
    p_full_name   IN  VARCHAR2,
    p_national_id IN  VARCHAR2,
    p_designation IN  VARCHAR2,
    p_join_date   IN  DATE,
    p_base_salary IN  NUMBER,
    p_shift       IN  VARCHAR2,
    p_status      IN  VARCHAR2,
    p_worker_id   OUT NUMBER
  ) IS
    v_proc   VARCHAR2(100) := 'pkg_worker_mgmt.sp_hire_worker';
    v_status VARCHAR2(50);
  BEGIN
    -- Validate factory eligibility
    BEGIN
      SELECT compliance_status INTO v_status
      FROM   FACTORY WHERE factory_id = p_factory_id;

      IF v_status = 'Suspended' THEN
        RAISE_APPLICATION_ERROR(-20001, 'Cannot hire into a suspended factory.');
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'Factory does not exist.');
    END;

    INSERT INTO WORKER (
      factory_id, full_name, national_id, designation,
      join_date, base_salary, shift, status
    ) VALUES (
      p_factory_id, p_full_name, p_national_id, p_designation,
      p_join_date, p_base_salary, p_shift, p_status
    ) RETURNING worker_id INTO p_worker_id;
    -- NOTE: FACTORY.total_workers is incremented by trg_worker_count_sync
  EXCEPTION
    WHEN OTHERS THEN
      pkg_error_handler.log_error(v_proc, SQLCODE, SQLERRM,
        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      RAISE;
  END sp_hire_worker;

  -- --------------------------------------------------------------------------
  -- sp_process_salary
  -- --------------------------------------------------------------------------
  PROCEDURE sp_process_salary(
    p_worker_id      IN NUMBER,
    p_month          IN NUMBER,
    p_year           IN NUMBER,
    p_overtime_hours IN NUMBER
  ) IS
    v_proc        VARCHAR2(100) := 'pkg_worker_mgmt.sp_process_salary';
    v_base_salary NUMBER(10,2);
    v_ot_paid     NUMBER(10,2);
    v_net_salary  NUMBER(10,2);
    v_count       NUMBER;
  BEGIN
    -- Separate checks for OT cap (-20002) and duplicate month (-20003)
    IF p_overtime_hours > pkg_reporting.c_ot_cap THEN
      RAISE_APPLICATION_ERROR(-20002, 'Overtime hours exceed the statutory limit of ' || pkg_reporting.c_ot_cap || ' hours.');
    END IF;

    SELECT COUNT(*) INTO v_count
    FROM   SALARY_RECORD
    WHERE  worker_id = p_worker_id
      AND  month     = p_month
      AND  year      = p_year;

    IF v_count > 0 THEN
      RAISE_APPLICATION_ERROR(-20003, 'Salary already processed for this worker for month ' || p_month || '/' || p_year || '.');
    END IF;

    BEGIN
      SELECT base_salary INTO v_base_salary
      FROM   WORKER WHERE worker_id = p_worker_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20008, 'Worker does not exist.');
    END;

    -- Bangladesh Labour Law OT formula
    v_ot_paid    := ROUND((v_base_salary / 26 / 8) * 1.25 * p_overtime_hours, 2);
    -- net_salary also enforced by trg_salary_net_calc BEFORE INSERT
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
      pkg_error_handler.log_error(v_proc, SQLCODE, SQLERRM,
        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      RAISE;
  END sp_process_salary;

  -- --------------------------------------------------------------------------
  -- sp_submit_grievance
  -- --------------------------------------------------------------------------
  PROCEDURE sp_submit_grievance(
    p_worker_id    IN  NUMBER,
    p_category     IN  VARCHAR2,
    p_description  IN  CLOB,
    p_grievance_id OUT NUMBER
  ) IS
    v_proc  VARCHAR2(100) := 'pkg_worker_mgmt.sp_submit_grievance';
    v_dummy NUMBER;
  BEGIN
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
      pkg_error_handler.log_error(v_proc, SQLCODE, SQLERRM,
        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      RAISE;
  END sp_submit_grievance;

  -- --------------------------------------------------------------------------
  -- fn_worker_ytd_salary
  -- --------------------------------------------------------------------------
  FUNCTION fn_worker_ytd_salary(
    p_worker_id IN NUMBER,
    p_year      IN NUMBER
  ) RETURN NUMBER IS
    v_total NUMBER;
  BEGIN
    SELECT NVL(SUM(net_salary), 0)
    INTO   v_total
    FROM   SALARY_RECORD
    WHERE  worker_id = p_worker_id
      AND  year      = p_year;

    RETURN v_total;
  EXCEPTION
    WHEN OTHERS THEN RETURN 0;
  END fn_worker_ytd_salary;

  -- --------------------------------------------------------------------------
  -- fn_grievance_resolution_days
  -- --------------------------------------------------------------------------
  FUNCTION fn_grievance_resolution_days(p_grievance_id IN NUMBER) RETURN NUMBER IS
    v_submitted DATE;
    v_resolved  DATE;
  BEGIN
    SELECT submitted_date, resolved_date
    INTO   v_submitted, v_resolved
    FROM   GRIEVANCE
    WHERE  grievance_id = p_grievance_id;

    RETURN CASE
             WHEN v_resolved IS NULL THEN NULL
             ELSE TRUNC(v_resolved) - TRUNC(v_submitted)
           END;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN RETURN NULL;
    WHEN OTHERS        THEN RETURN NULL;
  END fn_grievance_resolution_days;

  -- ==========================================================================
  -- PRIVATE subprograms
  -- ==========================================================================

  /**
   * fn_is_overtime_valid  [PRIVATE]
   *   Returns TRUE when BOTH conditions hold:
   *     (a) p_hours does not exceed the statutory OT cap (pkg_reporting.c_ot_cap)
   *     (b) no SALARY_RECORD already exists for this worker / month / year
   *   Returns FALSE (and thus triggers a -20002 error in sp_process_salary)
   *   if either condition fails.
   */
  FUNCTION fn_is_overtime_valid(
    p_worker_id IN NUMBER,
    p_month     IN NUMBER,
    p_year      IN NUMBER,
    p_hours     IN NUMBER
  ) RETURN BOOLEAN IS
    v_count NUMBER;
  BEGIN
    -- (a) Statutory cap
    IF p_hours > pkg_reporting.c_ot_cap THEN
      RETURN FALSE;
    END IF;

    -- (b) Duplicate month guard
    SELECT COUNT(*) INTO v_count
    FROM   SALARY_RECORD
    WHERE  worker_id = p_worker_id
      AND  month     = p_month
      AND  year      = p_year;

    RETURN (v_count = 0);
  EXCEPTION
    WHEN OTHERS THEN RETURN FALSE;
  END fn_is_overtime_valid;

END pkg_worker_mgmt;
/


-- =============================================================================
-- 7b. pkg_reporting  BODY
--     Compiled last: body calls pkg_factory_mgmt and pkg_worker_mgmt.
-- =============================================================================
PROMPT [7/7-b] pkg_reporting body...

CREATE OR REPLACE PACKAGE BODY pkg_reporting AS

  -- --------------------------------------------------------------------------
  -- sp_generate_factory_report
  --   Produces a human-readable compliance summary on DBMS_OUTPUT.
  -- --------------------------------------------------------------------------
  PROCEDURE sp_generate_factory_report(p_factory_id IN NUMBER) IS
    v_proc VARCHAR2(100) := 'pkg_reporting.sp_generate_factory_report';

    -- Factory header
    v_name       FACTORY.factory_name%TYPE;
    v_reg_no     FACTORY.registration_no%TYPE;
    v_district   FACTORY.district%TYPE;
    v_status     FACTORY.compliance_status%TYPE;
    v_score      FACTORY.compliance_score%TYPE;
    v_workers    FACTORY.total_workers%TYPE;
    v_last_audit FACTORY.last_audit_date%TYPE;
    v_next_audit FACTORY.next_audit_date%TYPE;
    v_phone      FACTORY.phone%TYPE;
    v_contact    FACTORY.contact_person%TYPE;

    -- Derived stats
    v_open_grievances NUMBER;
    v_active_certs    NUMBER;
    v_expiry_alert    VARCHAR2(4000);

    -- Formatting
    c_rule CONSTANT VARCHAR2(60) := RPAD('=', 58, '=');
    c_dash CONSTANT VARCHAR2(60) := RPAD('-', 58, '-');

    PROCEDURE line(p_label IN VARCHAR2, p_value IN VARCHAR2) IS
    BEGIN
      DBMS_OUTPUT.PUT_LINE('  ' || RPAD(p_label, 20) || ': ' || NVL(p_value, 'N/A'));
    END line;
  BEGIN
    -- Fetch factory header row
    SELECT factory_name, registration_no, district, compliance_status,
           compliance_score, total_workers, last_audit_date, next_audit_date,
           phone, contact_person
    INTO   v_name, v_reg_no, v_district, v_status,
           v_score, v_workers, v_last_audit, v_next_audit,
           v_phone, v_contact
    FROM   FACTORY
    WHERE  factory_id = p_factory_id;

    -- Open grievances across all factory workers
    SELECT COUNT(*)
    INTO   v_open_grievances
    FROM   GRIEVANCE g
    JOIN   WORKER   w ON g.worker_id = w.worker_id
    WHERE  w.factory_id = p_factory_id
      AND  g.status NOT IN ('Resolved', 'Closed', 'Rejected');

    -- Active certifications
    SELECT COUNT(*)
    INTO   v_active_certs
    FROM   CERTIFICATION
    WHERE  factory_id  = p_factory_id
      AND  status      = 'Active'
      AND  expiry_date > SYSDATE;

    -- Equipment expiry alert (delegates to pkg_factory_mgmt)
    v_expiry_alert := pkg_factory_mgmt.fn_equipment_expiry_alert(p_factory_id);

    -- Print the report
    DBMS_OUTPUT.PUT_LINE(c_rule);
    DBMS_OUTPUT.PUT_LINE('  GARMENTGUARD — FACTORY COMPLIANCE REPORT');
    DBMS_OUTPUT.PUT_LINE('  Factory ID: ' || p_factory_id);
    DBMS_OUTPUT.PUT_LINE(c_rule);
    line('Factory Name',  v_name);
    line('Reg. Number',   v_reg_no);
    line('District',      v_district);
    line('Contact',       v_contact);
    line('Phone',         v_phone);
    line('Total Workers', TO_CHAR(v_workers));
    DBMS_OUTPUT.PUT_LINE(c_dash);
    DBMS_OUTPUT.PUT_LINE('  COMPLIANCE');
    DBMS_OUTPUT.PUT_LINE(c_dash);
    line('Status',        v_status);
    line('Score',         NVL(TO_CHAR(v_score, '990.00'), 'N/A (no audits)'));
    DBMS_OUTPUT.PUT_LINE('  Thresholds  — Compliant : >= '
      || c_compliant_threshold
      || '   At Risk : >= '
      || c_at_risk_threshold);
    DBMS_OUTPUT.PUT_LINE(c_dash);
    DBMS_OUTPUT.PUT_LINE('  AUDIT SCHEDULE');
    DBMS_OUTPUT.PUT_LINE(c_dash);
    line('Last Audit',    NVL(TO_CHAR(v_last_audit, 'DD-MON-YYYY'), 'Never'));
    line('Next Audit',    NVL(TO_CHAR(v_next_audit, 'DD-MON-YYYY'), 'Not scheduled'));
    DBMS_OUTPUT.PUT_LINE(c_dash);
    DBMS_OUTPUT.PUT_LINE('  OPERATIONAL SNAPSHOT');
    DBMS_OUTPUT.PUT_LINE(c_dash);
    line('Active Certs',       TO_CHAR(v_active_certs));
    line('Open Grievances',    TO_CHAR(v_open_grievances));
    line('Equipment Expiring', v_expiry_alert);
    DBMS_OUTPUT.PUT_LINE(c_rule);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('!! No factory found with ID: ' || p_factory_id);
    WHEN OTHERS THEN
      pkg_error_handler.log_error(v_proc, SQLCODE, SQLERRM,
        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      RAISE;
  END sp_generate_factory_report;

  -- --------------------------------------------------------------------------
  -- sp_get_factory_workers
  --   REF CURSOR for Node.js / oracledb consumption.
  --   Returns all workers for a factory sorted by full_name.
  -- --------------------------------------------------------------------------
  PROCEDURE sp_get_factory_workers(
    p_factory_id IN  NUMBER,
    p_cursor     OUT SYS_REFCURSOR
  ) IS
    v_proc VARCHAR2(100) := 'pkg_reporting.sp_get_factory_workers';
  BEGIN
    OPEN p_cursor FOR
      SELECT
        w.worker_id,
        w.full_name,
        w.national_id,
        w.designation,
        w.join_date,
        w.base_salary,
        w.shift,
        w.status
      FROM   WORKER w
      WHERE  w.factory_id = p_factory_id
      ORDER BY w.full_name;
  EXCEPTION
    WHEN OTHERS THEN
      pkg_error_handler.log_error(v_proc, SQLCODE, SQLERRM,
        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      RAISE;
  END sp_get_factory_workers;

  -- --------------------------------------------------------------------------
  -- sp_get_audit_history
  --   REF CURSOR for Node.js / oracledb consumption.
  --   Returns full audit trail for a factory, most-recent first.
  -- --------------------------------------------------------------------------
  PROCEDURE sp_get_audit_history(
    p_factory_id IN  NUMBER,
    p_cursor     OUT SYS_REFCURSOR
  ) IS
    v_proc VARCHAR2(100) := 'pkg_reporting.sp_get_audit_history';
  BEGIN
    OPEN p_cursor FOR
      SELECT
        a.audit_id,
        a.audit_date,
        a.score,
        a.result,
        a.next_scheduled,
        u.full_name  AS inspector_name,
        u.email      AS inspector_email,
        a.findings,
        a.recommendations
      FROM   "AUDIT" a
      JOIN   USER_   u ON a.inspector_id = u.user_id
      WHERE  a.factory_id = p_factory_id
      ORDER BY a.audit_date DESC, a.audit_id DESC;
  EXCEPTION
    WHEN OTHERS THEN
      pkg_error_handler.log_error(v_proc, SQLCODE, SQLERRM,
        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      RAISE;
  END sp_get_audit_history;

END pkg_reporting;
/


PROMPT ============================================================
PROMPT  All 4 GarmentGuard packages compiled successfully.
PROMPT    pkg_error_handler  — error logging with auto-DDL guard
PROMPT    pkg_factory_mgmt   — factory ops, compliance scoring
PROMPT    pkg_worker_mgmt    — hiring, salary, grievances
PROMPT    pkg_reporting      — REF CURSORs + DBMS_OUTPUT report
PROMPT ============================================================
