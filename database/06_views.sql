-- 7. VIEW CREATION
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
