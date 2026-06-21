-- GarmentGuard Production Database Schema DDL
-- Database Platform: Oracle Database XE 11g (11.2)
-- Bangladesh RMG Compliance Industry Database

SET ECHO ON
SET FEEDBACK ON
SET SERVEROUTPUT ON

--------------------------------------------------------------------------------
-- 1. SAFE DROP CLEANUP
--------------------------------------------------------------------------------

PROMPT Dropping existing schema elements if they exist...

BEGIN
  FOR r IN (SELECT table_name FROM user_tables WHERE table_name IN (
    'BUYER_FACTORY', 'SALARY_RECORD', 'GRIEVANCE', 'SAFETY_EQUIPMENT',
    'CERTIFICATION', 'AUDIT', 'WORKER', 'USER_', 'BUYER', 'FACTORY'
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
    'SAFETY_EQUIPMENT_SEQ', 'GRIEVANCE_SEQ', 'SALARY_RECORD_SEQ', 'BUYER_SEQ'
  )) LOOP
    EXECUTE IMMEDIATE 'DROP SEQUENCE ' || r.sequence_name;
  END LOOP;
END;
/

--------------------------------------------------------------------------------
-- 2. SEQUENCE CREATION
--------------------------------------------------------------------------------

PROMPT Creating sequences for surrogate primary keys...

CREATE SEQUENCE FACTORY_SEQ START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE BUYER_SEQ START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE USER_SEQ START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE WORKER_SEQ START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE AUDIT_SEQ START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE CERTIFICATION_SEQ START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SAFETY_EQUIPMENT_SEQ START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE GRIEVANCE_SEQ START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SALARY_RECORD_SEQ START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

--------------------------------------------------------------------------------
-- 3. TABLE CREATION WITH CONSTRAINTS
--------------------------------------------------------------------------------

PROMPT Creating tables...

-- FACTORY
CREATE TABLE FACTORY (
  factory_id NUMBER(10) CONSTRAINT pk_factory PRIMARY KEY,
  factory_name VARCHAR2(255) NOT NULL,
  registration_no VARCHAR2(100) NOT NULL CONSTRAINT uq_factory_reg_no UNIQUE,
  address VARCHAR2(500) NOT NULL,
  district VARCHAR2(100) NOT NULL,
  total_workers NUMBER(6) DEFAULT 0 NOT NULL CONSTRAINT chk_factory_workers CHECK (total_workers >= 0),
  compliance_status VARCHAR2(50) NOT NULL CONSTRAINT chk_factory_compliance CHECK (compliance_status IN ('Compliant', 'Non-Compliant', 'Pending', 'Suspended')),
  compliance_score FLOAT CONSTRAINT chk_factory_score CHECK (compliance_score BETWEEN 0 AND 100),
  last_audit_date DATE,
  next_audit_date DATE,
  contact_person VARCHAR2(150),
  phone VARCHAR2(50) NOT NULL,
  email VARCHAR2(150) NOT NULL CONSTRAINT uq_factory_email UNIQUE CONSTRAINT chk_factory_email CHECK (REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')),
  CONSTRAINT chk_factory_audit_dates CHECK (next_audit_date >= last_audit_date OR next_audit_date IS NULL OR last_audit_date IS NULL)
);

-- BUYER
CREATE TABLE BUYER (
  buyer_id NUMBER(10) CONSTRAINT pk_buyer PRIMARY KEY,
  buyer_name VARCHAR2(255) NOT NULL,
  country VARCHAR2(100) NOT NULL,
  contact_name VARCHAR2(150),
  email VARCHAR2(150) NOT NULL CONSTRAINT uq_buyer_email UNIQUE CONSTRAINT chk_buyer_email CHECK (REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')),
  phone VARCHAR2(50),
  brand_name VARCHAR2(150)
);

-- USER_ (Reserved keyword USER avoided by trailing underscore)
CREATE TABLE USER_ (
  user_id NUMBER(10) CONSTRAINT pk_user PRIMARY KEY,
  username VARCHAR2(50) NOT NULL CONSTRAINT uq_user_username UNIQUE,
  password_hash VARCHAR2(255) NOT NULL,
  role VARCHAR2(50) NOT NULL CONSTRAINT chk_user_role CHECK (role IN ('Admin', 'Inspector', 'Factory_Manager', 'Compliance_Officer', 'Buyer_Representative')),
  full_name VARCHAR2(150) NOT NULL,
  factory_id NUMBER(10) CONSTRAINT fk_user_factory REFERENCES FACTORY(factory_id) ON DELETE SET NULL,
  email VARCHAR2(150) NOT NULL CONSTRAINT uq_user_email UNIQUE CONSTRAINT chk_user_email CHECK (REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')),
  status VARCHAR2(20) DEFAULT 'Active' NOT NULL CONSTRAINT chk_user_status CHECK (status IN ('Active', 'Inactive', 'Suspended'))
);

-- WORKER
CREATE TABLE WORKER (
  worker_id NUMBER(10) CONSTRAINT pk_worker PRIMARY KEY,
  factory_id NUMBER(10) NOT NULL CONSTRAINT fk_worker_factory REFERENCES FACTORY(factory_id) ON DELETE CASCADE,
  full_name VARCHAR2(150) NOT NULL,
  national_id VARCHAR2(50) NOT NULL CONSTRAINT uq_worker_nid UNIQUE,
  designation VARCHAR2(100) NOT NULL,
  join_date DATE NOT NULL,
  base_salary NUMBER(10,2) NOT NULL CONSTRAINT chk_worker_salary CHECK (base_salary > 0),
  shift VARCHAR2(20) NOT NULL CONSTRAINT chk_worker_shift CHECK (shift IN ('Day', 'Night', 'Roster')),
  status VARCHAR2(20) DEFAULT 'Active' NOT NULL CONSTRAINT chk_worker_status CHECK (status IN ('Active', 'Inactive', 'Suspended', 'Terminated'))
);

-- AUDIT
CREATE TABLE "AUDIT" (
  audit_id NUMBER(10) CONSTRAINT pk_audit PRIMARY KEY,
  factory_id NUMBER(10) NOT NULL CONSTRAINT fk_audit_factory REFERENCES FACTORY(factory_id) ON DELETE CASCADE,
  inspector_id NUMBER(10) NOT NULL CONSTRAINT fk_audit_inspector REFERENCES USER_(user_id),
  audit_date DATE NOT NULL,
  next_scheduled DATE,
  score FLOAT CONSTRAINT chk_audit_score CHECK (score BETWEEN 0 AND 100),
  result VARCHAR2(50) NOT NULL CONSTRAINT chk_audit_result CHECK (result IN ('Passed', 'Failed', 'Conditional', 'Pending')),
  findings CLOB,
  recommendations CLOB,
  CONSTRAINT chk_audit_dates CHECK (next_scheduled >= audit_date OR next_scheduled IS NULL)
);

-- CERTIFICATION
CREATE TABLE CERTIFICATION (
  cert_id NUMBER(10) CONSTRAINT pk_certification PRIMARY KEY,
  factory_id NUMBER(10) NOT NULL CONSTRAINT fk_cert_factory REFERENCES FACTORY(factory_id) ON DELETE CASCADE,
  cert_name VARCHAR2(150) NOT NULL,
  issuing_body VARCHAR2(150) NOT NULL,
  issue_date DATE NOT NULL,
  expiry_date DATE NOT NULL,
  status VARCHAR2(20) NOT NULL CONSTRAINT chk_cert_status CHECK (status IN ('Active', 'Expired', 'Revoked', 'Pending')),
  CONSTRAINT chk_cert_dates CHECK (expiry_date >= issue_date)
);

-- SAFETY_EQUIPMENT
CREATE TABLE SAFETY_EQUIPMENT (
  equipment_id NUMBER(10) CONSTRAINT pk_safety_equip PRIMARY KEY,
  factory_id NUMBER(10) NOT NULL CONSTRAINT fk_equip_factory REFERENCES FACTORY(factory_id) ON DELETE CASCADE,
  equipment_type VARCHAR2(100) NOT NULL,
  quantity NUMBER(6) NOT NULL CONSTRAINT chk_equip_quantity CHECK (quantity >= 0),
  purchase_date DATE NOT NULL,
  expiry_date DATE,
  last_inspection DATE,
  condition_status VARCHAR2(50) NOT NULL CONSTRAINT chk_equip_condition CHECK (condition_status IN ('Excellent', 'Good', 'Fair', 'Poor', 'Damaged', 'Expired')),
  location VARCHAR2(255) NOT NULL,
  CONSTRAINT chk_equip_dates CHECK (expiry_date >= purchase_date OR expiry_date IS NULL),
  CONSTRAINT chk_equip_insp CHECK (last_inspection >= purchase_date OR last_inspection IS NULL)
);

-- GRIEVANCE
CREATE TABLE GRIEVANCE (
  grievance_id NUMBER(10) CONSTRAINT pk_grievance PRIMARY KEY,
  worker_id NUMBER(10) NOT NULL CONSTRAINT fk_grievance_worker REFERENCES WORKER(worker_id) ON DELETE CASCADE,
  category VARCHAR2(100) NOT NULL CONSTRAINT chk_grievance_category CHECK (category IN ('Salary', 'Harassment', 'Working Hours', 'Safety', 'Leave', 'Other')),
  description CLOB NOT NULL,
  submitted_date DATE NOT NULL,
  status VARCHAR2(20) DEFAULT 'Pending' NOT NULL CONSTRAINT chk_grievance_status CHECK (status IN ('Pending', 'Investigating', 'Resolved', 'Rejected')),
  resolved_date DATE,
  resolution_notes CLOB,
  CONSTRAINT chk_grievance_dates CHECK (resolved_date >= submitted_date OR resolved_date IS NULL)
);

-- SALARY_RECORD
CREATE TABLE SALARY_RECORD (
  record_id NUMBER(10) CONSTRAINT pk_salary_rec PRIMARY KEY,
  worker_id NUMBER(10) NOT NULL CONSTRAINT fk_salary_worker REFERENCES WORKER(worker_id) ON DELETE CASCADE,
  month NUMBER(2) NOT NULL CONSTRAINT chk_salary_month CHECK (month BETWEEN 1 AND 12),
  year NUMBER(4) NOT NULL CONSTRAINT chk_salary_year CHECK (year BETWEEN 2000 AND 2100),
  base_amount NUMBER(10,2) NOT NULL CONSTRAINT chk_salary_base CHECK (base_amount >= 0),
  overtime_hours FLOAT DEFAULT 0 NOT NULL CONSTRAINT chk_salary_ot_hours CHECK (overtime_hours >= 0),
  overtime_paid NUMBER(10,2) DEFAULT 0 NOT NULL CONSTRAINT chk_salary_ot_paid CHECK (overtime_paid >= 0),
  deductions NUMBER(10,2) DEFAULT 0 NOT NULL CONSTRAINT chk_salary_deductions CHECK (deductions >= 0),
  net_salary NUMBER(10,2) NOT NULL CONSTRAINT chk_salary_net CHECK (net_salary >= 0),
  payment_status VARCHAR2(20) DEFAULT 'Unpaid' NOT NULL CONSTRAINT chk_salary_payment CHECK (payment_status IN ('Paid', 'Unpaid', 'Partially Paid', 'Hold')),
  CONSTRAINT uq_salary_record UNIQUE (worker_id, month, year)
);

-- BUYER_FACTORY
CREATE TABLE BUYER_FACTORY (
  buyer_id NUMBER(10) NOT NULL CONSTRAINT fk_bf_buyer REFERENCES BUYER(buyer_id) ON DELETE CASCADE,
  factory_id NUMBER(10) NOT NULL CONSTRAINT fk_bf_factory REFERENCES FACTORY(factory_id) ON DELETE CASCADE,
  since_date DATE NOT NULL,
  contract_status VARCHAR2(50) DEFAULT 'Active' NOT NULL CONSTRAINT chk_bf_status CHECK (contract_status IN ('Active', 'Terminated', 'Suspended', 'Pending')),
  CONSTRAINT pk_buyer_factory PRIMARY KEY (buyer_id, factory_id)
);

--------------------------------------------------------------------------------
-- 4. BEFORE INSERT TRIGGERS FOR AUTO-INCREMENT (Oracle 11g compatibility)
--------------------------------------------------------------------------------

PROMPT Creating triggers for primary key generation...

CREATE OR REPLACE TRIGGER FACTORY_BI
BEFORE INSERT ON FACTORY
FOR EACH ROW
BEGIN
  IF :NEW.factory_id IS NULL THEN
    SELECT FACTORY_SEQ.NEXTVAL INTO :NEW.factory_id FROM DUAL;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER BUYER_BI
BEFORE INSERT ON BUYER
FOR EACH ROW
BEGIN
  IF :NEW.buyer_id IS NULL THEN
    SELECT BUYER_SEQ.NEXTVAL INTO :NEW.buyer_id FROM DUAL;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER USER_BI
BEFORE INSERT ON USER_
FOR EACH ROW
BEGIN
  IF :NEW.user_id IS NULL THEN
    SELECT USER_SEQ.NEXTVAL INTO :NEW.user_id FROM DUAL;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER WORKER_BI
BEFORE INSERT ON WORKER
FOR EACH ROW
BEGIN
  IF :NEW.worker_id IS NULL THEN
    SELECT WORKER_SEQ.NEXTVAL INTO :NEW.worker_id FROM DUAL;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER AUDIT_BI
BEFORE INSERT ON "AUDIT"
FOR EACH ROW
BEGIN
  IF :NEW.audit_id IS NULL THEN
    SELECT AUDIT_SEQ.NEXTVAL INTO :NEW.audit_id FROM DUAL;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER CERTIFICATION_BI
BEFORE INSERT ON CERTIFICATION
FOR EACH ROW
BEGIN
  IF :NEW.cert_id IS NULL THEN
    SELECT CERTIFICATION_SEQ.NEXTVAL INTO :NEW.cert_id FROM DUAL;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER SAFETY_EQUIPMENT_BI
BEFORE INSERT ON SAFETY_EQUIPMENT
FOR EACH ROW
BEGIN
  IF :NEW.equipment_id IS NULL THEN
    SELECT SAFETY_EQUIPMENT_SEQ.NEXTVAL INTO :NEW.equipment_id FROM DUAL;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER GRIEVANCE_BI
BEFORE INSERT ON GRIEVANCE
FOR EACH ROW
BEGIN
  IF :NEW.grievance_id IS NULL THEN
    SELECT GRIEVANCE_SEQ.NEXTVAL INTO :NEW.grievance_id FROM DUAL;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER SALARY_RECORD_BI
BEFORE INSERT ON SALARY_RECORD
FOR EACH ROW
BEGIN
  IF :NEW.record_id IS NULL THEN
    SELECT SALARY_RECORD_SEQ.NEXTVAL INTO :NEW.record_id FROM DUAL;
  END IF;
END;
/

--------------------------------------------------------------------------------
-- 5. COMMENTS ON TABLES AND COLUMNS
--------------------------------------------------------------------------------

PROMPT Creating comments on tables and columns...

-- FACTORY Comments
COMMENT ON TABLE FACTORY IS 'Stores information about RMG factories registered for compliance monitoring.';
COMMENT ON COLUMN FACTORY.factory_id IS 'Unique identifier (Surrogate Primary Key) for each factory.';
COMMENT ON COLUMN FACTORY.factory_name IS 'Official name of the RMG factory.';
COMMENT ON COLUMN FACTORY.registration_no IS 'Official government/regulatory registration number of the factory.';
COMMENT ON COLUMN FACTORY.address IS 'Physical address where the factory is located.';
COMMENT ON COLUMN FACTORY.district IS 'District in Bangladesh where the factory resides (e.g., Dhaka, Gazipur).';
COMMENT ON COLUMN FACTORY.total_workers IS 'Current total count of active workers employed in the factory.';
COMMENT ON COLUMN FACTORY.compliance_status IS 'Overall compliance status of the factory (e.g., Compliant, Non-Compliant).';
COMMENT ON COLUMN FACTORY.compliance_score IS 'Numerical compliance evaluation score ranging from 0.0 to 100.0.';
COMMENT ON COLUMN FACTORY.last_audit_date IS 'Date when the most recent safety and compliance audit was conducted.';
COMMENT ON COLUMN FACTORY.next_audit_date IS 'Scheduled date for the next safety and compliance audit.';
COMMENT ON COLUMN FACTORY.contact_person IS 'Name of the factory primary liaison officer.';
COMMENT ON COLUMN FACTORY.phone IS 'Official contact telephone number for the factory.';
COMMENT ON COLUMN FACTORY.email IS 'Official email address for communication with the factory.';

-- BUYER Comments
COMMENT ON TABLE BUYER IS 'Stores details of international fashion brands and buyers sourcing RMG products.';
COMMENT ON COLUMN BUYER.buyer_id IS 'Unique identifier (Primary Key) for each buyer brand.';
COMMENT ON COLUMN BUYER.buyer_name IS 'Official corporate name of the buyer.';
COMMENT ON COLUMN BUYER.country IS 'Country of origin / corporate headquarters of the buyer.';
COMMENT ON COLUMN BUYER.contact_name IS 'Name of the main representative or account manager for the buyer.';
COMMENT ON COLUMN BUYER.email IS 'Official corporate email address for the buyer.';
COMMENT ON COLUMN BUYER.phone IS 'Telephone number for buyer inquiries.';
COMMENT ON COLUMN BUYER.brand_name IS 'Global commercial brand name of the buyer (if different from corporate name).';

-- USER_ Comments
COMMENT ON TABLE USER_ IS 'Stores registered application users including administrators, inspectors, and factory managers.';
COMMENT ON COLUMN USER_.user_id IS 'Unique identifier (Primary Key) for the user.';
COMMENT ON COLUMN USER_.username IS 'Unique login name for authentication.';
COMMENT ON COLUMN USER_.password_hash IS 'Cryptographically hashed password string.';
COMMENT ON COLUMN USER_.role IS 'System authorization role (e.g., Admin, Inspector, Factory_Manager).';
COMMENT ON COLUMN USER_.full_name IS 'Full personal name of the user.';
COMMENT ON COLUMN USER_.factory_id IS 'Foreign key linking the user to a specific factory (null for external inspectors/admins).';
COMMENT ON COLUMN USER_.email IS 'Email address associated with the user account.';
COMMENT ON COLUMN USER_.status IS 'Account status indicating if user is Active, Inactive, or Suspended.';

-- WORKER Comments
COMMENT ON TABLE WORKER IS 'Stores details of factory floor workers employed in the RMG factories.';
COMMENT ON COLUMN WORKER.worker_id IS 'Unique identifier (Primary Key) for the worker.';
COMMENT ON COLUMN WORKER.factory_id IS 'Foreign key linking the worker to their current factory.';
COMMENT ON COLUMN WORKER.full_name IS 'Full legal name of the worker.';
COMMENT ON COLUMN WORKER.national_id IS 'Unique National Identification (NID) card number of the worker.';
COMMENT ON COLUMN WORKER.designation IS 'Job title or role of the worker (e.g., Operator, Quality Controller).';
COMMENT ON COLUMN WORKER.join_date IS 'The date the worker officially joined the factory.';
COMMENT ON COLUMN WORKER.base_salary IS 'Monthly base salary of the worker in BDT.';
COMMENT ON COLUMN WORKER.shift IS 'Working shift assigned to the worker (Day, Night, or Roster).';
COMMENT ON COLUMN WORKER.status IS 'Employment status of the worker (Active, Inactive, Suspended, Terminated).';

-- AUDIT Comments
COMMENT ON TABLE "AUDIT" IS 'Stores records of safety and compliance audits conducted at factories.';
COMMENT ON COLUMN "AUDIT".audit_id IS 'Unique identifier (Primary Key) for the audit log.';
COMMENT ON COLUMN "AUDIT".factory_id IS 'Foreign key identifying the audited factory.';
COMMENT ON COLUMN "AUDIT".inspector_id IS 'Foreign key identifying the user who performed the audit.';
COMMENT ON COLUMN "AUDIT".audit_date IS 'Date when the audit took place.';
COMMENT ON COLUMN "AUDIT".next_scheduled IS 'Suggested or scheduled date for the next audit.';
COMMENT ON COLUMN "AUDIT".score IS 'Compliance audit score awarded to the factory (0.0 to 100.0).';
COMMENT ON COLUMN "AUDIT".result IS 'Audit result outcome (Passed, Failed, Conditional, Pending).';
COMMENT ON COLUMN "AUDIT".findings IS 'Detailed text notes on issues, safety hazards, or compliance violations observed.';
COMMENT ON COLUMN "AUDIT".recommendations IS 'Detailed corrective actions and safety recommendations prescribed.';

-- CERTIFICATION Comments
COMMENT ON TABLE CERTIFICATION IS 'Tracks safety, structural, or ethical compliance certificates issued to factories.';
COMMENT ON COLUMN CERTIFICATION.cert_id IS 'Unique identifier (Primary Key) for the certification record.';
COMMENT ON COLUMN CERTIFICATION.factory_id IS 'Foreign key identifying the factory holding the certificate.';
COMMENT ON COLUMN CERTIFICATION.cert_name IS 'Name of the certificate (e.g., Accord, Alliance, LEED, WRAP).';
COMMENT ON COLUMN CERTIFICATION.issuing_body IS 'Authority or organization that issued the certificate.';
COMMENT ON COLUMN CERTIFICATION.issue_date IS 'Date the certificate was officially granted.';
COMMENT ON COLUMN CERTIFICATION.expiry_date IS 'Expiration date of the certificate.';
COMMENT ON COLUMN CERTIFICATION.status IS 'Current status of the certificate (Active, Expired, Revoked, Pending).';

-- SAFETY_EQUIPMENT Comments
COMMENT ON TABLE SAFETY_EQUIPMENT IS 'Logs structural and operational safety equipment present at factories.';
COMMENT ON COLUMN SAFETY_EQUIPMENT.equipment_id IS 'Unique identifier (Primary Key) for the safety equipment entry.';
COMMENT ON COLUMN SAFETY_EQUIPMENT.factory_id IS 'Foreign key identifying the factory where the equipment is stationed.';
COMMENT ON COLUMN SAFETY_EQUIPMENT.equipment_type IS 'Type of safety equipment (e.g., Fire Extinguisher, Sprinkler, PPE).';
COMMENT ON COLUMN SAFETY_EQUIPMENT.quantity IS 'Total count of units of this equipment category.';
COMMENT ON COLUMN SAFETY_EQUIPMENT.purchase_date IS 'Date when this safety equipment batch was purchased.';
COMMENT ON COLUMN SAFETY_EQUIPMENT.expiry_date IS 'Expiry or service life end date for the equipment (if applicable).';
COMMENT ON COLUMN SAFETY_EQUIPMENT.last_inspection IS 'The date this equipment batch was last checked for functionality.';
COMMENT ON COLUMN SAFETY_EQUIPMENT.condition_status IS 'Physical state of the equipment (Excellent, Good, Fair, Poor, Damaged, Expired).';
COMMENT ON COLUMN SAFETY_EQUIPMENT.location IS 'Specific area or zone inside the factory building where the equipment is located.';

-- GRIEVANCE Comments
COMMENT ON TABLE GRIEVANCE IS 'Logs compliance and labor standard complaints filed by factory workers.';
COMMENT ON COLUMN GRIEVANCE.grievance_id IS 'Unique identifier (Primary Key) for the grievance entry.';
COMMENT ON COLUMN GRIEVANCE.worker_id IS 'Foreign key referencing the worker who submitted the grievance.';
COMMENT ON COLUMN GRIEVANCE.category IS 'Grievance classification category (e.g., Salary, Harassment, Safety).';
COMMENT ON COLUMN GRIEVANCE.description IS 'Comprehensive text description of the grievance.';
COMMENT ON COLUMN GRIEVANCE.submitted_date IS 'The date the grievance was logged into the system.';
COMMENT ON COLUMN GRIEVANCE.status IS 'Current resolution status of the grievance (Pending, Investigating, Resolved, Rejected).';
COMMENT ON COLUMN GRIEVANCE.resolved_date IS 'The date when a resolution or decision was finalized.';
COMMENT ON COLUMN GRIEVANCE.resolution_notes IS 'Notes describing actions taken, explanations, or resolution details.';

-- SALARY_RECORD Comments
COMMENT ON TABLE SALARY_RECORD IS 'Stores historical monthly payroll records for workers to monitor minimum wage compliance.';
COMMENT ON COLUMN SALARY_RECORD.record_id IS 'Unique identifier (Primary Key) for the salary sheet entry.';
COMMENT ON COLUMN SALARY_RECORD.worker_id IS 'Foreign key identifying the worker receiving the pay.';
COMMENT ON COLUMN SALARY_RECORD.month IS 'Numbered month of the payroll period (1 to 12).';
COMMENT ON COLUMN SALARY_RECORD.year IS 'Calendar year of the payroll period (e.g., 2026).';
COMMENT ON COLUMN SALARY_RECORD.base_amount IS 'The base pay amount disbursed to the worker for the month in BDT.';
COMMENT ON COLUMN SALARY_RECORD.overtime_hours IS 'Total number of overtime hours worked during the month.';
COMMENT ON COLUMN SALARY_RECORD.overtime_paid IS 'Amount of overtime compensation paid to the worker in BDT.';
COMMENT ON COLUMN SALARY_RECORD.deductions IS 'Any deductions from the salary (e.g., unpaid leaves, advances) in BDT.';
COMMENT ON COLUMN SALARY_RECORD.net_salary IS 'Net salary paid (base_amount + overtime_paid - deductions) in BDT.';
COMMENT ON COLUMN SALARY_RECORD.payment_status IS 'Disbursal status (Paid, Unpaid, Partially Paid, Hold).';

-- BUYER_FACTORY Comments
COMMENT ON TABLE BUYER_FACTORY IS 'Junction table mapping the sourcing relationships between buyers and RMG factories.';
COMMENT ON COLUMN BUYER_FACTORY.buyer_id IS 'Foreign key referencing the buyer brand.';
COMMENT ON COLUMN BUYER_FACTORY.factory_id IS 'Foreign key referencing the RMG factory.';
COMMENT ON COLUMN BUYER_FACTORY.since_date IS 'The date when the sourcing contract between buyer and factory commenced.';
COMMENT ON COLUMN BUYER_FACTORY.contract_status IS 'State of the sourcing relationship (Active, Terminated, Suspended, Pending).';

--------------------------------------------------------------------------------
-- 6. VERIFICATION QUERY FROM ALL_TABLES
--------------------------------------------------------------------------------

PROMPT Verifying that all 10 tables were successfully created...

COLUMN owner FORMAT A15
COLUMN table_name FORMAT A25

SELECT owner, table_name
FROM all_tables
WHERE owner = USER
  AND table_name IN (
    'FACTORY', 'WORKER', 'USER_', 'AUDIT', 'CERTIFICATION', 
    'SAFETY_EQUIPMENT', 'GRIEVANCE', 'SALARY_RECORD', 'BUYER', 'BUYER_FACTORY'
  )
ORDER BY table_name;

PROMPT Schema DDL Execution Complete.
EXIT;
