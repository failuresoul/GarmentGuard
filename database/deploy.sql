-- GarmentGuard Database Deploy Master Script
-- Platform: Oracle Database XE 11g
-- Runs all sub-scripts in order

SET DEFINE OFF
SET ECHO ON
SET FEEDBACK ON
SET SERVEROUTPUT ON

PROMPT Starting GarmentGuard Database Setup...


@01_cleanup.sql
@02_sequences.sql
@03_tables.sql
@04_comments.sql
@05_indexes.sql
@06_views.sql
@07_packages.sql
@08_functions_triggers.sql
@09_seeds.sql
@10_tests.sql
@11_verifications.sql
@12_production_processing.sql

PROMPT Database deployment and test script execution complete.
EXIT;
