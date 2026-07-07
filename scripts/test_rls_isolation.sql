-- ================================================================
-- RLS Isolation Test Suite
--
-- Run AFTER seed_data.sql. Replace placeholders with actual UUIDs
-- from your seeded data. Each test requires simulating a different
-- JWT claim via set_config().
-- ================================================================

-- Simulate a JWT: SELECT set_config('request.jwt.claims',
--   '{"sub": "<user-uuid>", "role": "authenticated"}', true);

-- ── TEST 1: Company admin sees only their own employees ──────────
-- Expected: 1 row with their own company
-- SELECT c.name, COUNT(*) FROM employees e
-- JOIN companies c ON c.id = e.company_id GROUP BY c.name;

-- ── TEST 2: Super admin sees all companies ──────────────────────
-- Expected: 3 rows
-- SELECT c.name, COUNT(*) FROM employees e
-- JOIN companies c ON c.id = e.company_id GROUP BY c.name;

-- ── TEST 3: Cross-tenant SELECT blocked ─────────────────────────
-- Expected: 0 rows
-- SELECT * FROM employees WHERE company_id = '<other-company-id>';

-- ── TEST 4: Cross-tenant INSERT blocked ─────────────────────────
-- Expected: ERROR or 0 rows inserted
-- INSERT INTO attendance_records (employee_id, company_id, date, status)
-- VALUES ('<other-co-employee>', '<other-company-id>', CURRENT_DATE, 'present');

-- ── TEST 5: KPI MV isolation ────────────────────────────────────
-- Expected: Only own company's rows
-- SELECT company_id, date, attendance_rate FROM mv_daily_attendance LIMIT 10;

-- ── TEST 6: Profiles self-select only ───────────────────────────
-- Expected: Only 1 row (own profile)
-- SELECT id, role, company_id FROM profiles;

-- ── TEST 7: Holiday isolation ───────────────────────────────────
-- Expected: Only own company's holidays
-- SELECT c.name, h.date, h.name FROM holidays h
-- JOIN companies c ON c.id = h.company_id;

-- Cleanup: SELECT set_config('request.jwt.claims', '{}', true);
