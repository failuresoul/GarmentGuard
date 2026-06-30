-- 14. GARMENTGUARD ADVANCED ANALYTICAL QUERIES & MATERIALIZED VIEW
-- This script sets up the database objects and documents the analytical queries.
SET DEFINE OFF
SET SQLBLANKLINES ON

PROMPT Setting up deterministic functions for materialized view...

CREATE OR REPLACE FUNCTION fn_get_active_certs(p_factory_id NUMBER) 
RETURN NUMBER DETERMINISTIC AS
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count 
  FROM CERTIFICATION 
  WHERE factory_id = p_factory_id AND status = 'Active';
  RETURN v_count;
END;
/

CREATE OR REPLACE FUNCTION fn_get_open_grievances(p_factory_id NUMBER) 
RETURN NUMBER DETERMINISTIC AS
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count 
  FROM GRIEVANCE g 
  JOIN WORKER w ON g.worker_id = w.worker_id 
  WHERE w.factory_id = p_factory_id AND g.status IN ('Pending', 'Investigating', 'Open', 'In Progress');
  RETURN v_count;
END;
/

CREATE OR REPLACE FUNCTION fn_get_expiring_equip(p_factory_id NUMBER) 
RETURN NUMBER DETERMINISTIC AS
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count 
  FROM SAFETY_EQUIPMENT 
  WHERE factory_id = p_factory_id AND expiry_date BETWEEN TO_DATE('2026-06-30', 'YYYY-MM-DD') AND TO_DATE('2026-07-30', 'YYYY-MM-DD');
  RETURN v_count;
END;
/

PROMPT Creating Materialized View mv_compliance_dashboard...

BEGIN
  EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW mv_compliance_dashboard';
EXCEPTION
  WHEN OTHERS THEN NULL; -- Ignore if it doesn't exist
END;
/

CREATE MATERIALIZED VIEW mv_compliance_dashboard
REFRESH COMPLETE ON COMMIT
AS
SELECT 
  f.factory_id, 
  f.factory_name, 
  f.compliance_score AS latest_score, 
  fn_get_active_certs(f.factory_id) AS cert_count, 
  fn_get_open_grievances(f.factory_id) AS open_grievances, 
  fn_get_expiring_equip(f.factory_id) AS equipment_expiring_soon 
FROM FACTORY f;


--------------------------------------------------------------------------------
-- 1. WINDOW RANK QUERY
-- Rank factories by compliance_score within each district
--------------------------------------------------------------------------------
-- SELECT /*+ PARALLEL(a,4) */
--   factory_id, 
--   factory_name, 
--   district, 
--   compliance_score, 
--   RANK() OVER (PARTITION BY district ORDER BY compliance_score DESC) AS compliance_rank
-- FROM FACTORY a;

--------------------------------------------------------------------------------
-- 2. RUNNING TOTAL QUERY
-- Cumulative net_salary per worker per year
--------------------------------------------------------------------------------
-- SELECT 
--   worker_id, 
--   year, 
--   month, 
--   net_salary, 
--   SUM(net_salary) OVER (PARTITION BY worker_id, year ORDER BY month ROWS UNBOUNDED PRECEDING) AS running_net_salary 
-- FROM SALARY_RECORD;

--------------------------------------------------------------------------------
-- 3. LAG/LEAD QUERY
-- For each factory show current vs previous audit score and percentage delta
--------------------------------------------------------------------------------
-- SELECT 
--   audit_id,
--   factory_id,
--   audit_date,
--   score AS current_score,
--   LAG(score) OVER (PARTITION BY factory_id ORDER BY audit_date) AS previous_score,
--   ROUND(
--     CASE 
--       WHEN LAG(score) OVER (PARTITION BY factory_id ORDER BY audit_date) IS NULL THEN NULL
--       WHEN LAG(score) OVER (PARTITION BY factory_id ORDER BY audit_date) = 0 THEN 0
--       ELSE ((score - LAG(score) OVER (PARTITION BY factory_id ORDER BY audit_date)) / LAG(score) OVER (PARTITION BY factory_id ORDER BY audit_date)) * 100
--     END, 
--     2
--   ) AS percentage_delta
-- FROM "AUDIT";

--------------------------------------------------------------------------------
-- 4. WITH CLAUSE QUERY
-- Find factories whose compliance score improved >10 points over last 2 audits
--------------------------------------------------------------------------------
-- WITH FactoryAudits AS (
--   SELECT 
--     factory_id,
--     score,
--     LAG(score) OVER (PARTITION BY factory_id ORDER BY audit_date) AS prev_score
--   FROM "AUDIT"
-- )
-- SELECT 
--   fa.factory_id, 
--   f.factory_name, 
--   fa.score AS current_score, 
--   fa.prev_score AS previous_score, 
--   (fa.score - fa.prev_score) AS improvement
-- FROM FactoryAudits fa
-- JOIN FACTORY f ON fa.factory_id = f.factory_id
-- WHERE fa.prev_score IS NOT NULL 
--   AND (fa.score - fa.prev_score) > 10;

--------------------------------------------------------------------------------
-- 5. PIVOT QUERY
-- Months Jan-Dec as columns, rows = factories, values = SUM(net_salary)
--------------------------------------------------------------------------------
-- SELECT * FROM (
--   SELECT 
--     f.factory_name, 
--     sr.month, 
--     sr.net_salary 
--   FROM SALARY_RECORD sr 
--   JOIN WORKER w ON sr.worker_id = w.worker_id 
--   JOIN FACTORY f ON w.factory_id = f.factory_id
-- ) PIVOT (
--   SUM(net_salary) 
--   FOR month IN (
--     1 AS "Jan", 
--     2 AS "Feb", 
--     3 AS "Mar", 
--     4 AS "Apr", 
--     5 AS "May", 
--     6 AS "Jun", 
--     7 AS "Jul", 
--     8 AS "Aug", 
--     9 AS "Sep", 
--     10 AS "Oct", 
--     11 AS "Nov", 
--     12 AS "Dec"
--   )
-- ) ORDER BY factory_name;

--------------------------------------------------------------------------------
-- 6. MATERIALIZED VIEW QUERY
-- Query from mv_compliance_dashboard
--------------------------------------------------------------------------------
-- SELECT 
--   factory_id, 
--   factory_name, 
--   latest_score, 
--   cert_count, 
--   open_grievances, 
--   equipment_expiring_soon 
-- FROM mv_compliance_dashboard 
-- ORDER BY factory_id;

--------------------------------------------------------------------------------
-- 7. DENSE_RANK QUERY
-- Top 3 grievance categories per factory using DENSE_RANK()
--------------------------------------------------------------------------------
-- WITH CategoryCounts AS (
--   SELECT 
--     w.factory_id, 
--     g.category, 
--     COUNT(*) AS cnt 
--   FROM GRIEVANCE g 
--   JOIN WORKER w ON g.worker_id = w.worker_id 
--   GROUP BY w.factory_id, g.category
-- ),
-- RankedCategories AS (
--   SELECT 
--     cc.factory_id, 
--     cc.category, 
--     cc.cnt, 
--     DENSE_RANK() OVER (PARTITION BY cc.factory_id ORDER BY cc.cnt DESC) AS rnk 
--   FROM CategoryCounts cc
-- )
-- SELECT 
--   rc.factory_id, 
--   f.factory_name, 
--   rc.category, 
--   rc.cnt AS grievance_count, 
--   rc.rnk
-- FROM RankedCategories rc
-- JOIN FACTORY f ON rc.factory_id = f.factory_id
-- WHERE rc.rnk <= 3
-- ORDER BY rc.factory_id, rc.rnk;

EXIT;
