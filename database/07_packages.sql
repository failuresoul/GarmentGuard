-- 8. PACKAGES AND STORED PROCEDURES
PROMPT Creating package pkg_error_handler...

CREATE OR REPLACE PACKAGE pkg_error_handler AS
  PROCEDURE log_error(
    p_procedure_name  IN VARCHAR2,
    p_error_code      IN NUMBER,
    p_error_message   IN VARCHAR2,
    p_error_backtrace IN VARCHAR2 DEFAULT NULL
  );
END pkg_error_handler;
/

CREATE OR REPLACE PACKAGE BODY pkg_error_handler AS
  PROCEDURE log_error(
    p_procedure_name  IN VARCHAR2,
    p_error_code      IN NUMBER,
    p_error_message   IN VARCHAR2,
    p_error_backtrace IN VARCHAR2 DEFAULT NULL
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
      p_procedure_name,
      p_error_code,
      p_error_message,
      p_error_backtrace,
      USER
    );
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('FAILED TO LOG ERROR: ' || SQLERRM);
      ROLLBACK;
  END log_error;
END pkg_error_handler;
/

PROMPT Creating package pkg_factory_mgmt...

CREATE OR REPLACE PACKAGE pkg_factory_mgmt AS
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
END pkg_factory_mgmt;
/

CREATE OR REPLACE PACKAGE BODY pkg_factory_mgmt AS

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
      factory_name,
      registration_no,
      address,
      district,
      total_workers,
      compliance_status,
      compliance_score,
      contact_person,
      phone,
      email
    ) VALUES (
      p_name,
      p_reg_no,
      p_address,
      p_district,
      p_workers,
      'Pending',
      NULL,
      p_contact,
      p_phone,
      p_email
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

  PROCEDURE sp_schedule_audit(
    p_factory_id     IN NUMBER,
    p_inspector_id   IN NUMBER,
    p_audit_date     IN DATE
  ) IS
    v_proc_name VARCHAR2(100) := 'pkg_factory_mgmt.sp_schedule_audit';
    v_count     NUMBER;
    v_role      VARCHAR2(50);
  BEGIN
    -- Validate inspector exists and has the 'Inspector' role
    BEGIN
      SELECT role INTO v_role FROM USER_ WHERE user_id = p_inspector_id;
      IF v_role != 'Inspector' THEN
        RAISE_APPLICATION_ERROR(-20005, 'Inspector ID must belong to a user with Inspector role.');
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20006, 'Inspector does not exist.');
    END;

    -- Validate no audit already scheduled this month for same factory
    SELECT COUNT(*) INTO v_count
    FROM "AUDIT"
    WHERE factory_id = p_factory_id
      AND EXTRACT(YEAR FROM audit_date) = EXTRACT(YEAR FROM p_audit_date)
      AND EXTRACT(MONTH FROM audit_date) = EXTRACT(MONTH FROM p_audit_date);

    IF v_count > 0 THEN
      RAISE_APPLICATION_ERROR(-20004, 'An audit is already scheduled for this factory in the specified month.');
    END IF;

    -- Insert scheduled audit
    INSERT INTO "AUDIT" (
      factory_id,
      inspector_id,
      audit_date,
      next_scheduled,
      score,
      result,
      findings,
      recommendations
    ) VALUES (
      p_factory_id,
      p_inspector_id,
      p_audit_date,
      NULL,
      NULL,
      'Pending',
      NULL,
      NULL
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

END pkg_factory_mgmt;
/

PROMPT Creating package pkg_worker_mgmt...

CREATE OR REPLACE PACKAGE pkg_worker_mgmt AS
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
END pkg_worker_mgmt;
/

CREATE OR REPLACE PACKAGE BODY pkg_worker_mgmt AS

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
    -- Validate factory is active (exists and compliance_status != 'Suspended')
    BEGIN
      SELECT compliance_status INTO v_compliance_status
      FROM FACTORY
      WHERE factory_id = p_factory_id;
      
      IF v_compliance_status = 'Suspended' THEN
        RAISE_APPLICATION_ERROR(-20001, 'Factory inactive');
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'Factory inactive');
    END;

    INSERT INTO WORKER (
      factory_id,
      full_name,
      national_id,
      designation,
      join_date,
      base_salary,
      shift,
      status
    ) VALUES (
      p_factory_id,
      p_full_name,
      p_national_id,
      p_designation,
      p_join_date,
      p_base_salary,
      p_shift,
      p_status
    ) RETURNING worker_id INTO p_worker_id;

    -- Update total_workers in FACTORY
    UPDATE FACTORY
    SET total_workers = total_workers + 1
    WHERE factory_id = p_factory_id;

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

  PROCEDURE sp_submit_grievance(
    p_worker_id      IN NUMBER,
    p_category       IN VARCHAR2,
    p_description    IN CLOB,
    p_grievance_id   OUT NUMBER
  ) IS
    v_proc_name VARCHAR2(100) := 'pkg_worker_mgmt.sp_submit_grievance';
  BEGIN
    -- Validate worker exists
    DECLARE
      v_dummy NUMBER;
    BEGIN
      SELECT 1 INTO v_dummy FROM WORKER WHERE worker_id = p_worker_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20007, 'Worker does not exist.');
    END;

    INSERT INTO GRIEVANCE (
      worker_id,
      category,
      description,
      submitted_date,
      status,
      resolved_date,
      resolution_notes
    ) VALUES (
      p_worker_id,
      p_category,
      p_description,
      SYSDATE,
      'Open',
      NULL,
      NULL
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

  PROCEDURE sp_process_salary(
    p_worker_id      IN NUMBER,
    p_month          IN NUMBER,
    p_year           IN NUMBER,
    p_overtime_hours IN NUMBER
  ) IS
    v_proc_name     VARCHAR2(100) := 'pkg_worker_mgmt.sp_process_salary';
    v_count         NUMBER;
    v_base_salary   NUMBER(10,2);
    v_ot_paid       NUMBER(10,2);
    v_net_salary    NUMBER(10,2);
  BEGIN
    -- cap check
    IF p_overtime_hours > 60 THEN
      RAISE_APPLICATION_ERROR(-20002, 'Overtime hours exceed Bangladesh Labour Law cap of 60 hours');
    END IF;

    -- month check
    SELECT COUNT(*) INTO v_count
    FROM SALARY_RECORD
    WHERE worker_id = p_worker_id AND month = p_month AND year = p_year;

    IF v_count > 0 THEN
      RAISE_APPLICATION_ERROR(-20003, 'Month already processed for this worker');
    END IF;

    -- fetch base_salary
    BEGIN
      SELECT base_salary INTO v_base_salary
      FROM WORKER
      WHERE worker_id = p_worker_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20008, 'Worker does not exist');
    END;

    -- calculate overtime_paid = (base_salary/26/8)*1.25*overtime_hours
    v_ot_paid := ROUND((v_base_salary / 26 / 8) * 1.25 * p_overtime_hours, 2);
    v_net_salary := v_base_salary + v_ot_paid;

    INSERT INTO SALARY_RECORD (
      worker_id,
      month,
      year,
      base_amount,
      overtime_hours,
      overtime_paid,
      deductions,
      net_salary,
      payment_status
    ) VALUES (
      p_worker_id,
      p_month,
      p_year,
      v_base_salary,
      p_overtime_hours,
      v_ot_paid,
      0,
      v_net_salary,
      'Pending'
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

END pkg_worker_mgmt;
/
