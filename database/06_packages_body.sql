-- 06. PACKAGES BODIES
SET DEFINE OFF
SET SQLBLANKLINES ON

PROMPT Creating package bodies...

-- =============================================================================
-- 1. pkg_error_handler BODY
-- =============================================================================
CREATE OR REPLACE PACKAGE BODY pkg_error_handler AS

  -- Private: create ERROR_LOG if it does not already exist
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
      IF SQLCODE = -955 THEN NULL;
      ELSE RAISE;
      END IF;
  END ensure_error_log_table;

  -- Public: log_error
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
      DBMS_OUTPUT.PUT_LINE('!! pkg_error_handler.log_error failed: ' || SQLERRM);
      ROLLBACK;
  END log_error;

-- Package initialisation
BEGIN
  ensure_error_log_table;
END pkg_error_handler;
/

-- =============================================================================
-- 2. pkg_factory_mgmt BODY
-- =============================================================================
CREATE OR REPLACE PACKAGE BODY pkg_factory_mgmt AS

  -- Private forward declaration
  FUNCTION get_last_n_audit_scores(
    p_factory_id IN NUMBER,
    p_n          IN NUMBER
  ) RETURN SYS.ODCINUMBERLIST;

  -- sp_register_factory
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

  -- sp_update_compliance_status
  PROCEDURE sp_update_compliance_status(p_factory_id IN NUMBER) IS
    v_proc   VARCHAR2(100) := 'pkg_factory_mgmt.sp_update_compliance_status';
    v_score  NUMBER;
    v_status VARCHAR2(50);
    v_curr   VARCHAR2(50);
  BEGIN
    SELECT compliance_status INTO v_curr FROM FACTORY WHERE factory_id = p_factory_id;
    v_score := fn_compliance_score(p_factory_id);

    IF v_curr = 'Suspended' THEN
      v_status := 'Suspended';
    ELSE
      v_status := CASE
        WHEN v_score >= pkg_reporting.c_compliant_threshold THEN 'Compliant'
        WHEN v_score >= pkg_reporting.c_at_risk_threshold   THEN 'Partially Compliant'
        ELSE 'Non-Compliant'
      END;
    END IF;

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

  -- fn_compliance_score (Caches weights calculation, relies on AUDIT)
  FUNCTION fn_compliance_score(p_factory_id IN NUMBER) RETURN NUMBER
    RESULT_CACHE RELIES_ON ("AUDIT") IS
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

  -- fn_is_cert_valid
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

  -- fn_equipment_expiry_alert
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

  -- Private score history retrieval (Version-conditional dynamic SQL)
  FUNCTION get_last_n_audit_scores(
    p_factory_id IN NUMBER,
    p_n          IN NUMBER
  ) RETURN SYS.ODCINUMBERLIST IS
    v_result SYS.ODCINUMBERLIST := SYS.ODCINUMBERLIST();
    TYPE cursor_ref IS REF CURSOR;
    c_scores cursor_ref;
    v_score  NUMBER;
  BEGIN
    IF DBMS_DB_VERSION.VERSION >= 12 THEN
      OPEN c_scores FOR 
        'SELECT score FROM "AUDIT" WHERE factory_id = :1 AND score IS NOT NULL ORDER BY audit_date DESC, audit_id DESC FETCH FIRST :2 ROWS ONLY'
        USING p_factory_id, p_n;
    ELSE
      OPEN c_scores FOR 
        'SELECT score FROM (SELECT score FROM "AUDIT" WHERE factory_id = :1 AND score IS NOT NULL ORDER BY audit_date DESC, audit_id DESC) WHERE ROWNUM <= :2'
        USING p_factory_id, p_n;
    END IF;

    LOOP
      FETCH c_scores INTO v_score;
      EXIT WHEN c_scores%NOTFOUND;
      v_result.EXTEND;
      v_result(v_result.COUNT) := v_score;
    END LOOP;
    CLOSE c_scores;

    RETURN v_result;
  EXCEPTION
    WHEN OTHERS THEN
      IF c_scores%ISOPEN THEN CLOSE c_scores; END IF;
      RETURN SYS.ODCINUMBERLIST();
  END get_last_n_audit_scores;

END pkg_factory_mgmt;
/

-- =============================================================================
-- 3. pkg_worker_mgmt BODY
-- =============================================================================
CREATE OR REPLACE PACKAGE BODY pkg_worker_mgmt AS

  -- Private forward declaration
  FUNCTION fn_is_overtime_valid(
    p_worker_id IN NUMBER,
    p_month     IN NUMBER,
    p_year      IN NUMBER,
    p_hours     IN NUMBER
  ) RETURN BOOLEAN;

  -- sp_hire_worker
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
  EXCEPTION
    WHEN OTHERS THEN
      pkg_error_handler.log_error(v_proc, SQLCODE, SQLERRM,
        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      RAISE;
  END sp_hire_worker;

  -- sp_process_salary
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
      pkg_error_handler.log_error(v_proc, SQLCODE, SQLERRM,
        DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      RAISE;
  END sp_process_salary;

  -- sp_submit_grievance
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

  -- fn_worker_ytd_salary
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

  -- fn_grievance_resolution_days
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

  -- Private helper overtime validation
  FUNCTION fn_is_overtime_valid(
    p_worker_id IN NUMBER,
    p_month     IN NUMBER,
    p_year      IN NUMBER,
    p_hours     IN NUMBER
  ) RETURN BOOLEAN IS
    v_count NUMBER;
  BEGIN
    IF p_hours > pkg_reporting.c_ot_cap THEN
      RETURN FALSE;
    END IF;

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
-- 4. pkg_reporting BODY
-- =============================================================================
CREATE OR REPLACE PACKAGE BODY pkg_reporting AS

  -- sp_generate_factory_report
  PROCEDURE sp_generate_factory_report(p_factory_id IN NUMBER) IS
    v_proc VARCHAR2(100) := 'pkg_reporting.sp_generate_factory_report';

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

    v_open_grievances NUMBER;
    v_active_certs    NUMBER;
    v_expiry_alert    VARCHAR2(4000);

    c_rule CONSTANT VARCHAR2(60) := RPAD('=', 58, '=');
    c_dash CONSTANT VARCHAR2(60) := RPAD('-', 58, '-');

    PROCEDURE line(p_label IN VARCHAR2, p_value IN VARCHAR2) IS
    BEGIN
      DBMS_OUTPUT.PUT_LINE('  ' || RPAD(p_label, 20) || ': ' || NVL(p_value, 'N/A'));
    END line;
  BEGIN
    SELECT factory_name, registration_no, district, compliance_status,
           compliance_score, total_workers, last_audit_date, next_audit_date,
           phone, contact_person
    INTO   v_name, v_reg_no, v_district, v_status,
           v_score, v_workers, v_last_audit, v_next_audit,
           v_phone, v_contact
    FROM   FACTORY
    WHERE  factory_id = p_factory_id;

    SELECT COUNT(*)
    INTO   v_open_grievances
    FROM   GRIEVANCE g
    JOIN   WORKER   w ON g.worker_id = w.worker_id
    WHERE  w.factory_id = p_factory_id
      AND  g.status NOT IN ('Resolved', 'Closed', 'Rejected');

    SELECT COUNT(*)
    INTO   v_active_certs
    FROM   CERTIFICATION
    WHERE  factory_id  = p_factory_id
      AND  status      = 'Active'
      AND  expiry_date > SYSDATE;

    v_expiry_alert := pkg_factory_mgmt.fn_equipment_expiry_alert(p_factory_id);

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
    DBMS_OUTPUT.PUT_LINE('  Thresholds  — Compliant : >= ' || c_compliant_threshold || '   At Risk : >= ' || c_at_risk_threshold);
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

  -- sp_get_factory_workers
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

  -- sp_get_audit_history
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
