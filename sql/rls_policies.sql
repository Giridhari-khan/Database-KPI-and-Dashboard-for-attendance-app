-- ================================================================
-- rls_policies.sql — Row-Level Security for multi-tenant attendance
--
-- ⚠ REFERENCE IMPLEMENTATION — for demo/education only.
-- All policies are idempotent (DROP + CREATE).
--
-- Roles:
--   super_admin   → full access across ALL companies
--   company_admin → sees ONLY their own company's data
--   employee      → sees ONLY their own records
-- ================================================================

-- ════════════════════════════════════════════════════════════════
-- 1. PROFILES
-- ════════════════════════════════════════════════════════════════

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "profiles_self_select" ON profiles;
CREATE POLICY "profiles_self_select" ON profiles
  FOR SELECT TO authenticated
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "profiles_super_admin_all" ON profiles;
CREATE POLICY "profiles_super_admin_all" ON profiles
  FOR ALL TO authenticated
  USING (auth.uid() IN (SELECT id FROM profiles WHERE role = 'super_admin'))
  WITH CHECK (auth.uid() IN (SELECT id FROM profiles WHERE role = 'super_admin'));

DROP POLICY IF EXISTS "profiles_company_admin_select" ON profiles;
CREATE POLICY "profiles_company_admin_select" ON profiles
  FOR SELECT TO authenticated
  USING (
    auth.uid() IN (SELECT id FROM profiles WHERE role = 'super_admin')
    OR
    company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())
  );

-- ════════════════════════════════════════════════════════════════
-- 2. COMPANIES
-- ════════════════════════════════════════════════════════════════

ALTER TABLE companies ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "companies_super_admin_all" ON companies;
CREATE POLICY "companies_super_admin_all" ON companies
  FOR ALL TO authenticated
  USING (auth.uid() IN (SELECT id FROM profiles WHERE role = 'super_admin'))
  WITH CHECK (auth.uid() IN (SELECT id FROM profiles WHERE role = 'super_admin'));

DROP POLICY IF EXISTS "companies_company_admin_select" ON companies;
CREATE POLICY "companies_company_admin_select" ON companies
  FOR SELECT TO authenticated
  USING (
    id IN (SELECT company_id FROM profiles WHERE id = auth.uid())
    OR
    auth.uid() IN (SELECT id FROM profiles WHERE role = 'super_admin')
  );

-- ════════════════════════════════════════════════════════════════
-- 3. BRANCHES
-- ════════════════════════════════════════════════════════════════

ALTER TABLE branches ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "branches_super_admin_all" ON branches;
CREATE POLICY "branches_super_admin_all" ON branches
  FOR ALL TO authenticated
  USING (auth.uid() IN (SELECT id FROM profiles WHERE role = 'super_admin'))
  WITH CHECK (auth.uid() IN (SELECT id FROM profiles WHERE role = 'super_admin'));

DROP POLICY IF EXISTS "branches_company_admin" ON branches;
CREATE POLICY "branches_company_admin" ON branches
  FOR ALL TO authenticated
  USING (
    company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())
  )
  WITH CHECK (
    company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())
  );

-- ════════════════════════════════════════════════════════════════
-- 4. SHIFTS
-- ════════════════════════════════════════════════════════════════

ALTER TABLE shifts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "shifts_super_admin_all" ON shifts;
CREATE POLICY "shifts_super_admin_all" ON shifts
  FOR ALL TO authenticated
  USING (auth.uid() IN (SELECT id FROM profiles WHERE role = 'super_admin'))
  WITH CHECK (auth.uid() IN (SELECT id FROM profiles WHERE role = 'super_admin'));

DROP POLICY IF EXISTS "shifts_company_admin" ON shifts;
CREATE POLICY "shifts_company_admin" ON shifts
  FOR ALL TO authenticated
  USING (
    company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())
  )
  WITH CHECK (
    company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())
  );

-- ════════════════════════════════════════════════════════════════
-- 5. EMPLOYEES
-- ════════════════════════════════════════════════════════════════

ALTER TABLE employees ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "employees_super_admin_all" ON employees;
CREATE POLICY "employees_super_admin_all" ON employees
  FOR ALL TO authenticated
  USING (auth.uid() IN (SELECT id FROM profiles WHERE role = 'super_admin'))
  WITH CHECK (auth.uid() IN (SELECT id FROM profiles WHERE role = 'super_admin'));

DROP POLICY IF EXISTS "employees_company_admin" ON employees;
CREATE POLICY "employees_company_admin" ON employees
  FOR ALL TO authenticated
  USING (
    company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())
  )
  WITH CHECK (
    company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())
  );

DROP POLICY IF EXISTS "employees_self_select" ON employees;
CREATE POLICY "employees_self_select" ON employees
  FOR SELECT TO authenticated
  USING (
    user_id = auth.uid()
    OR
    company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())
    OR
    auth.uid() IN (SELECT id FROM profiles WHERE role = 'super_admin')
  );

-- ════════════════════════════════════════════════════════════════
-- 6. ATTENDANCE RECORDS (KPI DATA SOURCE — HIGHEST TRAFFIC)
-- ════════════════════════════════════════════════════════════════

ALTER TABLE attendance_records ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "attendance_super_admin_all" ON attendance_records;
CREATE POLICY "attendance_super_admin_all" ON attendance_records
  FOR ALL TO authenticated
  USING (auth.uid() IN (SELECT id FROM profiles WHERE role = 'super_admin'))
  WITH CHECK (auth.uid() IN (SELECT id FROM profiles WHERE role = 'super_admin'));

DROP POLICY IF EXISTS "attendance_company_admin" ON attendance_records;
CREATE POLICY "attendance_company_admin" ON attendance_records
  FOR ALL TO authenticated
  USING (
    company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())
  )
  WITH CHECK (
    company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())
  );

--   IMPORTANT: The WHERE clause ensures the employee can only
--   INSERT their OWN attendance (employee row links to their auth.uid()).
DROP POLICY IF EXISTS "attendance_employee_insert" ON attendance_records;
CREATE POLICY "attendance_employee_insert" ON attendance_records
  FOR INSERT TO authenticated
  WITH CHECK (
    employee_id IN (SELECT id FROM employees WHERE user_id = auth.uid())
  );

DROP POLICY IF EXISTS "attendance_employee_select" ON attendance_records;
CREATE POLICY "attendance_employee_select" ON attendance_records
  FOR SELECT TO authenticated
  USING (
    employee_id IN (SELECT id FROM employees WHERE user_id = auth.uid())
    OR
    company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())
    OR
    auth.uid() IN (SELECT id FROM profiles WHERE role = 'super_admin')
  );

-- ════════════════════════════════════════════════════════════════
-- 7. LEAVE TYPES
-- ════════════════════════════════════════════════════════════════

ALTER TABLE leave_types ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "leave_types_super_admin_all" ON leave_types;
CREATE POLICY "leave_types_super_admin_all" ON leave_types
  FOR ALL TO authenticated
  USING (auth.uid() IN (SELECT id FROM profiles WHERE role = 'super_admin'))
  WITH CHECK (auth.uid() IN (SELECT id FROM profiles WHERE role = 'super_admin'));

DROP POLICY IF EXISTS "leave_types_company_admin" ON leave_types;
CREATE POLICY "leave_types_company_admin" ON leave_types
  FOR ALL TO authenticated
  USING (
    company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())
  )
  WITH CHECK (
    company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())
  );

-- ════════════════════════════════════════════════════════════════
-- 8. LEAVE BALANCES
-- ════════════════════════════════════════════════════════════════

ALTER TABLE leave_balances ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "leave_balances_super_admin_all" ON leave_balances;
CREATE POLICY "leave_balances_super_admin_all" ON leave_balances
  FOR ALL TO authenticated
  USING (auth.uid() IN (SELECT id FROM profiles WHERE role = 'super_admin'))
  WITH CHECK (auth.uid() IN (SELECT id FROM profiles WHERE role = 'super_admin'));

DROP POLICY IF EXISTS "leave_balances_company_admin" ON leave_balances;
CREATE POLICY "leave_balances_company_admin" ON leave_balances
  FOR ALL TO authenticated
  USING (
    employee_id IN (SELECT id FROM employees WHERE company_id IN
      (SELECT company_id FROM profiles WHERE id = auth.uid()))
  )
  WITH CHECK (
    employee_id IN (SELECT id FROM employees WHERE company_id IN
      (SELECT company_id FROM profiles WHERE id = auth.uid()))
  );

DROP POLICY IF EXISTS "leave_balances_employee_select" ON leave_balances;
CREATE POLICY "leave_balances_employee_select" ON leave_balances
  FOR SELECT TO authenticated
  USING (
    employee_id IN (SELECT id FROM employees WHERE user_id = auth.uid())
  );

-- ════════════════════════════════════════════════════════════════
-- 9. LEAVE REQUESTS
-- ════════════════════════════════════════════════════════════════

ALTER TABLE leave_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "leave_requests_super_admin_all" ON leave_requests;
CREATE POLICY "leave_requests_super_admin_all" ON leave_requests
  FOR ALL TO authenticated
  USING (auth.uid() IN (SELECT id FROM profiles WHERE role = 'super_admin'))
  WITH CHECK (auth.uid() IN (SELECT id FROM profiles WHERE role = 'super_admin'));

DROP POLICY IF EXISTS "leave_requests_company_admin" ON leave_requests;
CREATE POLICY "leave_requests_company_admin" ON leave_requests
  FOR ALL TO authenticated
  USING (
    company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())
  )
  WITH CHECK (
    company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())
  );

DROP POLICY IF EXISTS "leave_requests_employee_insert" ON leave_requests;
CREATE POLICY "leave_requests_employee_insert" ON leave_requests
  FOR INSERT TO authenticated
  WITH CHECK (
    employee_id IN (SELECT id FROM employees WHERE user_id = auth.uid())
  );

DROP POLICY IF EXISTS "leave_requests_employee_select" ON leave_requests;
CREATE POLICY "leave_requests_employee_select" ON leave_requests
  FOR SELECT TO authenticated
  USING (
    employee_id IN (SELECT id FROM employees WHERE user_id = auth.uid())
  );

-- ════════════════════════════════════════════════════════════════
-- 10. HOLIDAYS
-- ════════════════════════════════════════════════════════════════

ALTER TABLE holidays ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "holidays_super_admin_all" ON holidays;
CREATE POLICY "holidays_super_admin_all" ON holidays
  FOR ALL TO authenticated
  USING (auth.uid() IN (SELECT id FROM profiles WHERE role = 'super_admin'))
  WITH CHECK (auth.uid() IN (SELECT id FROM profiles WHERE role = 'super_admin'));

DROP POLICY IF EXISTS "holidays_company_admin" ON holidays;
CREATE POLICY "holidays_company_admin" ON holidays
  FOR ALL TO authenticated
  USING (
    company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())
  )
  WITH CHECK (
    company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())
  );

DROP POLICY IF EXISTS "holidays_employee_select" ON holidays;
CREATE POLICY "holidays_employee_select" ON holidays
  FOR SELECT TO authenticated
  USING (
    company_id IN (SELECT company_id FROM employees WHERE user_id = auth.uid())
  );

-- ════════════════════════════════════════════════════════════════
-- 11. KPI MATERIALIZED VIEWS (read-only for company admins)
-- ════════════════════════════════════════════════════════════════

ALTER TABLE mv_daily_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE mv_monthly_kpi ENABLE ROW LEVEL SECURITY;
ALTER TABLE mv_today_branch_snapshot ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "mv_daily_attendance_super_admin" ON mv_daily_attendance;
CREATE POLICY "mv_daily_attendance_super_admin" ON mv_daily_attendance
  FOR SELECT TO authenticated
  USING (auth.uid() IN (SELECT id FROM profiles WHERE role = 'super_admin'));

DROP POLICY IF EXISTS "mv_daily_attendance_company_admin" ON mv_daily_attendance;
CREATE POLICY "mv_daily_attendance_company_admin" ON mv_daily_attendance
  FOR SELECT TO authenticated
  USING (
    company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())
  );

DROP POLICY IF EXISTS "mv_monthly_kpi_super_admin" ON mv_monthly_kpi;
CREATE POLICY "mv_monthly_kpi_super_admin" ON mv_monthly_kpi
  FOR SELECT TO authenticated
  USING (auth.uid() IN (SELECT id FROM profiles WHERE role = 'super_admin'));

DROP POLICY IF EXISTS "mv_monthly_kpi_company_admin" ON mv_monthly_kpi;
CREATE POLICY "mv_monthly_kpi_company_admin" ON mv_monthly_kpi
  FOR SELECT TO authenticated
  USING (
    company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())
  );

DROP POLICY IF EXISTS "mv_today_branch_snapshot_super_admin" ON mv_today_branch_snapshot;
CREATE POLICY "mv_today_branch_snapshot_super_admin" ON mv_today_branch_snapshot
  FOR SELECT TO authenticated
  USING (auth.uid() IN (SELECT id FROM profiles WHERE role = 'super_admin'));

DROP POLICY IF EXISTS "mv_today_branch_snapshot_company_admin" ON mv_today_branch_snapshot;
CREATE POLICY "mv_today_branch_snapshot_company_admin" ON mv_today_branch_snapshot
  FOR SELECT TO authenticated
  USING (
    company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())
  );

-- ════════════════════════════════════════════════════════════════
-- COMMON BUG NOTES
-- ════════════════════════════════════════════════════════════════
--
-- BUG #1 — Missing WITH CHECK on INSERT policies
--   Without WITH CHECK, an employee could insert attendance for
--   someone else's employee_id. Always pair USING (SELECT) with
--   WITH CHECK (INSERT/UPDATE).
--
-- BUG #2 — Recursive policy on profiles
--   Profiles policies should NOT query profiles in a way that
--   creates infinite recursion. Use direct auth.uid() comparisons
--   where possible.
--
-- BUG #3 — Materialized views inheriting RLS from base tables
--   MVs get their OWN RLS. You MUST define separate policies on
--   the MV itself — the base table policies do NOT apply.
--
-- BUG #4 — UNIQUE constraint conflict with RLS
--   A UNIQUE(employee_id, date) on attendance_records means RLS
--   cannot prevent a user from seeing whether a conflicting row
--   exists (error message leaks existence). Use advisory locking
--   or application-level checks for sensitive uniqueness.
-- ════════════════════════════════════════════════════════════════
