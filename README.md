# GarmentGuard 🛡️

A state-of-the-art compliance, health & safety, and worker welfare audit platform designed for Bangladesh's Ready-Made Garment (RMG) sector. 

GarmentGuard coordinates real-time dashboard analytics, role-based access controls, Oracle PL/SQL performance tuning, and automated database triggers to streamline safety compliance tracking across factories.

---

## 🚀 Key Features

* **Real-time Sourcing Metrics**: Factory compliance health checking, audit history tracking, and active certifications monitoring.
* **Granular Role-Based Access Control (RBAC)**: Unique views and data segregation for `Admins`, `Compliance Officers`, `Inspectors`, `Buyers`, and `Workers`.
* **Row-Level Security (RLS)**: Transparent row segregation filters (via Oracle `CLIENT_INFO` context maps) protecting worker payroll records and grievance feedback logs.
* **Statutory Compliance Controls**: Automated triggers validating safety equipment expiry, net salaries computation, overtime caps under Bangladesh Labour Law, and factory registration bounds.
* **Polished Visualization Panel**: Comprehensive dashboard tracking audit trends, grievance counts, regional compliance rankings, and recent inspection events.

---

## 🛠️ Technology Stack & Prerequisites

* **Database**: Oracle Database 11g (or 21c) Express Edition (XE)
* **Backend**: Node.js v20.x, Express.js, `oracledb` thin client driver
* **Frontend**: React.js, Vite, TailwindCSS (for custom styles), Recharts
* **Authentication**: JSON Web Tokens (JWT) inside `httpOnly` secure cookies

---

## 💾 Database Setup Scripts

The database DDL is organized into chronological, self-contained modular files under `/database`:

* [01_tables.sql](file:///e:/GarmentGuard/database/01_tables.sql): Tables structure, key constraints, and relational schemas.
* [02_sequences.sql](file:///e:/GarmentGuard/database/02_sequences.sql): Database primary key generators.
* [03_indexes.sql](file:///e:/GarmentGuard/database/03_indexes.sql): Performance composite indexes and foreign key mappings.
* [04_views.sql](file:///e:/GarmentGuard/database/04_views.sql): Compliance dashboards and RLS user context views.
* [05_packages_spec.sql](file:///e:/GarmentGuard/database/05_packages_spec.sql): Specifications for modular business packages.
* [06_packages_body.sql](file:///e:/GarmentGuard/database/06_packages_body.sql): Core PL/SQL logic, cached compliance scoring, and version-conditional dynamic SQL execution.
* [07_triggers.sql](file:///e:/GarmentGuard/database/07_triggers.sql): Auto-increment key synchronization and integrity verification triggers.
* [08_scheduler_jobs.sql](file:///e:/GarmentGuard/database/08_scheduler_jobs.sql): Standalone procedures and scheduled batch jobs for alerts and status checks.
* [09_seed_data.sql](file:///e:/GarmentGuard/database/09_seed_data.sql): Roles creation, privileges mapping, and seed records (with bcrypt-hashed passwords).

### 🛠️ Execution Commands

To execute schema updates or run the tests, open a console in the `/database` directory and run:

1. **Clean Installation**: Rebuilds the database from scratch and inserts seeds.
   ```powershell
   sqlplus garmentguard/your_secure_password@localhost:1521/XE "@install.sql"
   ```
2. **Schema Rollback**: Cascades drops across all roles, triggers, tables, views, and packages.
   ```powershell
   sqlplus garmentguard/your_secure_password@localhost:1521/XE "@rollback.sql"
   ```
3. **Run Test Suite**: Executes 10 anonymous assertion blocks validating database constraints and return scopes.
   ```powershell
   sqlplus garmentguard/your_secure_password@localhost:1521/XE "@test_suite.sql"
   ```

---

## 🔑 Seed User Accounts

All seed user accounts use the default password: **`password123`**

| Username | Role | Database Linkages / Details |
| :--- | :--- | :--- |
| `sysadmin` | **Admin** | Unrestricted compliance administrative permissions. |
| `comp_dhaka` | **Compliance_Officer** | Assigned to Factory 1 (Dhaka Garments Ltd). |
| `comp_tongi` | **Compliance_Officer** | Assigned to Factory 3 (Tongi Tex Group). |
| `inspector1` | **Inspector** | Inspection logger; records audit results and scores. |
| `hm_buyer` | **Buyer** | Linked to Buyer 1 (H&M). Sourcing and certifications dashboard access. |
| `worker1` | **Worker** | Linked to Worker 1 (Abul Kalam) at Factory 1. Accesses pay records and submits grievances. |

---

## 🌐 Express Backend API Endpoints

### 🔐 Authentication Router (`/api/auth`)
* `POST /login`: Validates user password, signs JWT, and issues `httpOnly` secure cookie.
* `GET /me`: Decodes session token cookie to verify credentials and return role state.
* `POST /logout`: Clears session token cookie.

### 🏢 Compliance Officer & Admin Routers
* `/api/dashboard` (`GET`): High-level aggregates (compliant, at-risk, and non-compliant factory counts).
* `/api/analytics/audit-trends` (`GET`): Chronological 12-month compliance average scores.
* `/api/analytics/grievance-breakdown` (`GET`): Category distribution counts and resolution intervals.
* `/api/factories` (`GET`/`POST`): List all registered factories or enroll a new facility.
* `/api/factories/:id` (`GET`/`PUT`): Factory information fetch and detail updates.
* `/api/workers` (`GET`/`POST`): Employee directory access and hiring forms.
* `/api/workers/salary` (`POST`): Monthly wage processing bounds auditor.
* `/api/audits` (`GET`/`POST`): Audits catalog and inspections logger.
* `/api/reports/factory/:id` (`GET`): Compiles a text-based compliance summary report via DBMS_OUTPUT.

### 🌍 Buyer Sourcing Router (`/api/buyer`)
* `GET /factories/:buyerId`: Lists associated factories, contract status, compliance scores, and active certs.
* `GET /factory/:factoryId/certifications`: Lists active, expired, or pending OEKO-TEX, BSCI, GOTS certifications.

### 🧵 Worker Self-Service Router (`/api/worker-portal`)
* `GET /grievances`: Fetches worker's own grievances utilizing the RLS context view.
* `POST /grievances`: Submits a safety concern or salary dispute to the factory.
* `GET /salaries`: Fetches worker's personal monthly pay statements.

---

## 🏃 Quick Start Node App

1. Ensure Oracle Database XE is running and the credentials in `backend/.env` are updated.
2. Install dependencies for the server:
   ```bash
   cd backend
   npm install
   npm run dev
   ```
3. Install dependencies for the client:
   ```bash
   cd ../frontend
   npm install
   npm run dev
   ```
4. Access the web dashboard at `http://localhost:5173`.
