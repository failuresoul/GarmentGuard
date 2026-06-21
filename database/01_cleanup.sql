-- 1. SAFE DROP CLEANUP
PROMPT Dropping existing schema elements if they exist...

BEGIN
  FOR r IN (SELECT table_name FROM user_tables WHERE table_name IN (
    'BUYER_FACTORY', 'SALARY_RECORD', 'GRIEVANCE', 'SAFETY_EQUIPMENT',
    'CERTIFICATION', 'AUDIT', 'WORKER', 'USER_', 'BUYER', 'FACTORY', 'ERROR_LOG'
  )) LOOP
    IF r.table_name = 'AUDIT' THEN
      EXECUTE IMMEDIATE 'DROP TABLE "AUDIT" CASCADE CONSTRAINTS';
    ELSE
      EXECUTE IMMEDIATE 'DROP TABLE ' || r.table_name || ' CASCADE CONSTRAINTS';
    END IF;
  END LOOP;
END;
/

BEGIN
  FOR r IN (SELECT sequence_name FROM user_sequences WHERE sequence_name IN (
    'FACTORY_SEQ', 'WORKER_SEQ', 'USER_SEQ', 'AUDIT_SEQ', 'CERTIFICATION_SEQ',
    'SAFETY_EQUIPMENT_SEQ', 'GRIEVANCE_SEQ', 'SALARY_RECORD_SEQ', 'BUYER_SEQ', 'ERROR_LOG_SEQ'
  )) LOOP
    EXECUTE IMMEDIATE 'DROP SEQUENCE ' || r.sequence_name;
  END LOOP;
END;
/

BEGIN
  FOR r IN (SELECT object_name, object_type FROM user_objects WHERE object_type IN ('PACKAGE', 'PACKAGE BODY') AND object_name IN ('PKG_FACTORY_MGMT', 'PKG_WORKER_MGMT', 'PKG_ERROR_HANDLER')) LOOP
    EXECUTE IMMEDIATE 'DROP ' || r.object_type || ' ' || r.object_name;
  END LOOP;
END;
/
