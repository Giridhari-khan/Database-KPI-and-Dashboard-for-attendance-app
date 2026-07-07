-- ================================================================
-- schema.sql — Tap-In KPI Dashboard (Reference Schema)
--
-- ⚠ DISCLAIMER: This is a REFERENCE implementation for demo and
-- educational purposes. All data in seed files is fictional.
-- Do NOT use with real production credentials or real data.
-- ================================================================

-- 1. CUSTOM ENUMS
-- ================================================================
DO $$ BEGIN CREATE TYPE user_role AS ENUM ('super_admin','company_admin'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE company_status AS ENUM ('active','suspended','trial'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE employee_status AS ENUM ('active','inactive','suspended'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE attendance_status AS ENUM ('present','absent','late','half_day','holiday','week_off'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE request_status AS ENUM ('pending','approved','rejected','cancelled'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE pricing_plan AS ENUM ('Normal','Standard','Enterprise'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- 2. CORE TABLES (multi-tenant via company_id)
-- ================================================================

CREATE TABLE IF NOT EXISTS companies (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_code           TEXT UNIQUE NOT NULL,
  name                  TEXT NOT NULL,
  logo_url              TEXT,
  zone                  TEXT NOT NULL DEFAULT 'Asia/Kolkata',
  location              TEXT,
  contact_email         TEXT,
  contact_phone         TEXT,
  pricing_plan          pricing_plan NOT NULL DEFAULT 'Normal',
  seat_count            INTEGER NOT NULL DEFAULT 0,
  status                company_status NOT NULL DEFAULT 'active',
  billing_email         TEXT,
  gst_number            TEXT,
  auto_billing_enabled  BOOLEAN DEFAULT FALSE,
  last_billing_month    TEXT,
  lat                   NUMERIC,
  lng                   NUMERIC,
  geofence_radius_m     INTEGER DEFAULT 500,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS profiles (
  id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  company_id      UUID REFERENCES companies(id) ON DELETE SET NULL,
  role            user_role NOT NULL DEFAULT 'company_admin',
  full_name       TEXT,
  phone           TEXT,
  avatar_url      TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS branches (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id        UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name              TEXT NOT NULL,
  lat               NUMERIC,
  lng               NUMERIC,
  geofence_radius_m INTEGER NOT NULL DEFAULT 300,
  timezone          TEXT NOT NULL DEFAULT 'Asia/Kolkata',
  total_employees   INTEGER NOT NULL DEFAULT 0,
  present_today     INTEGER NOT NULL DEFAULT 0,
  address           TEXT,
  contact_person    TEXT,
  contact_phone     TEXT,
  pincode           TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS shifts (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id      UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name            TEXT NOT NULL,
  start_time      TIME NOT NULL,
  end_time        TIME NOT NULL,
  grace_minutes   INTEGER NOT NULL DEFAULT 15,
  assigned_count  INTEGER NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS employees (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  company_id      UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  branch_id       UUID REFERENCES branches(id) ON DELETE SET NULL,
  shift_id        UUID REFERENCES shifts(id) ON DELETE SET NULL,
  employee_code   TEXT NOT NULL,
  full_name       TEXT NOT NULL,
  phone           TEXT,
  job_role        TEXT,
  status          employee_status NOT NULL DEFAULT 'active',
  joined_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  deactivated_at  TIMESTAMPTZ,
  photo_url       TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(company_id, employee_code)
);

CREATE TABLE IF NOT EXISTS attendance_records (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id         UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  company_id          UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  branch_id           UUID REFERENCES branches(id) ON DELETE SET NULL,
  date                DATE NOT NULL,
  check_in_time       TIMESTAMPTZ,
  check_in_lat        NUMERIC,
  check_in_lng        NUMERIC,
  check_in_selfie     TEXT,
  is_in_geofence      BOOLEAN,
  liveness_passed     BOOLEAN,
  check_out_time      TIMESTAMPTZ,
  check_out_lat       NUMERIC,
  check_out_lng       NUMERIC,
  check_out_selfie    TEXT,
  status              attendance_status NOT NULL DEFAULT 'absent',
  total_hours         NUMERIC(5,2),
  is_manual_override  BOOLEAN NOT NULL DEFAULT FALSE,
  override_reason     TEXT,
  override_by         UUID,
  is_offline_sync     BOOLEAN NOT NULL DEFAULT FALSE,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(employee_id, date)
);

CREATE TABLE IF NOT EXISTS leave_types (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id      UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name            TEXT NOT NULL,
  days_per_year   INTEGER NOT NULL DEFAULT 0,
  UNIQUE(company_id, name)
);

CREATE TABLE IF NOT EXISTS leave_balances (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id     UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  leave_type_id   UUID NOT NULL REFERENCES leave_types(id) ON DELETE CASCADE,
  year            INTEGER NOT NULL,
  total           INTEGER NOT NULL DEFAULT 0,
  used            INTEGER NOT NULL DEFAULT 0,
  remaining       INTEGER GENERATED ALWAYS AS (total - used) STORED,
  UNIQUE(employee_id, leave_type_id, year)
);

CREATE TABLE IF NOT EXISTS leave_requests (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id     UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  company_id      UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  leave_type_id   UUID NOT NULL REFERENCES leave_types(id) ON DELETE CASCADE,
  from_date       DATE NOT NULL,
  to_date         DATE NOT NULL,
  days            INTEGER,
  reason          TEXT,
  status          request_status NOT NULL DEFAULT 'pending',
  reviewed_by     UUID,
  reviewed_at     TIMESTAMPTZ,
  admin_comment   TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS holidays (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id  UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  date        DATE NOT NULL,
  name        TEXT NOT NULL,
  type        TEXT NOT NULL DEFAULT 'public',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(company_id, date)
);

-- 3. KPI-FOCUSED INDEXES
-- ================================================================
CREATE INDEX IF NOT EXISTS idx_attendance_company_date ON attendance_records(company_id, date);
CREATE INDEX IF NOT EXISTS idx_attendance_company_status ON attendance_records(company_id, status);
CREATE INDEX IF NOT EXISTS idx_attendance_employee_date ON attendance_records(employee_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_attendance_date_status ON attendance_records(company_id, date, status);
CREATE INDEX IF NOT EXISTS idx_employees_company_branch ON employees(company_id, branch_id) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_leave_requests_company_status ON leave_requests(company_id, status);
CREATE INDEX IF NOT EXISTS idx_leave_requests_employee_dates ON leave_requests(employee_id, from_date, to_date) WHERE status = 'approved';
CREATE INDEX IF NOT EXISTS idx_profiles_company_role ON profiles(company_id, role);

-- 4. KPI MATERIALIZED VIEWS
-- ================================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_daily_attendance AS
SELECT
  a.company_id, a.date,
  COUNT(*)                                                         AS total_expected,
  COUNT(*) FILTER (WHERE a.status = 'present')                     AS present_count,
  COUNT(*) FILTER (WHERE a.status = 'late')                        AS late_count,
  COUNT(*) FILTER (WHERE a.status = 'absent')                      AS absent_count,
  COUNT(*) FILTER (WHERE a.status = 'half_day')                    AS half_day_count,
  COUNT(*) FILTER (WHERE a.check_in_time IS NOT NULL)              AS checked_in_count,
  COUNT(*) FILTER (WHERE a.check_out_time IS NOT NULL)             AS checked_out_count,
  ROUND((COUNT(*) FILTER (WHERE a.status IN ('present','late')) * 100.0 / NULLIF(COUNT(*), 0)), 1) AS attendance_rate,
  ROUND((COUNT(*) FILTER (WHERE a.status = 'late') * 100.0 / NULLIF(COUNT(*) FILTER (WHERE a.status IN ('present','late')), 0)), 1) AS late_percentage
FROM attendance_records a
GROUP BY a.company_id, a.date
ORDER BY a.company_id, a.date DESC;

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_daily_attendance ON mv_daily_attendance(company_id, date);

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_monthly_kpi AS
SELECT
  a.company_id,
  DATE_TRUNC('month', a.date)::DATE                                AS month,
  COUNT(*)                                                         AS total_expected,
  COUNT(*) FILTER (WHERE a.status = 'present')                     AS present_days,
  COUNT(*) FILTER (WHERE a.status = 'late')                        AS late_days,
  COUNT(*) FILTER (WHERE a.status = 'absent')                      AS absent_days,
  COUNT(*) FILTER (WHERE a.status = 'half_day')                    AS half_day_days,
  ROUND((COUNT(*) FILTER (WHERE a.status IN ('present','late')) * 100.0 / NULLIF(COUNT(*), 0)), 1) AS attendance_rate,
  ROUND((COUNT(*) FILTER (WHERE a.status = 'late') * 100.0 / NULLIF(COUNT(*) FILTER (WHERE a.status IN ('present','late')), 0)), 1) AS late_percentage,
  COUNT(DISTINCT a.employee_id)                                    AS unique_employees_attended,
  ROUND(AVG(a.total_hours) FILTER (WHERE a.total_hours IS NOT NULL), 2) AS avg_hours_per_day
FROM attendance_records a
GROUP BY a.company_id, DATE_TRUNC('month', a.date)
ORDER BY a.company_id, month DESC;

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_monthly_kpi ON mv_monthly_kpi(company_id, month);

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_today_branch_snapshot AS
SELECT
  a.company_id, a.branch_id, b.name AS branch_name, a.date,
  COUNT(*)                                                        AS total_expected,
  COUNT(*) FILTER (WHERE a.status = 'present')                    AS present,
  COUNT(*) FILTER (WHERE a.status = 'late')                       AS late,
  COUNT(*) FILTER (WHERE a.status = 'absent')                     AS absent,
  ROUND((COUNT(*) FILTER (WHERE a.status IN ('present','late')) * 100.0 / NULLIF(COUNT(*), 0)), 1) AS attendance_rate
FROM attendance_records a
JOIN branches b ON b.id = a.branch_id
WHERE a.date = CURRENT_DATE
GROUP BY a.company_id, a.branch_id, b.name, a.date;

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_today_branch ON mv_today_branch_snapshot(company_id, branch_id);

-- 5. REFRESH FUNCTION
-- ================================================================
CREATE OR REPLACE FUNCTION refresh_kpi_views()
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY mv_daily_attendance;
  REFRESH MATERIALIZED VIEW CONCURRENTLY mv_monthly_kpi;
  REFRESH MATERIALIZED VIEW CONCURRENTLY mv_today_branch_snapshot;
END;
$$;
