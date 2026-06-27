SET DEFINE OFF
-- 9. SEED DATA INSERTION
PROMPT Inserting seed data...


-- FACTORIES (10 rows, all 8 divisions)
INSERT INTO FACTORY (factory_id, factory_name, registration_no, address, district, total_workers, compliance_status, compliance_score, last_audit_date, next_audit_date, contact_person, phone, email)
VALUES (1, 'Dhaka Garments Ltd.', 'REG-DHA-001', 'Ashulia, Savar', 'Dhaka', 0, 'Compliant', 92.5, TO_DATE('2026-03-15', 'YYYY-MM-DD'), TO_DATE('2027-03-15', 'YYYY-MM-DD'), 'M. A. Rahman', '01711111111', 'info@dhakagarments.com');

INSERT INTO FACTORY (factory_id, factory_name, registration_no, address, district, total_workers, compliance_status, compliance_score, last_audit_date, next_audit_date, contact_person, phone, email)
VALUES (2, 'Mirpur Fashion Apparels', 'REG-DHA-002', 'Mirpur-10', 'Dhaka', 0, 'Partially Compliant', 76.0, TO_DATE('2026-04-10', 'YYYY-MM-DD'), TO_DATE('2027-04-10', 'YYYY-MM-DD'), 'Kamil Ahmed', '01711111112', 'info@mirpurfashion.com');

INSERT INTO FACTORY (factory_id, factory_name, registration_no, address, district, total_workers, compliance_status, compliance_score, last_audit_date, next_audit_date, contact_person, phone, email)
VALUES (3, 'Tongi Tex Group', 'REG-GAZ-001', 'Tongi Industrial Area', 'Gazipur', 0, 'Non-Compliant', 45.0, TO_DATE('2026-01-20', 'YYYY-MM-DD'), TO_DATE('2026-07-20', 'YYYY-MM-DD'), 'Shafiqul Alam', '01711111113', 'contact@tongitex.com');

INSERT INTO FACTORY (factory_id, factory_name, registration_no, address, district, total_workers, compliance_status, compliance_score, last_audit_date, next_audit_date, contact_person, phone, email)
VALUES (4, 'Kaliakair Eco-Styles', 'REG-GAZ-002', 'Kaliakair', 'Gazipur', 0, 'Compliant', 88.0, TO_DATE('2026-05-12', 'YYYY-MM-DD'), TO_DATE('2027-05-12', 'YYYY-MM-DD'), 'Farhana Chowdhury', '01711111114', 'eco@kaliakaireco.com');

INSERT INTO FACTORY (factory_id, factory_name, registration_no, address, district, total_workers, compliance_status, compliance_score, last_audit_date, next_audit_date, contact_person, phone, email)
VALUES (5, 'Bayview Apparels Ltd.', 'REG-CTG-001', 'CEPZ, Halishahar', 'Chittagong', 0, 'Compliant', 95.0, TO_DATE('2026-02-18', 'YYYY-MM-DD'), TO_DATE('2027-02-18', 'YYYY-MM-DD'), 'Zahirul Islam', '01711111115', 'info@bayviewctg.com');

INSERT INTO FACTORY (factory_id, factory_name, registration_no, address, district, total_workers, compliance_status, compliance_score, last_audit_date, next_audit_date, contact_person, phone, email)
VALUES (6, 'Sreemangal Quality Knits', 'REG-SYL-001', 'Sreemangal', 'Sylhet', 0, 'Pending', 60.0, TO_DATE('2026-06-01', 'YYYY-MM-DD'), TO_DATE('2026-12-01', 'YYYY-MM-DD'), 'Mohit Lal', '01711111116', 'knits@sreemangalquality.com');

INSERT INTO FACTORY (factory_id, factory_name, registration_no, address, district, total_workers, compliance_status, compliance_score, last_audit_date, next_audit_date, contact_person, phone, email)
VALUES (7, 'Silk City Apparels', 'REG-RAJ-001', 'BSCIC Area', 'Rajshahi', 0, 'Suspended', 30.0, TO_DATE('2025-11-10', 'YYYY-MM-DD'), TO_DATE('2026-05-10', 'YYYY-MM-DD'), 'Aminul Islam', '01711111117', 'info@silkcityraj.com');

INSERT INTO FACTORY (factory_id, factory_name, registration_no, address, district, total_workers, compliance_status, compliance_score, last_audit_date, next_audit_date, contact_person, phone, email)
VALUES (8, 'Rupsha Fashion Tech', 'REG-KHU-001', 'Khalishpur', 'Khulna', 0, 'Partially Compliant', 72.0, TO_DATE('2026-03-05', 'YYYY-MM-DD'), TO_DATE('2026-09-05', 'YYYY-MM-DD'), 'Saiful Bari', '01711111118', 'tech@rupshafashion.com');

INSERT INTO FACTORY (factory_id, factory_name, registration_no, address, district, total_workers, compliance_status, compliance_score, last_audit_date, next_audit_date, contact_person, phone, email)
VALUES (9, 'Kirtankhola Fabrics', 'REG-BAR-001', 'Barishal City', 'Barishal', 0, 'Non-Compliant', 52.0, TO_DATE('2026-02-28', 'YYYY-MM-DD'), TO_DATE('2026-08-28', 'YYYY-MM-DD'), 'Anisur Rahman', '01711111119', 'ops@kirtankholafab.com');

INSERT INTO FACTORY (factory_id, factory_name, registration_no, address, district, total_workers, compliance_status, compliance_score, last_audit_date, next_audit_date, contact_person, phone, email)
VALUES (10, 'Brahmaputra Garment Zone', 'REG-MYM-001', 'Mymensingh Sadar', 'Mymensingh', 0, 'Compliant', 85.0, TO_DATE('2026-05-25', 'YYYY-MM-DD'), TO_DATE('2027-05-25', 'YYYY-MM-DD'), 'Faruk Ahmed', '01711111120', 'admin@brahmaputragz.com');

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
VALUES (1, 'H' || CHR(38) || 'M', 'Sweden', 'Sven Larsson', 'sourcing@hm.com', '+4687965500', 'H' || CHR(38) || 'M');

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
