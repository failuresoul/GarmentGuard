-- 05. PACKAGES SPECIFICATIONS
SET DEFINE OFF
SET SQLBLANKLINES ON

PROMPT Creating package specifications...

-- =============================================================================
-- 1. pkg_error_handler SPECIFICATION
-- =============================================================================
CREATE OR REPLACE PACKAGE pkg_error_handler AS
  PROCEDURE log_error(
    p_proc_name IN VARCHAR2,
    p_sqlcode   IN NUMBER,
    p_sqlerrm   IN VARCHAR2,
    p_stack     IN VARCHAR2 DEFAULT NULL
  );
END pkg_error_handler;
/

-- =============================================================================
-- 2. pkg_reporting SPECIFICATION
-- =============================================================================
CREATE OR REPLACE PACKAGE pkg_reporting AS
  c_compliant_threshold CONSTANT NUMBER := 75;   -- score >= 75  => Compliant
  c_at_risk_threshold   CONSTANT NUMBER := 40;   -- score >= 40  => Partially Compliant
  c_ot_cap              CONSTANT NUMBER := 60;   -- Bangladesh Labour Law OT cap (hours/month)

  PROCEDURE sp_generate_factory_report(p_factory_id IN NUMBER);
  PROCEDURE sp_get_factory_workers(p_factory_id IN NUMBER, p_cursor OUT SYS_REFCURSOR);
  PROCEDURE sp_get_audit_history(p_factory_id IN NUMBER, p_cursor OUT SYS_REFCURSOR);
END pkg_reporting;
/

-- =============================================================================
-- 3. pkg_factory_mgmt SPECIFICATION
-- =============================================================================
CREATE OR REPLACE PACKAGE pkg_factory_mgmt AS
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

  PROCEDURE sp_update_compliance_status(p_factory_id IN NUMBER);

  PROCEDURE sp_schedule_audit(
    p_factory_id   IN NUMBER,
    p_inspector_id IN NUMBER,
    p_audit_date   IN DATE
  );

  FUNCTION fn_compliance_score(p_factory_id IN NUMBER) RETURN NUMBER
    RESULT_CACHE;

  FUNCTION fn_is_cert_valid(
    p_factory_id IN NUMBER,
    p_cert_name  IN VARCHAR2
  ) RETURN CHAR;

  FUNCTION fn_equipment_expiry_alert(p_factory_id IN NUMBER) RETURN VARCHAR2;
END pkg_factory_mgmt;
/

-- =============================================================================
-- 4. pkg_worker_mgmt SPECIFICATION
-- =============================================================================
CREATE OR REPLACE PACKAGE pkg_worker_mgmt AS
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

  PROCEDURE sp_process_salary(
    p_worker_id      IN NUMBER,
    p_month          IN NUMBER,
    p_year           IN NUMBER,
    p_overtime_hours IN NUMBER
  );

  PROCEDURE sp_submit_grievance(
    p_worker_id    IN  NUMBER,
    p_category     IN  VARCHAR2,
    p_description  IN  CLOB,
    p_grievance_id OUT NUMBER
  );

  FUNCTION fn_worker_ytd_salary(
    p_worker_id IN NUMBER,
    p_year      IN NUMBER
  ) RETURN NUMBER;

  FUNCTION fn_grievance_resolution_days(p_grievance_id IN NUMBER) RETURN NUMBER;
END pkg_worker_mgmt;
/
