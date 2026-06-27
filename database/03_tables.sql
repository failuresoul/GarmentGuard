-- 3. TABLE CREATION WITH CONSTRAINTS
PROMPT Creating tables...

-- FACTORY
CREATE TABLE FACTORY (
  factory_id NUMBER(10) CONSTRAINT pk_factory PRIMARY KEY,
  factory_name VARCHAR2(255) NOT NULL,
  registration_no VARCHAR2(100) NOT NULL CONSTRAINT uq_factory_reg_no UNIQUE,
  address VARCHAR2(500) NOT NULL,
  district VARCHAR2(100) NOT NULL,
  total_workers NUMBER(6) DEFAULT 0 NOT NULL CONSTRAINT chk_factory_workers CHECK (total_workers >= 0),
  compliance_status VARCHAR2(50) NOT NULL CONSTRAINT chk_factory_compliance CHECK (compliance_status IN ('Compliant', 'Non-Compliant', 'Partially Compliant', 'Pending', 'Suspended', 'Review Needed')),
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

-- ERROR_LOG
CREATE TABLE ERROR_LOG (
  log_id NUMBER(10) CONSTRAINT pk_error_log PRIMARY KEY,
  log_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  username VARCHAR2(100) NOT NULL,
  procedure_name VARCHAR2(150) NOT NULL,
  error_code NUMBER(10) NOT NULL,
  error_message VARCHAR2(4000) NOT NULL,
  error_backtrace VARCHAR2(4000)
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

CREATE OR REPLACE TRIGGER ERROR_LOG_BI
BEFORE INSERT ON ERROR_LOG
FOR EACH ROW
BEGIN
  IF :NEW.log_id IS NULL THEN
    SELECT ERROR_LOG_SEQ.NEXTVAL INTO :NEW.log_id FROM DUAL;
  END IF;
END;
/
