-- GARMENTGUARD COMPREHENSIVE DATABASE TEST SUITE
SET DEFINE OFF
SET SERVEROUTPUT ON
SET LINESIZE 150
SET PAGESIZE 100

PROMPT =========================================================================
PROMPT  RUNNING 10 PL/SQL INTEGRITY ASSERTION BLOCKS
PROMPT =========================================================================

PROMPT [1/10] Testing fn_compliance_score for factory 1...
DECLARE
  v_score NUMBER;
BEGIN
  v_score := pkg_factory_mgmt.fn_compliance_score(1);
  IF v_score = 92.5 THEN
    DBMS_OUTPUT.PUT_LINE('BLOCK 1 PASS: fn_compliance_score(1) returned expected score 92.5');
  ELSE
    DBMS_OUTPUT.PUT_LINE('BLOCK 1 FAIL: fn_compliance_score(1) returned ' || v_score);
  END IF;
END;
/

PROMPT [2/10] Testing fn_is_cert_valid for factory 1 (BSCI)...
DECLARE
  v_res CHAR(1);
BEGIN
  v_res := pkg_factory_mgmt.fn_is_cert_valid(1, 'BSCI (Business Social Compliance Initiative)');
  IF v_res = 'Y' THEN
    DBMS_OUTPUT.PUT_LINE('BLOCK 2 PASS: fn_is_cert_valid(1, BSCI) returned Y');
  ELSE
    DBMS_OUTPUT.PUT_LINE('BLOCK 2 FAIL: fn_is_cert_valid(1, BSCI) returned ' || v_res);
  END IF;
END;
/

PROMPT [3/10] Testing sp_process_salary OT limits (> 60 hours cap)...
BEGIN
  pkg_worker_mgmt.sp_process_salary(p_worker_id => 1, p_month => 6, p_year => 2026, p_overtime_hours => 61);
  DBMS_OUTPUT.PUT_LINE('BLOCK 3 FAIL: sp_process_salary did not raise error on 61 OT hours');
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE = -20002 THEN
      DBMS_OUTPUT.PUT_LINE('BLOCK 3 PASS: sp_process_salary raised expected error -20002 on 61 OT hours');
    ELSE
      DBMS_OUTPUT.PUT_LINE('BLOCK 3 FAIL: sp_process_salary raised unexpected error: ' || SQLERRM);
    END IF;
END;
/

PROMPT [4/10] Testing trg_worker_count_sync auto-increment on Worker insert...
DECLARE
  v_before NUMBER;
  v_after NUMBER;
BEGIN
  SELECT total_workers INTO v_before FROM FACTORY WHERE factory_id = 10;
  
  INSERT INTO WORKER (worker_id, factory_id, full_name, national_id, designation, join_date, base_salary, shift, status)
  VALUES (999, 10, 'Temp Worker', 'NID-99999', 'Operator', SYSDATE, 10000, 'Morning', 'Active');
  
  SELECT total_workers INTO v_after FROM FACTORY WHERE factory_id = 10;
  
  DELETE FROM WORKER WHERE worker_id = 999;
  
  IF v_after = v_before + 1 THEN
    DBMS_OUTPUT.PUT_LINE('BLOCK 4 PASS: trg_worker_count_sync successfully incremented factory workers count');
  ELSE
    DBMS_OUTPUT.PUT_LINE('BLOCK 4 FAIL: workers count before: ' || v_before || ', after: ' || v_after);
  END IF;
END;
/

PROMPT [5/10] Testing trg_cert_expiry_guard for past expiry certifications...
BEGIN
  INSERT INTO CERTIFICATION (cert_id, factory_id, cert_name, issuing_body, issue_date, expiry_date, status)
  VALUES (999, 1, 'Past Cert', 'Body', SYSDATE - 10, SYSDATE - 2, 'Active');
  DBMS_OUTPUT.PUT_LINE('BLOCK 5 FAIL: trg_cert_expiry_guard did not block expired certificate');
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE = -20004 THEN
      DBMS_OUTPUT.PUT_LINE('BLOCK 5 PASS: trg_cert_expiry_guard successfully blocked past certificate with -20004');
    ELSE
      DBMS_OUTPUT.PUT_LINE('BLOCK 5 FAIL: trg_cert_expiry_guard raised unexpected error: ' || SQLERRM);
    END IF;
END;
/

PROMPT [6/10] Testing trg_salary_net_calc net computation auto-calc...
DECLARE
  v_net NUMBER;
BEGIN
  INSERT INTO SALARY_RECORD (record_id, worker_id, month, year, base_amount, overtime_hours, overtime_paid, deductions, net_salary, payment_status)
  VALUES (999, 1, 6, 2026, 10000.00, 10, 1000.00, 200.00, 0, 'Pending');
  
  SELECT net_salary INTO v_net FROM SALARY_RECORD WHERE record_id = 999;
  DELETE FROM SALARY_RECORD WHERE record_id = 999;
  
  IF v_net = 10800.00 THEN
    DBMS_OUTPUT.PUT_LINE('BLOCK 6 PASS: trg_salary_net_calc successfully computed net_salary as 10800.00');
  ELSE
    DBMS_OUTPUT.PUT_LINE('BLOCK 6 FAIL: net_salary computed as ' || v_net);
  END IF;
END;
/

PROMPT [7/10] Testing fn_equipment_expiry_alert for factory 2...
DECLARE
  v_res VARCHAR2(4000);
BEGIN
  v_res := pkg_factory_mgmt.fn_equipment_expiry_alert(2);
  IF v_res = 'ALL OK' THEN
    DBMS_OUTPUT.PUT_LINE('BLOCK 7 PASS: fn_equipment_expiry_alert(2) returned expected ALL OK');
  ELSE
    DBMS_OUTPUT.PUT_LINE('BLOCK 7 FAIL: fn_equipment_expiry_alert(2) returned ' || v_res);
  END IF;
END;
/

PROMPT [8/10] Testing fn_worker_ytd_salary for worker 1...
DECLARE
  v_ytd NUMBER;
BEGIN
  v_ytd := pkg_worker_mgmt.fn_worker_ytd_salary(1, 2026);
  IF v_ytd = 27855.04 THEN
    DBMS_OUTPUT.PUT_LINE('BLOCK 8 PASS: fn_worker_ytd_salary(1, 2026) returned correct YTD sum 27855.04');
  ELSE
    DBMS_OUTPUT.PUT_LINE('BLOCK 8 FAIL: fn_worker_ytd_salary(1, 2026) returned ' || v_ytd);
  END IF;
END;
/

PROMPT [9/10] Testing fn_grievance_resolution_days for grievance 1...
DECLARE
  v_days NUMBER;
BEGIN
  v_days := pkg_worker_mgmt.fn_grievance_resolution_days(1);
  IF v_days = 7 THEN
    DBMS_OUTPUT.PUT_LINE('BLOCK 9 PASS: fn_grievance_resolution_days(1) returned correct delta 7 days');
  ELSE
    DBMS_OUTPUT.PUT_LINE('BLOCK 9 FAIL: fn_grievance_resolution_days(1) returned ' || v_days);
  END IF;
END;
/

PROMPT [10/10] Testing sp_hire_worker block in suspended factories (factory 7)...
DECLARE
  v_id NUMBER;
BEGIN
  pkg_worker_mgmt.sp_hire_worker(
    p_factory_id  => 7,
    p_full_name   => 'Forbidden Worker',
    p_national_id => 'NID-XXXXX',
    p_designation => 'Operator',
    p_join_date   => SYSDATE,
    p_base_salary => 10000,
    p_shift       => 'Morning',
    p_status      => 'Active',
    p_worker_id   => v_id
  );
  DBMS_OUTPUT.PUT_LINE('BLOCK 10 FAIL: sp_hire_worker allowed hiring into a suspended factory');
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE = -20001 THEN
      DBMS_OUTPUT.PUT_LINE('BLOCK 10 PASS: sp_hire_worker blocked hiring in suspended factory with -20001');
    ELSE
      DBMS_OUTPUT.PUT_LINE('BLOCK 10 FAIL: sp_hire_worker raised unexpected error: ' || SQLERRM);
    END IF;
END;
/

PROMPT [11/11] Testing sp_schedule_audit and duplicate validation...
DECLARE
  v_count_before NUMBER;
  v_count_after NUMBER;
BEGIN
  -- Schedule audit for Factory 1 in July 2026 (no audit exists yet in July 2026)
  SELECT COUNT(*) INTO v_count_before FROM "AUDIT" WHERE factory_id = 1;

  pkg_factory_mgmt.sp_schedule_audit(
    p_factory_id   => 1,
    p_inspector_id => 4,
    p_audit_date   => TO_DATE('2026-07-15', 'YYYY-MM-DD')
  );

  SELECT COUNT(*) INTO v_count_after FROM "AUDIT" WHERE factory_id = 1;

  -- Try scheduling another audit for same factory in same month (July 2026) -> Should throw -20004
  BEGIN
    pkg_factory_mgmt.sp_schedule_audit(
      p_factory_id   => 1,
      p_inspector_id => 4,
      p_audit_date   => TO_DATE('2026-07-20', 'YYYY-MM-DD')
    );
    DBMS_OUTPUT.PUT_LINE('BLOCK 11 FAIL: Allowed duplicate scheduling in same month');
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE = -20004 THEN
        DBMS_OUTPUT.PUT_LINE('BLOCK 11 PASS: sp_schedule_audit scheduled successfully and blocked duplicate with -20004');
      ELSE
        DBMS_OUTPUT.PUT_LINE('BLOCK 11 FAIL: sp_schedule_audit raised unexpected error: ' || SQLERRM);
      END IF;
  END;

  -- Cleanup
  DELETE FROM "AUDIT" WHERE factory_id = 1 AND audit_date = TO_DATE('2026-07-15', 'YYYY-MM-DD');
  COMMIT;
END;
/

PROMPT =========================================================================
PROMPT  INTEGRITY RUN COMPLETED
PROMPT =========================================================================

EXIT;
