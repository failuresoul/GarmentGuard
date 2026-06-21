-- 5. COMMENTS ON TABLES AND COLUMNS
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
