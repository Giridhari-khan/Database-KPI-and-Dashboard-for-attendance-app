# RLS Deep Dive — Multi-Tenant Security

## Architecture

RLS isolates data via `company_id` on every table. JWT → `profiles(role, company_id)` decides visibility.

## 4 RLS Bugs & Fixes

### Bug 1 — Missing `WITH CHECK` on INSERT

`USING` controls SELECT/UPDATE/DELETE. **`WITH CHECK`** controls INSERT. Without it:

```sql
-- ❌ Employee can forge attendance for ANY employee_id
CREATE POLICY "bad" ON attendance_records FOR INSERT TO authenticated
  WITH CHECK (true);

-- ✅ Only allows INSERT where employee links to auth user
CREATE POLICY "fixed" ON attendance_records FOR INSERT TO authenticated
  WITH CHECK (employee_id IN (SELECT id FROM employees WHERE user_id = auth.uid()));
```

### Bug 2 — Recursive `profiles` Policy

```sql
-- ❌ Queries profiles while filtering profiles = infinite recursion
CREATE POLICY "bad" ON profiles FOR SELECT USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'super_admin')
);

-- ✅ Non-recursive: direct auth.uid() comparison
CREATE POLICY "self" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "super" ON profiles FOR ALL USING (
  auth.uid() IN (SELECT id FROM profiles WHERE role = 'super_admin')
);
```

### Bug 3 — Materialized Views Without Own RLS

MVs **do not inherit** base-table RLS. Must define policies on the MV explicitly:

```sql
ALTER TABLE mv_daily_attendance ENABLE ROW LEVEL SECURITY;
CREATE POLICY "company_access" ON mv_daily_attendance FOR SELECT USING (
  company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())
);
```

Without this, a company admin querying `mv_daily_attendance` sees **all companies'** data.

### Bug 4 — UNIQUE Constraint Info Leak

`UNIQUE(employee_id, date)` + failed INSERT = error confirming row exists:

```
ERROR: duplicate key violates unique constraint
```

**Mitigations:** `ON CONFLICT DO NOTHING`, advisory locks, or accept for low-sensitivity data.

## Cheat Sheet

| Rule | Why |
|------|-----|
| Always pair `USING` + `WITH CHECK` | `WITH CHECK` is the only INSERT gate |
| Keep `profiles` policies non-recursive | Recursion → silent failures |
| Add RLS to MVs explicitly | MVs don't inherit base table RLS |
| Prefer `auth.uid()` over subqueries | Faster, no recursion risk |
| `DROP POLICY IF EXISTS` before `CREATE` | Avoid duplicate policy errors |
