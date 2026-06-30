-- MASTER DATABASE INSTALLATION SCRIPT
SET DEFINE OFF
SET ECHO ON
SET SERVEROUTPUT ON

WHENEVER SQLERROR EXIT ROLLBACK;

PROMPT [1/9] Deploying Tables...
@@01_tables.sql

PROMPT [2/9] Deploying Sequences...
@@02_sequences.sql

PROMPT [3/9] Deploying Indexes...
@@03_indexes.sql

PROMPT [4/9] Deploying Views...
@@04_views.sql

PROMPT [5/9] Deploying Package Specifications...
@@05_packages_spec.sql

PROMPT [6/9] Deploying Package Bodies...
@@06_packages_body.sql

PROMPT [7/9] Deploying Triggers...
@@07_triggers.sql

PROMPT [8/9] Deploying Scheduler Jobs...
@@08_scheduler_jobs.sql

PROMPT [9/9] Deploying Roles, Grants and Seed Data...
@@09_seed_data.sql

COMMIT;
PROMPT Database installation successfully finished.

SELECT 'Installation complete. Tables count: ' || COUNT(*) AS "Result" FROM USER_TABLES;

EXIT;
