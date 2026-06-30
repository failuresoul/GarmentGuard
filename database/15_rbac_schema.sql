-- 15. ROLE-BASED ACCESS CONTROL SCHEMA
SET DEFINE OFF
SET SQLBLANKLINES ON

PROMPT Altering USER_ table for worker references and roles...

-- Add worker_id and buyer_id to USER_ table (wrapped to run idempotently)
DECLARE
  v_cols NUMBER := 0;
BEGIN
  SELECT COUNT(*) INTO v_cols FROM user_tab_cols WHERE table_name = 'USER_' AND column_name = 'WORKER_ID';
  IF v_cols = 0 THEN
    EXECUTE IMMEDIATE 'ALTER TABLE USER_ ADD worker_id NUMBER(10)';
    EXECUTE IMMEDIATE 'ALTER TABLE USER_ ADD CONSTRAINT fk_user_worker FOREIGN KEY (worker_id) REFERENCES WORKER(worker_id) ON DELETE CASCADE';
  END IF;
  
  SELECT COUNT(*) INTO v_cols FROM user_tab_cols WHERE table_name = 'USER_' AND column_name = 'BUYER_ID';
  IF v_cols = 0 THEN
    EXECUTE IMMEDIATE 'ALTER TABLE USER_ ADD buyer_id NUMBER(10)';
    EXECUTE IMMEDIATE 'ALTER TABLE USER_ ADD CONSTRAINT fk_user_buyer FOREIGN KEY (buyer_id) REFERENCES BUYER(buyer_id) ON DELETE CASCADE';
  END IF;
END;
/

-- Recreate check constraint to allow Worker and Buyer roles
DECLARE
  v_const NUMBER := 0;
BEGIN
  SELECT COUNT(*) INTO v_const FROM user_constraints WHERE constraint_name = 'CHK_USER_ROLE';
  IF v_const > 0 THEN
    EXECUTE IMMEDIATE 'ALTER TABLE USER_ DROP CONSTRAINT CHK_USER_ROLE';
  END IF;
  EXECUTE IMMEDIATE 'ALTER TABLE USER_ ADD CONSTRAINT CHK_USER_ROLE CHECK (role IN (''Admin'', ''Inspector'', ''Factory_Manager'', ''Compliance_Officer'', ''Buyer_Representative'', ''Buyer'', ''Worker''))';
END;
/

PROMPT Creating Database Roles...

BEGIN
  EXECUTE IMMEDIATE 'CREATE ROLE compliance_officer_role';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
  EXECUTE IMMEDIATE 'CREATE ROLE inspector_role';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
  EXECUTE IMMEDIATE 'CREATE ROLE buyer_role';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
  EXECUTE IMMEDIATE 'CREATE ROLE worker_role';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

PROMPT Granting base table privileges to roles...

-- compliance_officer_role
GRANT SELECT, INSERT, UPDATE, DELETE ON FACTORY TO compliance_officer_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON WORKER TO compliance_officer_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON "AUDIT" TO compliance_officer_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON CERTIFICATION TO compliance_officer_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON SAFETY_EQUIPMENT TO compliance_officer_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON GRIEVANCE TO compliance_officer_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON SALARY_RECORD TO compliance_officer_role;

-- inspector_role
GRANT SELECT, INSERT, UPDATE ON FACTORY TO inspector_role;
GRANT SELECT, INSERT, UPDATE ON WORKER TO inspector_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON "AUDIT" TO inspector_role;
GRANT SELECT, INSERT, UPDATE ON CERTIFICATION TO inspector_role;
GRANT SELECT, INSERT, UPDATE ON SAFETY_EQUIPMENT TO inspector_role;
GRANT SELECT ON GRIEVANCE TO inspector_role;

-- buyer_role
GRANT SELECT ON FACTORY TO buyer_role;
GRANT SELECT ON CERTIFICATION TO buyer_role;
GRANT SELECT ON "AUDIT" TO buyer_role;

PROMPT Creating RLS Context Views...

-- Worker's own grievances view using SYS_CONTEXT CLIENT_INFO
CREATE OR REPLACE VIEW vw_my_grievances AS
SELECT * 
FROM GRIEVANCE 
WHERE worker_id = TO_NUMBER(COALESCE(SYS_CONTEXT('USERENV', 'CLIENT_INFO'), '0'));

-- Worker's own salary records view
CREATE OR REPLACE VIEW vw_my_salary_records AS
SELECT * 
FROM SALARY_RECORD 
WHERE worker_id = TO_NUMBER(COALESCE(SYS_CONTEXT('USERENV', 'CLIENT_INFO'), '0'));

PROMPT Granting view privileges to worker_role...

GRANT SELECT, INSERT, UPDATE ON vw_my_grievances TO worker_role;
GRANT SELECT ON vw_my_salary_records TO worker_role;

EXIT;
