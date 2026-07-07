-- ================================================================
-- grants.sql — Role-based table permissions
--
-- ⚠ REFERENCE IMPLEMENTATION — for demo/education only.
-- Run AFTER schema.sql + rls_policies.sql.
-- ================================================================

-- ════════════════════════════════════════════════════════════════
-- 1. USAGE on schema
-- ════════════════════════════════════════════════════════════════

GRANT USAGE ON SCHEMA public TO authenticated, anon, service_role;

-- ════════════════════════════════════════════════════════════════
-- 2. TABLES — authenticated users
-- ════════════════════════════════════════════════════════════════

-- Core tables
GRANT SELECT, INSERT, UPDATE ON companies            TO authenticated;
GRANT SELECT, INSERT, UPDATE ON profiles             TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON branches     TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON shifts       TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON employees    TO authenticated;
GRANT SELECT, INSERT, UPDATE       ON attendance_records TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON leave_types  TO authenticated;
GRANT SELECT, INSERT, UPDATE       ON leave_balances TO authenticated;
GRANT SELECT, INSERT, UPDATE       ON leave_requests TO authenticated;
GRANT SELECT                       ON holidays       TO authenticated;

-- KPI materialized views (read-only)
GRANT SELECT ON mv_daily_attendance       TO authenticated;
GRANT SELECT ON mv_monthly_kpi            TO authenticated;
GRANT SELECT ON mv_today_branch_snapshot  TO authenticated;

-- ════════════════════════════════════════════════════════════════
-- 3. TABLES — anon (unauthenticated, very limited)
-- ════════════════════════════════════════════════════════════════

-- Only allow inserting leads from the landing page form
-- GRANT INSERT ON leads TO anon;

-- ════════════════════════════════════════════════════════════════
-- 4. SEQUENCES (if any)
-- ════════════════════════════════════════════════════════════════

-- GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- ════════════════════════════════════════════════════════════════
-- 5. FUNCTIONS
-- ════════════════════════════════════════════════════════════════

GRANT EXECUTE ON FUNCTION refresh_kpi_views() TO authenticated;

-- ════════════════════════════════════════════════════════════════
-- 6. service_role (backend Edge Functions / API)
-- ════════════════════════════════════════════════════════════════

-- Service role bypasses RLS entirely — grant ONLY what's needed.
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO service_role;

-- ════════════════════════════════════════════════════════════════
-- 7. DEFAULT PRIVILEGES (future tables)
-- ════════════════════════════════════════════════════════════════

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT ALL ON TABLES TO service_role;
