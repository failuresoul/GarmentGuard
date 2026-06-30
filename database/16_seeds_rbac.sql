-- 16. RBAC USER SEEDS
SET DEFINE OFF
SET SQLBLANKLINES ON

PROMPT Updating existing seed users to bcrypt hashes...

-- Update all existing user hashes to bcrypt hash of 'password123'
UPDATE USER_
SET password_hash = '$2b$10$6WyU3pjoR3da3dEHrWAYe.bHwqz52O/JcW53amQrrP1kkjbgSgC/2';

PROMPT Creating worker user accounts...

-- Delete if exists
DELETE FROM USER_ WHERE user_id = 6 OR username = 'worker1';

-- Insert a user account for Worker 1 (Abul Kalam)
INSERT INTO USER_ (user_id, username, password_hash, role, full_name, factory_id, worker_id, email, status)
VALUES (6, 'worker1', '$2b$10$6WyU3pjoR3da3dEHrWAYe.bHwqz52O/JcW53amQrrP1kkjbgSgC/2', 'Worker', 'Abul Kalam', 1, 1, 'worker1@dhakagarments.com', 'Active');

-- Update user roles and link to buyer_id for consistency
UPDATE USER_
SET role = 'Buyer', buyer_id = 1
WHERE username = 'hm_buyer';

COMMIT;
EXIT;
