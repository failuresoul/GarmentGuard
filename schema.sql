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

CREATE SEQUENCE FACTORY_SEQ START WITH 100 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE BUYER_SEQ START WITH 100 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE USER_SEQ START WITH 100 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE WORKER_SEQ START WITH 100 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE AUDIT_SEQ START WITH 100 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE CERTIFICATION_SEQ START WITH 100 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SAFETY_EQUIPMENT_SEQ START WITH 100 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE GRIEVANCE_SEQ START WITH 100 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SALARY_RECORD_SEQ START WITH 100 INCREMENT BY 1 NOCACHE NOCYCLE;

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
  compliance_status VARCHAR2(50) NOT NULL CONSTRAINT chk_factory_compliance CHECK (compliance_status IN ('Compliant', 'Non-Compliant', 'Partially Compliant', 'Pending', 'Suspended')),
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
  shift VARCHAR2(20) NOT NULL CONSTRAINT chk_worker_shift CHECK (shift IN ('Morning', 'Evening', 'Night', 'Day', 'Roster')),
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
  category VARCHAR2(100) NOT NULL CONSTRAINT chk_grievance_category CHECK (category IN ('Salary', 'Harassment', 'Working Hours', 'Safety', 'Leave', 'Other', 'Salary Dispute', 'Safety Concern', 'Overtime Dispute', 'Leave Denial', 'Wrongful Termination')),
  description CLOB NOT NULL,
  submitted_date DATE NOT NULL,
  status VARCHAR2(20) DEFAULT 'Pending' NOT NULL CONSTRAINT chk_grievance_status CHECK (status IN ('Pending', 'Investigating', 'Resolved', 'Rejected', 'Open', 'In Progress', 'Closed')),
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
  payment_status VARCHAR2(20) DEFAULT 'Unpaid' NOT NULL CONSTRAINT chk_salary_payment CHECK (payment_status IN ('Paid', 'Unpaid', 'Partially Paid', 'Hold', 'Pending', 'Partial')),
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
-- 6. INDEX CREATION
--------------------------------------------------------------------------------

PROMPT Creating indexes...

-- Indexes on Foreign Key Columns
CREATE INDEX idx_worker_factory_id ON WORKER(factory_id);
CREATE INDEX idx_audit_factory_id ON "AUDIT"(factory_id);
CREATE INDEX idx_audit_inspector_id ON "AUDIT"(inspector_id);
CREATE INDEX idx_cert_factory_id ON CERTIFICATION(factory_id);
CREATE INDEX idx_safety_eq_factory_id ON SAFETY_EQUIPMENT(factory_id);
CREATE INDEX idx_grievance_worker_id ON GRIEVANCE(worker_id);
CREATE INDEX idx_salary_rec_worker_id ON SALARY_RECORD(worker_id);
CREATE INDEX idx_user_factory_id ON USER_(factory_id);
CREATE INDEX idx_bf_buyer_id ON BUYER_FACTORY(buyer_id);
CREATE INDEX idx_bf_factory_id ON BUYER_FACTORY(factory_id);

-- Composite Indexes
CREATE INDEX idx_audit_fac_date ON "AUDIT"(factory_id, audit_date DESC);
CREATE INDEX idx_salary_rec_date ON SALARY_RECORD(worker_id, year, month);

-- Status and Compliance Indexes
CREATE INDEX idx_factory_compliance_stat ON FACTORY(compliance_status);
CREATE INDEX idx_grievance_status ON GRIEVANCE(status);
CREATE INDEX idx_cert_status ON CERTIFICATION(status);
CREATE INDEX idx_safety_eq_condition_stat ON SAFETY_EQUIPMENT(condition_status);


--------------------------------------------------------------------------------
-- 7. VIEW CREATION
--------------------------------------------------------------------------------

PROMPT Creating views...

-- vw_factory_compliance
CREATE OR REPLACE VIEW vw_factory_compliance AS
SELECT 
  f.factory_id,
  f.factory_name,
  f.registration_no,
  f.address,
  f.district,
  f.contact_person,
  f.phone,
  f.email,
  f.total_workers,
  f.compliance_status,
  f.compliance_score,
  (SELECT MAX(score) KEEP (DENSE_RANK LAST ORDER BY audit_date ASC, audit_id ASC) 
   FROM "AUDIT" a 
   WHERE a.factory_id = f.factory_id) AS latest_audit_score,
  (SELECT COUNT(*) 
   FROM CERTIFICATION c 
   WHERE c.factory_id = f.factory_id AND c.status = 'Active') AS active_certs_count,
  (SELECT COUNT(*) 
   FROM GRIEVANCE g 
   JOIN WORKER w ON g.worker_id = w.worker_id 
   WHERE w.factory_id = f.factory_id AND g.status IN ('Pending', 'Investigating', 'Open', 'In Progress')) AS open_grievances_count
FROM FACTORY f;

-- vw_worker_salary_ytd
CREATE OR REPLACE VIEW vw_worker_salary_ytd AS
SELECT 
  w.worker_id,
  w.full_name,
  f.factory_name,
  f.district,
  w.designation,
  COALESCE(SUM(s.net_salary), 0) AS ytd_net_salary,
  COALESCE(SUM(s.overtime_paid), 0) AS ytd_overtime_paid,
  COUNT(CASE WHEN s.payment_status = 'Paid' THEN 1 END) AS months_paid
FROM WORKER w
JOIN FACTORY f ON w.factory_id = f.factory_id
LEFT JOIN SALARY_RECORD s ON w.worker_id = s.worker_id AND s.year = EXTRACT(YEAR FROM SYSDATE)
GROUP BY w.worker_id, w.full_name, f.factory_name, f.district, w.designation;


--------------------------------------------------------------------------------
-- 8. SEED DATA INSERTION
--------------------------------------------------------------------------------

PROMPT Inserting seed data...

-- FACTORIES (10 rows, all 8 divisions)
INSERT INTO FACTORY (factory_id, factory_name, registration_no, address, district, total_workers, compliance_status, compliance_score, last_audit_date, next_audit_date, contact_person, phone, email)
VALUES (1, 'Dhaka Garments Ltd.', 'REG-DHA-001', 'Ashulia, Savar', 'Dhaka', 3, 'Compliant', 92.5, TO_DATE('2026-03-15', 'YYYY-MM-DD'), TO_DATE('2027-03-15', 'YYYY-MM-DD'), 'M. A. Rahman', '01711111111', 'info@dhakagarments.com');

INSERT INTO FACTORY (factory_id, factory_name, registration_no, address, district, total_workers, compliance_status, compliance_score, last_audit_date, next_audit_date, contact_person, phone, email)
VALUES (2, 'Mirpur Fashion Apparels', 'REG-DHA-002', 'Mirpur-10', 'Dhaka', 3, 'Partially Compliant', 76.0, TO_DATE('2026-04-10', 'YYYY-MM-DD'), TO_DATE('2027-04-10', 'YYYY-MM-DD'), 'Kamil Ahmed', '01711111112', 'info@mirpurfashion.com');

INSERT INTO FACTORY (factory_id, factory_name, registration_no, address, district, total_workers, compliance_status, compliance_score, last_audit_date, next_audit_date, contact_person, phone, email)
VALUES (3, 'Tongi Tex Group', 'REG-GAZ-001', 'Tongi Industrial Area', 'Gazipur', 3, 'Non-Compliant', 45.0, TO_DATE('2026-01-20', 'YYYY-MM-DD'), TO_DATE('2026-07-20', 'YYYY-MM-DD'), 'Shafiqul Alam', '01711111113', 'contact@tongitex.com');

INSERT INTO FACTORY (factory_id, factory_name, registration_no, address, district, total_workers, compliance_status, compliance_score, last_audit_date, next_audit_date, contact_person, phone, email)
VALUES (4, 'Kaliakair Eco-Styles', 'REG-GAZ-002', 'Kaliakair', 'Gazipur', 3, 'Compliant', 88.0, TO_DATE('2026-05-12', 'YYYY-MM-DD'), TO_DATE('2027-05-12', 'YYYY-MM-DD'), 'Farhana Chowdhury', '01711111114', 'eco@kaliakaireco.com');

INSERT INTO FACTORY (factory_id, factory_name, registration_no, address, district, total_workers, compliance_status, compliance_score, last_audit_date, next_audit_date, contact_person, phone, email)
VALUES (5, 'Bayview Apparels Ltd.', 'REG-CTG-001', 'CEPZ, Halishahar', 'Chittagong', 3, 'Compliant', 95.0, TO_DATE('2026-02-18', 'YYYY-MM-DD'), TO_DATE('2027-02-18', 'YYYY-MM-DD'), 'Zahirul Islam', '01711111115', 'info@bayviewctg.com');

INSERT INTO FACTORY (factory_id, factory_name, registration_no, address, district, total_workers, compliance_status, compliance_score, last_audit_date, next_audit_date, contact_person, phone, email)
VALUES (6, 'Sreemangal Quality Knits', 'REG-SYL-001', 'Sreemangal', 'Sylhet', 3, 'Pending', 60.0, TO_DATE('2026-06-01', 'YYYY-MM-DD'), TO_DATE('2026-12-01', 'YYYY-MM-DD'), 'Mohit Lal', '01711111116', 'knits@sreemangalquality.com');

INSERT INTO FACTORY (factory_id, factory_name, registration_no, address, district, total_workers, compliance_status, compliance_score, last_audit_date, next_audit_date, contact_person, phone, email)
VALUES (7, 'Silk City Apparels', 'REG-RAJ-001', 'BSCIC Area', 'Rajshahi', 3, 'Suspended', 30.0, TO_DATE('2025-11-10', 'YYYY-MM-DD'), TO_DATE('2026-05-10', 'YYYY-MM-DD'), 'Aminul Islam', '01711111117', 'info@silkcityraj.com');

INSERT INTO FACTORY (factory_id, factory_name, registration_no, address, district, total_workers, compliance_status, compliance_score, last_audit_date, next_audit_date, contact_person, phone, email)
VALUES (8, 'Rupsha Fashion Tech', 'REG-KHU-001', 'Khalishpur', 'Khulna', 3, 'Partially Compliant', 72.0, TO_DATE('2026-03-05', 'YYYY-MM-DD'), TO_DATE('2026-09-05', 'YYYY-MM-DD'), 'Saiful Bari', '01711111118', 'tech@rupshafashion.com');

INSERT INTO FACTORY (factory_id, factory_name, registration_no, address, district, total_workers, compliance_status, compliance_score, last_audit_date, next_audit_date, contact_person, phone, email)
VALUES (9, 'Kirtankhola Fabrics', 'REG-BAR-001', 'Barishal City', 'Barishal', 3, 'Non-Compliant', 52.0, TO_DATE('2026-02-28', 'YYYY-MM-DD'), TO_DATE('2026-08-28', 'YYYY-MM-DD'), 'Anisur Rahman', '01711111119', 'ops@kirtankholafab.com');

INSERT INTO FACTORY (factory_id, factory_name, registration_no, address, district, total_workers, compliance_status, compliance_score, last_audit_date, next_audit_date, contact_person, phone, email)
VALUES (10, 'Brahmaputra Garment Zone', 'REG-MYM-001', 'Mymensingh Sadar', 'Mymensingh', 3, 'Compliant', 85.0, TO_DATE('2026-05-25', 'YYYY-MM-DD'), TO_DATE('2027-05-25', 'YYYY-MM-DD'), 'Faruk Ahmed', '01711111120', 'admin@brahmaputragz.com');

-- USERS (5 rows)
INSERT INTO USER_ (user_id, username, password_hash, role, full_name, factory_id, email, status)
VALUES (1, 'sysadmin', 'argon2id$v=19$m=65536,t=3,p=4$adminhash', 'Admin', 'Tariqul Islam', NULL, 'admin@garmentguard.org', 'Active');

INSERT INTO USER_ (user_id, username, password_hash, role, full_name, factory_id, email, status)
VALUES (2, 'comp_dhaka', 'argon2id$v=19$m=65536,t=3,p=4$dhakahash', 'Compliance_Officer', 'Rahman Khan', 1, 'rahman@dhakagarments.com', 'Active');

INSERT INTO USER_ (user_id, username, password_hash, role, full_name, factory_id, email, status)
VALUES (3, 'comp_tongi', 'argon2id$v=19$m=65536,t=3,p=4$tongihash', 'Compliance_Officer', 'Nusrat Jahan', 3, 'nusrat@tongitex.com', 'Active');

INSERT INTO USER_ (user_id, username, password_hash, role, full_name, factory_id, email, status)
VALUES (4, 'inspector1', 'argon2id$v=19$m=65536,t=3,p=4$insphash', 'Inspector', 'Kazi Ashraful', NULL, 'kazi.a@garmentguard.org', 'Active');

INSERT INTO USER_ (user_id, username, password_hash, role, full_name, factory_id, email, status)
VALUES (5, 'hm_buyer', 'argon2id$v=19$m=65536,t=3,p=4$buyerhash', 'Buyer_Representative', 'Sven Andersson', NULL, 'sven@hm.com', 'Active');

-- WORKERS (30 rows, 3 per factory)
INSERT INTO WORKER (worker_id, factory_id, full_name, national_id, designation, join_date, base_salary, shift, status)
VALUES (1, 1, 'Abul Kalam', 'NID-10001', 'Sewing Operator', TO_DATE('2022-01-15', 'YYYY-MM-DD'), 12500, 'Morning', 'Active');
INSERT INTO WORKER (worker_id, factory_id, full_name, national_id, designation, join_date, base_salary, shift, status)
VALUES (2, 1, 'Mariam Begum', 'NID-10002', 'Helper', TO_DATE('2023-03-10', 'YYYY-MM-DD'), 9500, 'Evening', 'Active');
INSERT INTO WORKER (worker_id, factory_id, full_name, national_id, designation, join_date, base_salary, shift, status)
VALUES (3, 1, 'Kamrul Hasan', 'NID-10003', 'Floor Supervisor', TO_DATE('2020-05-20', 'YYYY-MM-DD'), 22000, 'Morning', 'Active');

INSERT INTO WORKER (worker_id, factory_id, full_name, national_id, designation, join_date, base_salary, shift, status)
VALUES (4, 2, 'Fatema Tuz Zohra', 'NID-10004', 'Quality Inspector', TO_DATE('2021-08-11', 'YYYY-MM-DD'), 15000, 'Morning', 'Active');
INSERT INTO WORKER (worker_id, factory_id, full_name, national_id, designation, join_date, base_salary, shift, status)
VALUES (5, 2, 'Mohammad Ali', 'NID-10005', 'Cutting Master', TO_DATE('2019-11-01', 'YYYY-MM-DD'), 24000, 'Evening', 'Active');
INSERT INTO WORKER (worker_id, factory_id, full_name, national_id, designation, join_date, base_salary, shift, status)
VALUES (6, 2, 'Rabeya Khatun', 'NID-10006', 'Finishing Operator', TO_DATE('2024-02-15', 'YYYY-MM-DD'), 11000, 'Night', 'Active');

INSERT INTO WORKER (worker_id, factory_id, full_name, national_id, designation, join_date, base_salary, shift, status)
VALUES (7, 3, 'Siddiqur Rahman', 'NID-10007', 'Sewing Operator', TO_DATE('2021-06-25', 'YYYY-MM-DD'), 13000, 'Evening', 'Inactive');
INSERT INTO WORKER (worker_id, factory_id, full_name, national_id, designation, join_date, base_salary, shift, status)
VALUES (8, 3, 'Jahanara Alam', 'NID-10008', 'Helper', TO_DATE('2023-07-01', 'YYYY-MM-DD'), 9000, 'Night', 'Active');
INSERT INTO WORKER (worker_id, factory_id, full_name, national_id, designation, join_date, base_salary, shift, status)
VALUES (9, 3, 'Mustafizur Rahman', 'NID-10009', 'Machine Technician', TO_DATE('2022-09-12', 'YYYY-MM-DD'), 19500, 'Morning', 'Active');

INSERT INTO WORKER (worker_id, factory_id, full_name, national_id, designation, join_date, base_salary, shift, status)
VALUES (10, 4, 'Nasrin Sultana', 'NID-10010', 'Packing Worker', TO_DATE('2023-01-10', 'YYYY-MM-DD'), 10000, 'Morning', 'Active');
INSERT INTO WORKER (worker_id, factory_id, full_name, national_id, designation, join_date, base_salary, shift, status)
VALUES (11, 4, 'Mizanur Rahman', 'NID-10011', 'Sewing Operator', TO_DATE('2022-04-18', 'YYYY-MM-DD'), 12000, 'Evening', 'Active');
INSERT INTO WORKER (worker_id, factory_id, full_name, national_id, designation, join_date, base_salary, shift, status)
VALUES (12, 4, 'Selina Akhter', 'NID-10012', 'Quality Inspector', TO_DATE('2021-03-22', 'YYYY-MM-DD'), 14500, 'Morning', 'Active');

INSERT INTO WORKER (worker_id, factory_id, full_name, national_id, designation, join_date, base_salary, shift, status)
VALUES (13, 5, 'Rokeya Begum', 'NID-10013', 'Finishing Operator', TO_DATE('2020-07-15', 'YYYY-MM-DD'), 11500, 'Evening', 'Active');
INSERT INTO WORKER (worker_id, factory_id, full_name, national_id, designation, join_date, base_salary, shift, status)
VALUES (14, 5, 'Mohammad Yeasin', 'NID-10014', 'Floor Supervisor', TO_DATE('2018-02-10', 'YYYY-MM-DD'), 25000, 'Morning', 'Active');
INSERT INTO WORKER (worker_id, factory_id, full_name, national_id, designation, join_date, base_salary, shift, status)
VALUES (15, 5, 'Rasheda Chowdhury', 'NID-10015', 'Helper', TO_DATE('2023-09-05', 'YYYY-MM-DD'), 9200, 'Night', 'Active');

INSERT INTO WORKER (worker_id, factory_id, full_name, national_id, designation, join_date, base_salary, shift, status)
VALUES (16, 6, 'Abdul Wahab', 'NID-10016', 'Cutting Master', TO_DATE('2020-10-01', 'YYYY-MM-DD'), 23000, 'Morning', 'Active');
INSERT INTO WORKER (worker_id, factory_id, full_name, national_id, designation, join_date, base_salary, shift, status)
VALUES (17, 6, 'Shahnaz Parveen', 'NID-10017', 'Sewing Operator', TO_DATE('2022-12-01', 'YYYY-MM-DD'), 12500, 'Evening', 'Active');
INSERT INTO WORKER (worker_id, factory_id, full_name, national_id, designation, join_date, base_salary, shift, status)
VALUES (18, 6, 'Biplob Barua', 'NID-10018', 'Packing Worker', TO_DATE('2023-11-20', 'YYYY-MM-DD'), 9800, 'Night', 'Inactive');

INSERT INTO WORKER (worker_id, factory_id, full_name, national_id, designation, join_date, base_salary, shift, status)
VALUES (19, 7, 'Anwara Begum', 'NID-10019', 'Helper', TO_DATE('2024-01-05', 'YYYY-MM-DD'), 9000, 'Morning', 'Active');
INSERT INTO WORKER (worker_id, factory_id, full_name, national_id, designation, join_date, base_salary, shift, status)
VALUES (20, 7, 'Tariqul Anam', 'NID-10020', 'Machine Technician', TO_DATE('2021-05-15', 'YYYY-MM-DD'), 18000, 'Evening', 'Active');
INSERT INTO WORKER (worker_id, factory_id, full_name, national_id, designation, join_date, base_salary, shift, status)
VALUES (21, 7, 'Rehana Akhter', 'NID-10021', 'Sewing Operator', TO_DATE('2022-07-28', 'YYYY-MM-DD'), 12000, 'Night', 'Active');

INSERT INTO WORKER (worker_id, factory_id, full_name, national_id, designation, join_date, base_salary, shift, status)
VALUES (22, 8, 'Faruk Hossain', 'NID-10022', 'Sewing Operator', TO_DATE('2022-02-12', 'YYYY-MM-DD'), 13000, 'Morning', 'Active');
INSERT INTO WORKER (worker_id, factory_id, full_name, national_id, designation, join_date, base_salary, shift, status)
VALUES (23, 8, 'Monira Yasmin', 'NID-10023', 'Quality Inspector', TO_DATE('2021-11-05', 'YYYY-MM-DD'), 15500, 'Evening', 'Active');
INSERT INTO WORKER (worker_id, factory_id, full_name, national_id, designation, join_date, base_salary, shift, status)
VALUES (24, 8, 'Imrul Kayes', 'NID-10024', 'Floor Supervisor', TO_DATE('2019-06-30', 'YYYY-MM-DD'), 21000, 'Morning', 'Active');

INSERT INTO WORKER (worker_id, factory_id, full_name, national_id, designation, join_date, base_salary, shift, status)
VALUES (25, 9, 'Nargis Akter', 'NID-10025', 'Finishing Operator', TO_DATE('2023-04-01', 'YYYY-MM-DD'), 10800, 'Evening', 'Active');
INSERT INTO WORKER (worker_id, factory_id, full_name, national_id, designation, join_date, base_salary, shift, status)
VALUES (26, 9, 'Shafiqul Islam', 'NID-10026', 'Helper', TO_DATE('2024-03-10', 'YYYY-MM-DD'), 9100, 'Night', 'Active');
INSERT INTO WORKER (worker_id, factory_id, full_name, national_id, designation, join_date, base_salary, shift, status)
VALUES (27, 9, 'Taslima Nasrin', 'NID-10027', 'Sewing Operator', TO_DATE('2022-08-15', 'YYYY-MM-DD'), 12200, 'Morning', 'Active');

INSERT INTO WORKER (worker_id, factory_id, full_name, national_id, designation, join_date, base_salary, shift, status)
VALUES (28, 10, 'Rafiqul Islam', 'NID-10028', 'Machine Technician', TO_DATE('2021-02-28', 'YYYY-MM-DD'), 19000, 'Morning', 'Active');
INSERT INTO WORKER (worker_id, factory_id, full_name, national_id, designation, join_date, base_salary, shift, status)
VALUES (29, 10, 'Sonia Akter', 'NID-10029', 'Packing Worker', TO_DATE('2023-05-18', 'YYYY-MM-DD'), 9500, 'Evening', 'Active');
INSERT INTO WORKER (worker_id, factory_id, full_name, national_id, designation, join_date, base_salary, shift, status)
VALUES (30, 10, 'Asaduzzaman', 'NID-10030', 'Cutting Master', TO_DATE('2020-04-12', 'YYYY-MM-DD'), 24500, 'Morning', 'Active');

-- BUYERS (5 rows)
INSERT INTO BUYER (buyer_id, buyer_name, country, contact_name, email, phone, brand_name)
VALUES (1, 'H&M', 'Sweden', 'Sven Larsson', 'sourcing@hm.com', '+4687965500', 'H&M');

INSERT INTO BUYER (buyer_id, buyer_name, country, contact_name, email, phone, brand_name)
VALUES (2, 'Walmart', 'USA', 'John Smith', 'supplier@walmart.com', '+14792734000', 'Walmart');

INSERT INTO BUYER (buyer_id, buyer_name, country, contact_name, email, phone, brand_name)
VALUES (3, 'Zara/Inditex', 'Spain', 'Carlos Gomez', 'compliance@inditex.com', '+34981185400', 'Zara');

INSERT INTO BUYER (buyer_id, buyer_name, country, contact_name, email, phone, brand_name)
VALUES (4, 'Primark', 'UK/Ireland', 'Emma Watson', 'ethical@primark.ie', '+442074950000', 'Primark');

INSERT INTO BUYER (buyer_id, buyer_name, country, contact_name, email, phone, brand_name)
VALUES (5, 'Gap Inc.', 'USA', 'Sarah Connor', 'sourcing@gap.com', '+14154270100', 'Gap Inc.');

-- BUYER_FACTORY (8 rows)
INSERT INTO BUYER_FACTORY (buyer_id, factory_id, since_date, contract_status)
VALUES (1, 1, TO_DATE('2022-01-01', 'YYYY-MM-DD'), 'Active');

INSERT INTO BUYER_FACTORY (buyer_id, factory_id, since_date, contract_status)
VALUES (1, 5, TO_DATE('2020-05-10', 'YYYY-MM-DD'), 'Active');

INSERT INTO BUYER_FACTORY (buyer_id, factory_id, since_date, contract_status)
VALUES (2, 2, TO_DATE('2021-03-15', 'YYYY-MM-DD'), 'Active');

INSERT INTO BUYER_FACTORY (buyer_id, factory_id, since_date, contract_status)
VALUES (2, 3, TO_DATE('2022-09-01', 'YYYY-MM-DD'), 'Suspended');

INSERT INTO BUYER_FACTORY (buyer_id, factory_id, since_date, contract_status)
VALUES (3, 4, TO_DATE('2023-01-15', 'YYYY-MM-DD'), 'Active');

INSERT INTO BUYER_FACTORY (buyer_id, factory_id, since_date, contract_status)
VALUES (3, 8, TO_DATE('2022-11-20', 'YYYY-MM-DD'), 'Active');

INSERT INTO BUYER_FACTORY (buyer_id, factory_id, since_date, contract_status)
VALUES (4, 9, TO_DATE('2023-06-01', 'YYYY-MM-DD'), 'Active');

INSERT INTO BUYER_FACTORY (buyer_id, factory_id, since_date, contract_status)
VALUES (5, 10, TO_DATE('2021-08-01', 'YYYY-MM-DD'), 'Active');

-- AUDITS (10 rows)
INSERT INTO "AUDIT" (audit_id, factory_id, inspector_id, audit_date, next_scheduled, score, result, findings, recommendations)
VALUES (1, 1, 4, TO_DATE('2026-03-15', 'YYYY-MM-DD'), TO_DATE('2027-03-15', 'YYYY-MM-DD'), 92.5, 'Passed', 'All emergency exits clear. Structural integrity certified.', 'Continue bi-annual training.');

INSERT INTO "AUDIT" (audit_id, factory_id, inspector_id, audit_date, next_scheduled, score, result, findings, recommendations)
VALUES (2, 2, 4, TO_DATE('2026-04-10', 'YYYY-MM-DD'), TO_DATE('2027-04-10', 'YYYY-MM-DD'), 76.0, 'Conditional', 'Exits locked during lunch break. Fire extinguisher inspection records missing.', 'Unlock all doors immediately. Update extinguisher tag records.');

INSERT INTO "AUDIT" (audit_id, factory_id, inspector_id, audit_date, next_scheduled, score, result, findings, recommendations)
VALUES (3, 3, 4, TO_DATE('2026-01-20', 'YYYY-MM-DD'), TO_DATE('2026-07-20', 'YYYY-MM-DD'), 45.0, 'Failed', 'Exposed wiring on 2nd floor sewing line. Structural crack in pillars.', 'Immediate electrical rewire required. Hire certified structural engineer.');

INSERT INTO "AUDIT" (audit_id, factory_id, inspector_id, audit_date, next_scheduled, score, result, findings, recommendations)
VALUES (4, 4, 4, TO_DATE('2026-05-12', 'YYYY-MM-DD'), TO_DATE('2027-05-12', 'YYYY-MM-DD'), 88.0, 'Passed', 'Adequate lighting. Minor exhaust fan dust accumulation.', 'Clean ventilation shafts monthly.');

INSERT INTO "AUDIT" (audit_id, factory_id, inspector_id, audit_date, next_scheduled, score, result, findings, recommendations)
VALUES (5, 5, 4, TO_DATE('2026-02-18', 'YYYY-MM-DD'), TO_DATE('2027-02-18', 'YYYY-MM-DD'), 95.0, 'Passed', 'Top-tier fire drill preparedness. Modern evacuation layout.', 'Promote to safety trainer role.');

INSERT INTO "AUDIT" (audit_id, factory_id, inspector_id, audit_date, next_scheduled, score, result, findings, recommendations)
VALUES (6, 6, 4, TO_DATE('2026-06-01', 'YYYY-MM-DD'), TO_DATE('2026-12-01', 'YYYY-MM-DD'), 60.0, 'Conditional', 'No personal protective equipment (PPE) for cutting section workers.', 'Provide steel mesh gloves and masks immediately.');

INSERT INTO "AUDIT" (audit_id, factory_id, inspector_id, audit_date, next_scheduled, score, result, findings, recommendations)
VALUES (7, 7, 4, TO_DATE('2025-11-10', 'YYYY-MM-DD'), TO_DATE('2026-05-10', 'YYYY-MM-DD'), 30.0, 'Failed', 'Child labor suspicion (underage helper). Non-payment of minimum wages.', 'Suspend production. Verify age files of all helpers.');

INSERT INTO "AUDIT" (audit_id, factory_id, inspector_id, audit_date, next_scheduled, score, result, findings, recommendations)
VALUES (8, 8, 4, TO_DATE('2026-03-05', 'YYYY-MM-DD'), TO_DATE('2026-09-05', 'YYYY-MM-DD'), 72.0, 'Conditional', 'First aid kits empty. High temperature in finishing section.', 'Refill first aid boxes. Increase ventilation fans.');

INSERT INTO "AUDIT" (audit_id, factory_id, inspector_id, audit_date, next_scheduled, score, result, findings, recommendations)
VALUES (9, 9, 4, TO_DATE('2026-02-28', 'YYYY-MM-DD'), TO_DATE('2026-08-28', 'YYYY-MM-DD'), 52.0, 'Failed', 'Expired fire alarms. Aisles blocked with fabric rolls.', 'Replace alarm batteries. Clear all walkways.');

INSERT INTO "AUDIT" (audit_id, factory_id, inspector_id, audit_date, next_scheduled, score, result, findings, recommendations)
VALUES (10, 10, 4, TO_DATE('2026-05-25', 'YYYY-MM-DD'), TO_DATE('2027-05-25', 'YYYY-MM-DD'), 85.0, 'Passed', 'Decent overall compliance. Need more signage.', 'Install local language safety boards.');

-- CERTIFICATIONS (12 rows)
INSERT INTO CERTIFICATION (cert_id, factory_id, cert_name, issuing_body, issue_date, expiry_date, status)
VALUES (1, 1, 'OEKO-TEX Standard 100', 'OEKO-TEX Association', TO_DATE('2025-01-10', 'YYYY-MM-DD'), TO_DATE('2026-01-10', 'YYYY-MM-DD'), 'Expired');

INSERT INTO CERTIFICATION (cert_id, factory_id, cert_name, issuing_body, issue_date, expiry_date, status)
VALUES (2, 1, 'BSCI (Business Social Compliance Initiative)', 'amfori', TO_DATE('2025-06-01', 'YYYY-MM-DD'), TO_DATE('2027-06-01', 'YYYY-MM-DD'), 'Active');

INSERT INTO CERTIFICATION (cert_id, factory_id, cert_name, issuing_body, issue_date, expiry_date, status)
VALUES (3, 2, 'ISO 9001:2015', 'SGS Bangladesh', TO_DATE('2024-03-15', 'YYYY-MM-DD'), TO_DATE('2027-03-15', 'YYYY-MM-DD'), 'Active');

INSERT INTO CERTIFICATION (cert_id, factory_id, cert_name, issuing_body, issue_date, expiry_date, status)
VALUES (4, 3, 'WRAP (Worldwide Responsible Accredited Production)', 'WRAP Inc', TO_DATE('2024-05-10', 'YYYY-MM-DD'), TO_DATE('2025-05-10', 'YYYY-MM-DD'), 'Expired');

INSERT INTO CERTIFICATION (cert_id, factory_id, cert_name, issuing_body, issue_date, expiry_date, status)
VALUES (5, 4, 'ISO 14001 (Environmental)', 'TUV SUD', TO_DATE('2025-08-01', 'YYYY-MM-DD'), TO_DATE('2028-08-01', 'YYYY-MM-DD'), 'Active');

INSERT INTO CERTIFICATION (cert_id, factory_id, cert_name, issuing_body, issue_date, expiry_date, status)
VALUES (6, 4, 'GOTS (Global Organic Textile Standard)', 'Control Union', TO_DATE('2025-10-01', 'YYYY-MM-DD'), TO_DATE('2026-10-01', 'YYYY-MM-DD'), 'Active');

INSERT INTO CERTIFICATION (cert_id, factory_id, cert_name, issuing_body, issue_date, expiry_date, status)
VALUES (7, 5, 'BSCI (Business Social Compliance Initiative)', 'amfori', TO_DATE('2025-04-15', 'YYYY-MM-DD'), TO_DATE('2027-04-15', 'YYYY-MM-DD'), 'Active');

INSERT INTO CERTIFICATION (cert_id, factory_id, cert_name, issuing_body, issue_date, expiry_date, status)
VALUES (8, 5, 'OEKO-TEX Standard 100', 'OEKO-TEX Association', TO_DATE('2025-05-20', 'YYYY-MM-DD'), TO_DATE('2026-05-20', 'YYYY-MM-DD'), 'Expired');

INSERT INTO CERTIFICATION (cert_id, factory_id, cert_name, issuing_body, issue_date, expiry_date, status)
VALUES (9, 6, 'ISO 9001:2015', 'Bureau Veritas', TO_DATE('2026-01-10', 'YYYY-MM-DD'), TO_DATE('2029-01-10', 'YYYY-MM-DD'), 'Active');

INSERT INTO CERTIFICATION (cert_id, factory_id, cert_name, issuing_body, issue_date, expiry_date, status)
VALUES (10, 8, 'WRAP (Worldwide Responsible Accredited Production)', 'WRAP Inc', TO_DATE('2026-02-15', 'YYYY-MM-DD'), TO_DATE('2027-02-15', 'YYYY-MM-DD'), 'Active');

INSERT INTO CERTIFICATION (cert_id, factory_id, cert_name, issuing_body, issue_date, expiry_date, status)
VALUES (11, 9, 'GOTS (Global Organic Textile Standard)', 'Control Union', TO_DATE('2026-06-15', 'YYYY-MM-DD'), TO_DATE('2027-06-15', 'YYYY-MM-DD'), 'Pending');

INSERT INTO CERTIFICATION (cert_id, factory_id, cert_name, issuing_body, issue_date, expiry_date, status)
VALUES (12, 10, 'ISO 14001 (Environmental)', 'Intertek', TO_DATE('2025-12-01', 'YYYY-MM-DD'), TO_DATE('2028-12-01', 'YYYY-MM-DD'), 'Active');

-- SAFETY_EQUIPMENT (15 rows)
INSERT INTO SAFETY_EQUIPMENT (equipment_id, factory_id, equipment_type, quantity, purchase_date, expiry_date, last_inspection, condition_status, location)
VALUES (1, 1, 'Fire Extinguisher', 25, TO_DATE('2024-07-01', 'YYYY-MM-DD'), TO_DATE('2026-07-05', 'YYYY-MM-DD'), TO_DATE('2026-01-15', 'YYYY-MM-DD'), 'Good', 'Sewing Floor A');

INSERT INTO SAFETY_EQUIPMENT (equipment_id, factory_id, equipment_type, quantity, purchase_date, expiry_date, last_inspection, condition_status, location)
VALUES (2, 1, 'First Aid Kit', 10, TO_DATE('2025-01-10', 'YYYY-MM-DD'), TO_DATE('2026-07-10', 'YYYY-MM-DD'), TO_DATE('2026-05-10', 'YYYY-MM-DD'), 'Fair', 'Near Office Room');

INSERT INTO SAFETY_EQUIPMENT (equipment_id, factory_id, equipment_type, quantity, purchase_date, expiry_date, last_inspection, condition_status, location)
VALUES (3, 2, 'Emergency Exit Light', 12, TO_DATE('2023-03-15', 'YYYY-MM-DD'), TO_DATE('2028-03-15', 'YYYY-MM-DD'), TO_DATE('2026-03-15', 'YYYY-MM-DD'), 'Good', 'All exit doors');

INSERT INTO SAFETY_EQUIPMENT (equipment_id, factory_id, equipment_type, quantity, purchase_date, expiry_date, last_inspection, condition_status, location)
VALUES (4, 3, 'Fire Hose', 5, TO_DATE('2022-09-01', 'YYYY-MM-DD'), TO_DATE('2026-05-01', 'YYYY-MM-DD'), TO_DATE('2025-09-01', 'YYYY-MM-DD'), 'Poor', 'Water Hydrant Station');

INSERT INTO SAFETY_EQUIPMENT (equipment_id, factory_id, equipment_type, quantity, purchase_date, expiry_date, last_inspection, condition_status, location)
VALUES (5, 4, 'Smoke Detector', 50, TO_DATE('2023-01-15', 'YYYY-MM-DD'), TO_DATE('2028-01-15', 'YYYY-MM-DD'), TO_DATE('2026-01-15', 'YYYY-MM-DD'), 'Excellent', 'Ceiling Grid');

INSERT INTO SAFETY_EQUIPMENT (equipment_id, factory_id, equipment_type, quantity, purchase_date, expiry_date, last_inspection, condition_status, location)
VALUES (6, 5, 'Safety Helmet', 40, TO_DATE('2025-05-01', 'YYYY-MM-DD'), TO_DATE('2030-05-01', 'YYYY-MM-DD'), TO_DATE('2025-05-01', 'YYYY-MM-DD'), 'Excellent', 'Warehouse Section');

INSERT INTO SAFETY_EQUIPMENT (equipment_id, factory_id, equipment_type, quantity, purchase_date, expiry_date, last_inspection, condition_status, location)
VALUES (7, 6, 'Safety Gloves', 100, TO_DATE('2025-08-01', 'YYYY-MM-DD'), TO_DATE('2026-07-15', 'YYYY-MM-DD'), TO_DATE('2026-02-01', 'YYYY-MM-DD'), 'Fair', 'Cutting Section Store');

INSERT INTO SAFETY_EQUIPMENT (equipment_id, factory_id, equipment_type, quantity, purchase_date, expiry_date, last_inspection, condition_status, location)
VALUES (8, 7, 'Fire Extinguisher', 15, TO_DATE('2023-05-15', 'YYYY-MM-DD'), TO_DATE('2025-05-15', 'YYYY-MM-DD'), TO_DATE('2024-05-15', 'YYYY-MM-DD'), 'Poor', 'Ground Floor Lobby');

INSERT INTO SAFETY_EQUIPMENT (equipment_id, factory_id, equipment_type, quantity, purchase_date, expiry_date, last_inspection, condition_status, location)
VALUES (9, 8, 'Eye Protection', 30, TO_DATE('2024-11-20', 'YYYY-MM-DD'), TO_DATE('2026-07-20', 'YYYY-MM-DD'), TO_DATE('2025-11-20', 'YYYY-MM-DD'), 'Good', 'Chemical Mix Lab');

INSERT INTO SAFETY_EQUIPMENT (equipment_id, factory_id, equipment_type, quantity, purchase_date, expiry_date, last_inspection, condition_status, location)
VALUES (10, 9, 'First Aid Kit', 8, TO_DATE('2025-06-01', 'YYYY-MM-DD'), TO_DATE('2026-06-01', 'YYYY-MM-DD'), TO_DATE('2025-12-01', 'YYYY-MM-DD'), 'Fair', 'Finishing Room');

INSERT INTO SAFETY_EQUIPMENT (equipment_id, factory_id, equipment_type, quantity, purchase_date, expiry_date, last_inspection, condition_status, location)
VALUES (11, 10, 'Fire Extinguisher', 30, TO_DATE('2025-08-01', 'YYYY-MM-DD'), TO_DATE('2027-08-01', 'YYYY-MM-DD'), TO_DATE('2026-02-01', 'YYYY-MM-DD'), 'Good', 'Sewing Floor B');

INSERT INTO SAFETY_EQUIPMENT (equipment_id, factory_id, equipment_type, quantity, purchase_date, expiry_date, last_inspection, condition_status, location)
VALUES (12, 2, 'Fire Hose', 6, TO_DATE('2024-03-15', 'YYYY-MM-DD'), TO_DATE('2029-03-15', 'YYYY-MM-DD'), TO_DATE('2026-03-15', 'YYYY-MM-DD'), 'Good', 'Main stairs');

INSERT INTO SAFETY_EQUIPMENT (equipment_id, factory_id, equipment_type, quantity, purchase_date, expiry_date, last_inspection, condition_status, location)
VALUES (13, 4, 'Emergency Exit Light', 15, TO_DATE('2025-10-01', 'YYYY-MM-DD'), TO_DATE('2030-10-01', 'YYYY-MM-DD'), TO_DATE('2025-10-01', 'YYYY-MM-DD'), 'Excellent', 'Staircase exits');

INSERT INTO SAFETY_EQUIPMENT (equipment_id, factory_id, equipment_type, quantity, purchase_date, expiry_date, last_inspection, condition_status, location)
VALUES (14, 6, 'First Aid Kit', 12, TO_DATE('2026-01-10', 'YYYY-MM-DD'), TO_DATE('2027-01-10', 'YYYY-MM-DD'), TO_DATE('2026-01-10', 'YYYY-MM-DD'), 'Good', 'Quality control desk');

INSERT INTO SAFETY_EQUIPMENT (equipment_id, factory_id, equipment_type, quantity, purchase_date, expiry_date, last_inspection, condition_status, location)
VALUES (15, 8, 'Smoke Detector', 25, TO_DATE('2026-02-15', 'YYYY-MM-DD'), TO_DATE('2031-02-15', 'YYYY-MM-DD'), TO_DATE('2026-02-15', 'YYYY-MM-DD'), 'Excellent', 'Admin Block');

-- GRIEVANCES (12 rows)
INSERT INTO GRIEVANCE (grievance_id, worker_id, category, description, submitted_date, status, resolved_date, resolution_notes)
VALUES (1, 1, 'Salary Dispute', 'Delayed payment of April base salary.', TO_DATE('2026-05-05', 'YYYY-MM-DD'), 'Resolved', TO_DATE('2026-05-12', 'YYYY-MM-DD'), 'Disbursed bank transfer on May 12.');

INSERT INTO GRIEVANCE (grievance_id, worker_id, category, description, submitted_date, status, resolved_date, resolution_notes)
VALUES (2, 2, 'Harassment', 'Verbal abuse by floor supervisor.', TO_DATE('2026-06-10', 'YYYY-MM-DD'), 'In Progress', NULL, NULL);

INSERT INTO GRIEVANCE (grievance_id, worker_id, category, description, submitted_date, status, resolved_date, resolution_notes)
VALUES (3, 4, 'Safety Concern', 'Exposed electrical wiring near sewing table 14.', TO_DATE('2026-06-15', 'YYYY-MM-DD'), 'Open', NULL, NULL);

INSERT INTO GRIEVANCE (grievance_id, worker_id, category, description, submitted_date, status, resolved_date, resolution_notes)
VALUES (4, 7, 'Overtime Dispute', 'Did not receive overtime pay for 15 hours worked in May.', TO_DATE('2026-06-02', 'YYYY-MM-DD'), 'Resolved', TO_DATE('2026-06-08', 'YYYY-MM-DD'), 'Calculated hours and added to next cycle payroll.');

INSERT INTO GRIEVANCE (grievance_id, worker_id, category, description, submitted_date, status, resolved_date, resolution_notes)
VALUES (5, 8, 'Leave Denial', 'Sick leave rejected during severe fever.', TO_DATE('2026-05-20', 'YYYY-MM-DD'), 'Closed', TO_DATE('2026-05-25', 'YYYY-MM-DD'), 'Closed after worker submitted medical certificate and leave was approved retroactively.');

INSERT INTO GRIEVANCE (grievance_id, worker_id, category, description, submitted_date, status, resolved_date, resolution_notes)
VALUES (6, 11, 'Wrongful Termination', 'Terminated without notice period or severance package.', TO_DATE('2026-04-10', 'YYYY-MM-DD'), 'Resolved', TO_DATE('2026-04-20', 'YYYY-MM-DD'), 'Settlement amount paid and service book updated.');

INSERT INTO GRIEVANCE (grievance_id, worker_id, category, description, submitted_date, status, resolved_date, resolution_notes)
VALUES (7, 13, 'Salary Dispute', 'Deduction of 500 BDT without valid reason.', TO_DATE('2026-06-01', 'YYYY-MM-DD'), 'In Progress', NULL, NULL);

INSERT INTO GRIEVANCE (grievance_id, worker_id, category, description, submitted_date, status, resolved_date, resolution_notes)
VALUES (8, 17, 'Safety Concern', 'Emergency exit door kept locked during night shift.', TO_DATE('2026-06-18', 'YYYY-MM-DD'), 'Open', NULL, NULL);

INSERT INTO GRIEVANCE (grievance_id, worker_id, category, description, submitted_date, status, resolved_date, resolution_notes)
VALUES (9, 19, 'Harassment', 'Discrimination regarding shift scheduling.', TO_DATE('2026-05-15', 'YYYY-MM-DD'), 'Closed', TO_DATE('2026-05-22', 'YYYY-MM-DD'), 'Shift adjusted to morning shift as requested.');

INSERT INTO GRIEVANCE (grievance_id, worker_id, category, description, submitted_date, status, resolved_date, resolution_notes)
VALUES (10, 22, 'Overtime Dispute', 'Overtime rate calculated below 1.5x standard.', TO_DATE('2026-06-05', 'YYYY-MM-DD'), 'In Progress', NULL, NULL);

INSERT INTO GRIEVANCE (grievance_id, worker_id, category, description, submitted_date, status, resolved_date, resolution_notes)
VALUES (11, 25, 'Leave Denial', 'Denied maternity leave request.', TO_DATE('2026-05-01', 'YYYY-MM-DD'), 'Resolved', TO_DATE('2026-05-10', 'YYYY-MM-DD'), 'Maternity leave granted starting June 1st.');

INSERT INTO GRIEVANCE (grievance_id, worker_id, category, description, submitted_date, status, resolved_date, resolution_notes)
VALUES (12, 28, 'Safety Concern', 'Lack of fire safety masks in welding area.', TO_DATE('2026-06-20', 'YYYY-MM-DD'), 'Open', NULL, NULL);

-- SALARY_RECORD (25 records)
INSERT INTO SALARY_RECORD (record_id, worker_id, month, year, base_amount, overtime_hours, overtime_paid, deductions, net_salary, payment_status)
VALUES (1, 1, 4, 2026, 12500.00, 20.0, 1802.88, 200.00, 14102.88, 'Paid');

INSERT INTO SALARY_RECORD (record_id, worker_id, month, year, base_amount, overtime_hours, overtime_paid, deductions, net_salary, payment_status)
VALUES (2, 1, 5, 2026, 12500.00, 15.0, 1352.16, 100.00, 13752.16, 'Paid');

INSERT INTO SALARY_RECORD (record_id, worker_id, month, year, base_amount, overtime_hours, overtime_paid, deductions, net_salary, payment_status)
VALUES (3, 2, 4, 2026, 9500.00, 30.0, 2055.29, 0.00, 11555.29, 'Paid');

INSERT INTO SALARY_RECORD (record_id, worker_id, month, year, base_amount, overtime_hours, overtime_paid, deductions, net_salary, payment_status)
VALUES (4, 2, 5, 2026, 9500.00, 25.0, 1712.74, 0.00, 11212.74, 'Paid');

INSERT INTO SALARY_RECORD (record_id, worker_id, month, year, base_amount, overtime_hours, overtime_paid, deductions, net_salary, payment_status)
VALUES (5, 3, 5, 2026, 22000.00, 10.0, 1586.54, 500.00, 23086.54, 'Paid');

INSERT INTO SALARY_RECORD (record_id, worker_id, month, year, base_amount, overtime_hours, overtime_paid, deductions, net_salary, payment_status)
VALUES (6, 4, 4, 2026, 15000.00, 40.0, 4326.92, 150.00, 19176.92, 'Paid');

INSERT INTO SALARY_RECORD (record_id, worker_id, month, year, base_amount, overtime_hours, overtime_paid, deductions, net_salary, payment_status)
VALUES (7, 4, 5, 2026, 15000.00, 35.0, 3786.06, 100.00, 18686.06, 'Paid');

INSERT INTO SALARY_RECORD (record_id, worker_id, month, year, base_amount, overtime_hours, overtime_paid, deductions, net_salary, payment_status)
VALUES (8, 5, 5, 2026, 24000.00, 12.0, 2076.92, 600.00, 25476.92, 'Paid');

INSERT INTO SALARY_RECORD (record_id, worker_id, month, year, base_amount, overtime_hours, overtime_paid, deductions, net_salary, payment_status)
VALUES (9, 6, 4, 2026, 11000.00, 20.0, 1586.54, 0.00, 12586.54, 'Paid');

INSERT INTO SALARY_RECORD (record_id, worker_id, month, year, base_amount, overtime_hours, overtime_paid, deductions, net_salary, payment_status)
VALUES (10, 6, 5, 2026, 11000.00, 18.0, 1427.88, 0.00, 12427.88, 'Paid');

INSERT INTO SALARY_RECORD (record_id, worker_id, month, year, base_amount, overtime_hours, overtime_paid, deductions, net_salary, payment_status)
VALUES (11, 7, 5, 2026, 13000.00, 50.0, 4687.50, 300.00, 17387.50, 'Partial');

INSERT INTO SALARY_RECORD (record_id, worker_id, month, year, base_amount, overtime_hours, overtime_paid, deductions, net_salary, payment_status)
VALUES (12, 8, 5, 2026, 9000.00, 22.0, 1429.33, 0.00, 10429.33, 'Paid');

INSERT INTO SALARY_RECORD (record_id, worker_id, month, year, base_amount, overtime_hours, overtime_paid, deductions, net_salary, payment_status)
VALUES (13, 9, 5, 2026, 19500.00, 15.0, 2108.17, 400.00, 21208.17, 'Paid');

INSERT INTO SALARY_RECORD (record_id, worker_id, month, year, base_amount, overtime_hours, overtime_paid, deductions, net_salary, payment_status)
VALUES (14, 10, 5, 2026, 10000.00, 10.0, 721.15, 100.00, 10621.15, 'Paid');

INSERT INTO SALARY_RECORD (record_id, worker_id, month, year, base_amount, overtime_hours, overtime_paid, deductions, net_salary, payment_status)
VALUES (15, 11, 5, 2026, 12000.00, 30.0, 2596.15, 200.00, 14396.15, 'Paid');

INSERT INTO SALARY_RECORD (record_id, worker_id, month, year, base_amount, overtime_hours, overtime_paid, deductions, net_salary, payment_status)
VALUES (16, 12, 5, 2026, 14500.00, 25.0, 2614.18, 250.00, 16864.18, 'Paid');

INSERT INTO SALARY_RECORD (record_id, worker_id, month, year, base_amount, overtime_hours, overtime_paid, deductions, net_salary, payment_status)
VALUES (17, 13, 5, 2026, 11500.00, 20.0, 1658.65, 150.00, 13008.65, 'Pending');

INSERT INTO SALARY_RECORD (record_id, worker_id, month, year, base_amount, overtime_hours, overtime_paid, deductions, net_salary, payment_status)
VALUES (18, 14, 5, 2026, 25000.00, 8.0, 1442.31, 500.00, 25942.31, 'Paid');

INSERT INTO SALARY_RECORD (record_id, worker_id, month, year, base_amount, overtime_hours, overtime_paid, deductions, net_salary, payment_status)
VALUES (19, 15, 5, 2026, 9200.00, 60.0, 3980.77, 0.00, 13180.77, 'Paid');

INSERT INTO SALARY_RECORD (record_id, worker_id, month, year, base_amount, overtime_hours, overtime_paid, deductions, net_salary, payment_status)
VALUES (20, 17, 5, 2026, 12500.00, 18.0, 1622.60, 200.00, 13922.60, 'Paid');

INSERT INTO SALARY_RECORD (record_id, worker_id, month, year, base_amount, overtime_hours, overtime_paid, deductions, net_salary, payment_status)
VALUES (21, 20, 5, 2026, 18000.00, 15.0, 1947.12, 350.00, 19597.12, 'Paid');

INSERT INTO SALARY_RECORD (record_id, worker_id, month, year, base_amount, overtime_hours, overtime_paid, deductions, net_salary, payment_status)
VALUES (22, 22, 5, 2026, 13000.00, 35.0, 3281.25, 250.00, 16031.25, 'Pending');

INSERT INTO SALARY_RECORD (record_id, worker_id, month, year, base_amount, overtime_hours, overtime_paid, deductions, net_salary, payment_status)
VALUES (23, 23, 5, 2026, 15500.00, 20.0, 2235.58, 300.00, 17435.58, 'Paid');

INSERT INTO SALARY_RECORD (record_id, worker_id, month, year, base_amount, overtime_hours, overtime_paid, deductions, net_salary, payment_status)
VALUES (24, 25, 5, 2026, 10800.00, 40.0, 3115.38, 100.00, 13815.38, 'Paid');

INSERT INTO SALARY_RECORD (record_id, worker_id, month, year, base_amount, overtime_hours, overtime_paid, deductions, net_salary, payment_status)
VALUES (25, 28, 5, 2026, 19000.00, 15.0, 2054.09, 400.00, 20654.09, 'Paid');


--------------------------------------------------------------------------------
-- 9. VERIFICATION & COMMIT
--------------------------------------------------------------------------------

PROMPT Committing transaction...
COMMIT;

PROMPT Verifying view vw_factory_compliance...
COLUMN factory_name FORMAT A25
COLUMN registration_no FORMAT A15
COLUMN compliance_status FORMAT A15
SELECT factory_id, factory_name, registration_no, compliance_status, latest_audit_score, active_certs_count, open_grievances_count 
FROM vw_factory_compliance
ORDER BY factory_id;

PROMPT Verifying view vw_worker_salary_ytd...
COLUMN full_name FORMAT A20
COLUMN designation FORMAT A20
SELECT worker_id, full_name, factory_name, designation, ytd_net_salary, ytd_overtime_paid, months_paid
FROM vw_worker_salary_ytd
ORDER BY worker_id;

PROMPT Showing factories with grievance count > 0...
SELECT f.factory_name, COUNT(g.grievance_id) AS total_grievances
FROM FACTORY f
JOIN WORKER w ON f.factory_id = w.factory_id
JOIN GRIEVANCE g ON w.worker_id = g.worker_id
GROUP BY f.factory_name
HAVING COUNT(g.grievance_id) > 0;

PROMPT Showing safety equipment expiring in next 30 days...
COLUMN equipment_type FORMAT A20
COLUMN location FORMAT A20
SELECT f.factory_name, se.equipment_type, se.quantity, se.expiry_date, se.location, se.condition_status
FROM SAFETY_EQUIPMENT se
JOIN FACTORY f ON se.factory_id = f.factory_id
WHERE se.expiry_date >= SYSDATE AND se.expiry_date <= SYSDATE + 30;

PROMPT Schema DDL Execution Complete.
EXIT;
