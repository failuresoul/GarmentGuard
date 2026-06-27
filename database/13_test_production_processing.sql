-- 13_test_production_processing.sql
-- Verification test suite for production-level processing features.

SET SERVEROUTPUT ON
SET FEEDBACK ON

DECLARE
  v_pending_count NUMBER;
  v_paid_count NUMBER;
  v_alert_count NUMBER;
  v_alert_count2 NUMBER;
  v_record_id NUMBER;
  v_worker_id NUMBER;
  v_equip_id NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('==================================================');
  DBMS_OUTPUT.PUT_LINE('RUNNING PRODUCTION-LEVEL DATA PROCESSING TESTS');
  DBMS_OUTPUT.PUT_LINE('==================================================');

  -- Get a valid worker_id to seed a salary record
  SELECT worker_id INTO v_worker_id FROM WORKER WHERE ROWNUM = 1;

  -- 1. Test sp_bulk_mark_salaries_paid
  DBMS_OUTPUT.PUT_LINE('Test 1: Testing bulk salary updates (Pending -> Paid)...');
  
  -- Create a unique record ID
  SELECT NVL(MAX(record_id), 0) + 1 INTO v_record_id FROM SALARY_RECORD;

  INSERT INTO SALARY_RECORD (record_id, worker_id, month, year, base_amount, overtime_hours, overtime_paid, deductions, net_salary, payment_status)
  VALUES (v_record_id, v_worker_id, 11, 2026, 15000, 10, 500, 0, 15500, 'Pending');

  -- Verify count of Pending before procedure call
  SELECT COUNT(*) INTO v_pending_count FROM SALARY_RECORD WHERE month = 11 AND year = 2026 AND payment_status = 'Pending';
  DBMS_OUTPUT.PUT_LINE('Pending salary count before bulk payment: ' || v_pending_count);

  -- Call procedure
  sp_bulk_mark_salaries_paid(11, 2026);

  -- Verify count of Paid and Pending after procedure call
  SELECT COUNT(*) INTO v_paid_count FROM SALARY_RECORD WHERE month = 11 AND year = 2026 AND payment_status = 'Paid';
  SELECT COUNT(*) INTO v_pending_count FROM SALARY_RECORD WHERE month = 11 AND year = 2026 AND payment_status = 'Pending';
  
  IF v_paid_count = 1 AND v_pending_count = 0 THEN
    DBMS_OUTPUT.PUT_LINE('SUCCESS: Bulk salary marked as Paid.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('FAILURE: Bulk salary update check failed.');
  END IF;

  -- 2. Test sp_check_equipment_expiry
  DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
  DBMS_OUTPUT.PUT_LINE('Test 2: Testing sp_check_equipment_expiry...');

  -- Insert a safety equipment expiring in 15 days
  SELECT NVL(MAX(equipment_id), 0) + 1 INTO v_equip_id FROM SAFETY_EQUIPMENT;
  
  INSERT INTO SAFETY_EQUIPMENT (equipment_id, factory_id, equipment_type, quantity, purchase_date, expiry_date, last_inspection, condition_status, location)
  VALUES (v_equip_id, 1, 'Test Helmet', 50, SYSDATE - 100, SYSDATE + 15, SYSDATE - 10, 'Good', 'Store A');

  -- Run expiry safety alert checker
  sp_check_equipment_expiry;

  -- Verify that alert is added
  SELECT COUNT(*) INTO v_alert_count FROM SAFETY_ALERT WHERE equipment_id = v_equip_id AND status = 'Active';
  DBMS_OUTPUT.PUT_LINE('Active safety alerts created for new expiring item: ' || v_alert_count);

  -- Run safety check again (should not duplicate since we have an active alert)
  sp_check_equipment_expiry;
  SELECT COUNT(*) INTO v_alert_count2 FROM SAFETY_ALERT WHERE equipment_id = v_equip_id AND status = 'Active';
  
  IF v_alert_count = 1 AND v_alert_count2 = 1 THEN
    DBMS_OUTPUT.PUT_LINE('SUCCESS: Safety alert generated correctly and idempotency verified.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('FAILURE: Safety alert duplication or creation issue.');
  END IF;

  -- 3. Test explicit cursor block
  DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
  DBMS_OUTPUT.PUT_LINE('Test 3: Testing explicit cursor reports anonymous block...');
  
  -- Run the explicit cursor logic inline to check for compile/runtime issues
  DECLARE
    CURSOR cur_factories IS
      SELECT factory_id, compliance_status FROM FACTORY;
    v_compliant_count NUMBER := 0;
    v_at_risk_count NUMBER := 0;
    v_non_compliant_count NUMBER := 0;
  BEGIN
    FOR r_fac IN cur_factories LOOP
      pkg_reporting.sp_generate_factory_report(r_fac.factory_id);
      IF r_fac.compliance_status = 'Compliant' THEN
        v_compliant_count := v_compliant_count + 1;
      ELSIF r_fac.compliance_status = 'Partially Compliant' THEN
        v_at_risk_count := v_at_risk_count + 1;
      ELSIF r_fac.compliance_status = 'Non-Compliant' THEN
        v_non_compliant_count := v_non_compliant_count + 1;
      END IF;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('SUMMARY: Compliant=' || v_compliant_count || '; At Risk=' || v_at_risk_count || '; Non-Compliant=' || v_non_compliant_count);
  END;

  DBMS_OUTPUT.PUT_LINE('SUCCESS: Explicit cursor block executed.');
  
  -- Clean up test records
  DELETE FROM SAFETY_ALERT WHERE equipment_id = v_equip_id;
  DELETE FROM SAFETY_EQUIPMENT WHERE equipment_id = v_equip_id;
  DELETE FROM SALARY_RECORD WHERE record_id = v_record_id;
  COMMIT;
  
  DBMS_OUTPUT.PUT_LINE('==================================================');
END;
/
