-- 6. INDEX CREATION
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
