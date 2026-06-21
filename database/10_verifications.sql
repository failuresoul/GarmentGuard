-- 11. VERIFICATION QUERIES
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

PROMPT Querying ERROR_LOG table to show autonomous logging results...
COLUMN procedure_name FORMAT A35
COLUMN error_message FORMAT A55
COLUMN username FORMAT A15
SELECT log_id, log_timestamp, username, procedure_name, error_code, error_message
FROM ERROR_LOG
ORDER BY log_id;
