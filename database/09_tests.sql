-- 10. PL/SQL STORED PROCEDURES VERIFICATION TESTS
PROMPT Running PL/SQL Stored Procedures Verification Tests...

SET SERVEROUTPUT ON

DECLARE
  v_new_factory_id   NUMBER;
  v_new_worker_id    NUMBER;
  v_dummy_worker_id  NUMBER;
  v_grievance_id     NUMBER;
BEGIN
  -- 1. Test sp_register_factory (Success)
  DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
  DBMS_OUTPUT.PUT_LINE('Test 1: Registering new factory (Dhaka Apparels)...');
  pkg_factory_mgmt.sp_register_factory(
    p_name       => 'Dhaka Apparels Ltd.',
    p_reg_no     => 'REG-DHA-101',
    p_address    => 'Mirpur, Dhaka',
    p_district   => 'Dhaka',
    p_workers    => 0,
    p_contact    => 'Hasan Ali',
    p_phone      => '01722222222',
    p_email      => 'hasan@dhakaapparels.com',
    p_factory_id => v_new_factory_id
  );
  DBMS_OUTPUT.PUT_LINE('SUCCESS: Registered Factory ID = ' || v_new_factory_id);

  -- 2. Test sp_hire_worker on Active Factory (Success)
  DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
  DBMS_OUTPUT.PUT_LINE('Test 2: Hiring worker on active factory...');
  pkg_worker_mgmt.sp_hire_worker(
    p_factory_id  => v_new_factory_id,
    p_full_name   => 'Mofizur Rahman',
    p_national_id => 'NID-99999',
    p_designation => 'Sewing Operator',
    p_join_date   => TO_DATE('2026-06-01', 'YYYY-MM-DD'),
    p_base_salary => 12000,
    p_shift       => 'Morning',
    p_status      => 'Active',
    p_worker_id   => v_new_worker_id
  );
  DBMS_OUTPUT.PUT_LINE('SUCCESS: Hired Worker ID = ' || v_new_worker_id);

  -- 3. Test sp_hire_worker on Suspended Factory (Expect -20001)
  DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
  DBMS_OUTPUT.PUT_LINE('Test 3: Hiring worker on suspended factory (Factory 7)...');
  BEGIN
    pkg_worker_mgmt.sp_hire_worker(
      p_factory_id  => 7,
      p_full_name   => 'Bad Worker',
      p_national_id => 'NID-00000',
      p_designation => 'Helper',
      p_join_date   => SYSDATE,
      p_base_salary => 8000,
      p_shift       => 'Morning',
      p_status      => 'Active',
      p_worker_id   => v_dummy_worker_id
    );
    DBMS_OUTPUT.PUT_LINE('FAILURE: Should have thrown Factory Inactive exception.');
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR CAUGHT: ' || SQLERRM);
  END;

  -- 4. Test sp_schedule_audit (Success)
  DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
  DBMS_OUTPUT.PUT_LINE('Test 4: Scheduling first audit for Dhaka Apparels...');
  pkg_factory_mgmt.sp_schedule_audit(
    p_factory_id   => v_new_factory_id,
    p_inspector_id => 4,
    p_audit_date   => TO_DATE('2026-07-15', 'YYYY-MM-DD')
  );
  DBMS_OUTPUT.PUT_LINE('SUCCESS: Scheduled audit on 2026-07-15');

  -- 5. Test sp_schedule_audit in duplicate month (Expect -20004)
  DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
  DBMS_OUTPUT.PUT_LINE('Test 5: Scheduling duplicate audit in same month...');
  BEGIN
    pkg_factory_mgmt.sp_schedule_audit(
      p_factory_id   => v_new_factory_id,
      p_inspector_id => 4,
      p_audit_date   => TO_DATE('2026-07-20', 'YYYY-MM-DD')
    );
    DBMS_OUTPUT.PUT_LINE('FAILURE: Should have thrown Duplicate Audit exception.');
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR CAUGHT: ' || SQLERRM);
  END;

  -- 6. Test sp_submit_grievance (Success)
  DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
  DBMS_OUTPUT.PUT_LINE('Test 6: Submitting grievance for Mofizur Rahman...');
  pkg_worker_mgmt.sp_submit_grievance(
    p_worker_id    => v_new_worker_id,
    p_category     => 'Safety Concern',
    p_description  => 'Emergency exit is partially blocked by boxes on the 1st floor.',
    p_grievance_id => v_grievance_id
  );
  DBMS_OUTPUT.PUT_LINE('SUCCESS: Grievance ID = ' || v_grievance_id);

  -- 7. Test sp_process_salary (Success)
  DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
  DBMS_OUTPUT.PUT_LINE('Test 7: Processing salary for worker (OT = 45 hrs)...');
  pkg_worker_mgmt.sp_process_salary(
    p_worker_id      => v_new_worker_id,
    p_month          => 6,
    p_year           => 2026,
    p_overtime_hours => 45
  );
  DBMS_OUTPUT.PUT_LINE('SUCCESS: Processed salary for June 2026.');

  -- 8. Test sp_process_salary with OT > 60 (Expect -20002)
  DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
  DBMS_OUTPUT.PUT_LINE('Test 8: Processing salary with OT = 65 hrs (Exceeds limit)...');
  BEGIN
    pkg_worker_mgmt.sp_process_salary(
      p_worker_id      => v_new_worker_id,
      p_month          => 7,
      p_year           => 2026,
      p_overtime_hours => 65
    );
    DBMS_OUTPUT.PUT_LINE('FAILURE: Should have thrown Overtime Cap Exceeded exception.');
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR CAUGHT: ' || SQLERRM);
  END;

  -- 9. Test sp_process_salary for duplicate month (Expect -20003)
  DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
  DBMS_OUTPUT.PUT_LINE('Test 9: Processing salary for June 2026 again (Duplicate)...');
  BEGIN
    pkg_worker_mgmt.sp_process_salary(
      p_worker_id      => v_new_worker_id,
      p_month          => 6,
      p_year           => 2026,
      p_overtime_hours => 20
    );
    DBMS_OUTPUT.PUT_LINE('FAILURE: Should have thrown Duplicate Month exception.');
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR CAUGHT: ' || SQLERRM);
  END;
  DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
END;
/
