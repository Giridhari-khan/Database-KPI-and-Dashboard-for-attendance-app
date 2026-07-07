-- ================================================================
-- seed_data.sql — Demo data for KPI dashboard + RLS testing
--
-- Run AFTER schema.sql and rls_policies.sql.
-- All data is fictional — for demo/education only.
-- Creates 3 companies (15 employees, 7 days of attendance).
-- ================================================================

TRUNCATE attendance_records, leave_requests, leave_balances, holidays CASCADE;
TRUNCATE employees, shifts, branches CASCADE;
TRUNCATE companies CASCADE;

-- 1. COMPANIES (3 demo tenants)
INSERT INTO companies (id, client_code, name, contact_email, seat_count, pricing_plan, status) VALUES
  ('c0a00000-0000-4000-8000-000000000001', 'ACME',    'Acme Corp',  'admin@acme.demo',   50,  'Standard',   'active'),
  ('c0a00000-0000-4000-8000-000000000002', 'GLOBEX',  'Globex Inc', 'admin@globex.demo', 120, 'Enterprise', 'active'),
  ('c0a00000-0000-4000-8000-000000000003', 'INITECH', 'Initech',    'admin@initech.demo', 20,  'Normal',     'active');

-- 2. BRANCHES (1 per company)
INSERT INTO branches (id, company_id, name, lat, lng, timezone, total_employees) VALUES
  ('b0a00000-0000-4000-8000-000000000001', 'c0a00000-0000-4000-8000-000000000001', 'Mumbai HQ',   19.0760, 72.8777, 'Asia/Kolkata', 5),
  ('b0a00000-0000-4000-8000-000000000002', 'c0a00000-0000-4000-8000-000000000002', 'Delhi Office', 28.7041, 77.1025, 'Asia/Kolkata', 5),
  ('b0a00000-0000-4000-8000-000000000003', 'c0a00000-0000-4000-8000-000000000003', 'Bangalore Hub',12.9716, 77.5946, 'Asia/Kolkata', 5);

-- 3. SHIFTS
INSERT INTO shifts (id, company_id, name, start_time, end_time, grace_minutes, assigned_count) VALUES
  ('s0a00000-0000-4000-8000-000000000001', 'c0a00000-0000-4000-8000-000000000001', 'Day',   '09:00', '18:00', 15, 5),
  ('s0a00000-0000-4000-8000-000000000002', 'c0a00000-0000-4000-8000-000000000002', 'Day',   '08:00', '17:00', 15, 5),
  ('s0a00000-0000-4000-8000-000000000003', 'c0a00000-0000-4000-8000-000000000003', 'Flexi', '10:00', '19:00', 30, 5);

-- 4. EMPLOYEES (5 per company = 15 total)
INSERT INTO employees (id, company_id, branch_id, shift_id, employee_code, full_name, phone, job_role, status) VALUES
  -- Acme Corp
  ('e0a00000-0000-4000-8000-000000000001', 'c0a00000-0000-4000-8000-000000000001', 'b0a00000-0000-4000-8000-000000000001', 's0a00000-0000-4000-8000-000000000001', 'ACM-001', 'Amit Sharma',  '+919000000001', 'Guard',  'active'),
  ('e0a00000-0000-4000-8000-000000000002', 'c0a00000-0000-4000-8000-000000000001', 'b0a00000-0000-4000-8000-000000000001', 's0a00000-0000-4000-8000-000000000001', 'ACM-002', 'Bhavna Patel', '+919000000002', 'Guard',  'active'),
  ('e0a00000-0000-4000-8000-000000000003', 'c0a00000-0000-4000-8000-000000000001', 'b0a00000-0000-4000-8000-000000000001', 's0a00000-0000-4000-8000-000000000001', 'ACM-003', 'Chirag Singh', '+919000000003', 'Supervisor', 'active'),
  ('e0a00000-0000-4000-8000-000000000004', 'c0a00000-0000-4000-8000-000000000001', 'b0a00000-0000-4000-8000-000000000001', 's0a00000-0000-4000-8000-000000000001', 'ACM-004', 'Deepa Iyer',   '+919000000004', 'Guard',  'active'),
  ('e0a00000-0000-4000-8000-000000000005', 'c0a00000-0000-4000-8000-000000000001', 'b0a00000-0000-4000-8000-000000000001', 's0a00000-0000-4000-8000-000000000001', 'ACM-005', 'Esha Gupta',   '+919000000005', 'Guard',  'active'),
  -- Globex Inc
  ('e0b00000-0000-4000-8000-000000000001', 'c0a00000-0000-4000-8000-000000000002', 'b0a00000-0000-4000-8000-000000000002', 's0a00000-0000-4000-8000-000000000002', 'GLB-001', 'Farhan Khan',   '+919000000006', 'Guard',  'active'),
  ('e0b00000-0000-4000-8000-000000000002', 'c0a00000-0000-4000-8000-000000000002', 'b0a00000-0000-4000-8000-000000000002', 's0a00000-0000-4000-8000-000000000002', 'GLB-002', 'Geeta Reddy',  '+919000000007', 'Guard',  'active'),
  ('e0b00000-0000-4000-8000-000000000003', 'c0a00000-0000-4000-8000-000000000002', 'b0a00000-0000-4000-8000-000000000002', 's0a00000-0000-4000-8000-000000000002', 'GLB-003', 'Harish Nair',  '+919000000008', 'Supervisor', 'active'),
  ('e0b00000-0000-4000-8000-000000000004', 'c0a00000-0000-4000-8000-000000000002', 'b0a00000-0000-4000-8000-000000000002', 's0a00000-0000-4000-8000-000000000002', 'GLB-004', 'Ishita Jain',  '+919000000009', 'Guard',  'active'),
  ('e0b00000-0000-4000-8000-000000000005', 'c0a00000-0000-4000-8000-000000000002', 'b0a00000-0000-4000-8000-000000000002', 's0a00000-0000-4000-8000-000000000002', 'GLB-005', 'Jatin Verma',  '+919000000010', 'Guard',  'active'),
  -- Initech
  ('e0c00000-0000-4000-8000-000000000001', 'c0a00000-0000-4000-8000-000000000003', 'b0a00000-0000-4000-8000-000000000003', 's0a00000-0000-4000-8000-000000000003', 'INT-001', 'Kavya Rao',     '+919000000011', 'Guard',  'active'),
  ('e0c00000-0000-4000-8000-000000000002', 'c0a00000-0000-4000-8000-000000000003', 'b0a00000-0000-4000-8000-000000000003', 's0a00000-0000-4000-8000-000000000003', 'INT-002', 'Lokesh Shetty', '+919000000012', 'Guard',  'active'),
  ('e0c00000-0000-4000-8000-000000000003', 'c0a00000-0000-4000-8000-000000000003', 'b0a00000-0000-4000-8000-000000000003', 's0a00000-0000-4000-8000-000000000003', 'INT-003', 'Maya Krishnan', '+919000000013', 'Supervisor', 'active'),
  ('e0c00000-0000-4000-8000-000000000004', 'c0a00000-0000-4000-8000-000000000003', 'b0a00000-0000-4000-8000-000000000003', 's0a00000-0000-4000-8000-000000000003', 'INT-004', 'Nitin Joshi',   '+919000000014', 'Guard',  'active'),
  ('e0c00000-0000-4000-8000-000000000005', 'c0a00000-0000-4000-8000-000000000003', 'b0a00000-0000-4000-8000-000000000003', 's0a00000-0000-4000-8000-000000000003', 'INT-005', 'Aisha Kapoor',  '+919000000015', 'Guard',  'active');

-- 5. ATTENDANCE RECORDS (last 7 days)
INSERT INTO attendance_records (employee_id, company_id, branch_id, date, check_in_time, check_out_time, status, total_hours, is_in_geofence, liveness_passed)
SELECT
  e.id, e.company_id, e.branch_id, d.date,
  d.date + TIME '09:00' + (random() * interval '45 minutes'),
  d.date + TIME '18:00' + (random() * interval '30 minutes'),
  CASE (row_number() OVER (PARTITION BY e.id ORDER BY d.date)) % 5
    WHEN 0 THEN 'absent'::attendance_status
    WHEN 4 THEN 'late'::attendance_status
    ELSE 'present'::attendance_status
  END,
  ROUND((8 + random() * 1.5)::NUMERIC, 2), TRUE, TRUE
FROM employees e
CROSS JOIN (SELECT d::DATE AS date FROM generate_series(CURRENT_DATE - 7, CURRENT_DATE - 1, '1 day') AS d) d
WHERE NOT EXISTS (SELECT 1 FROM attendance_records a WHERE a.employee_id = e.id AND a.date = d.date);

-- 6. LEAVE TYPES
INSERT INTO leave_types (id, company_id, name, days_per_year) VALUES
  ('l0a00000-0000-4000-8000-000000000001', 'c0a00000-0000-4000-8000-000000000001', 'Casual', 12),
  ('l0a00000-0000-4000-8000-000000000002', 'c0a00000-0000-4000-8000-000000000001', 'Sick',   10),
  ('l0b00000-0000-4000-8000-000000000001', 'c0a00000-0000-4000-8000-000000000002', 'Casual', 12),
  ('l0b00000-0000-4000-8000-000000000002', 'c0a00000-0000-4000-8000-000000000002', 'Sick',   10),
  ('l0c00000-0000-4000-8000-000000000001', 'c0a00000-0000-4000-8000-000000000003', 'Casual', 12),
  ('l0c00000-0000-4000-8000-000000000002', 'c0a00000-0000-4000-8000-000000000003', 'Sick',   10);

-- 7. LEAVE BALANCES (full allocation for 2026)
INSERT INTO leave_balances (employee_id, leave_type_id, year, total, used)
SELECT e.id, lt.id, 2026, lt.days_per_year, 0
FROM employees e
JOIN leave_types lt ON lt.company_id = e.company_id
WHERE NOT EXISTS (SELECT 1 FROM leave_balances lb WHERE lb.employee_id = e.id AND lb.leave_type_id = lt.id AND lb.year = 2026);

-- 8. PENDING LEAVE REQUESTS (demo)
INSERT INTO leave_requests (employee_id, company_id, leave_type_id, from_date, to_date, days, reason, status)
SELECT e.id, e.company_id, lt.id, CURRENT_DATE + 10, CURRENT_DATE + 10, 1, 'Personal work', 'pending'
FROM employees e
JOIN leave_types lt ON lt.company_id = e.company_id AND lt.name = 'Casual'
WHERE e.employee_code IN ('ACM-001', 'GLB-002', 'INT-003')
AND NOT EXISTS (SELECT 1 FROM leave_requests lr WHERE lr.employee_id = e.id AND lr.status = 'pending');

-- 9. HOLIDAYS
INSERT INTO holidays (company_id, date, name, type)
SELECT c.id, d::DATE, h.name, h.type
FROM companies c
CROSS JOIN (VALUES (CURRENT_DATE + 15, 'Demo Holiday', 'public'), (CURRENT_DATE + 45, 'Demo Festival', 'public')) AS h(date, name, type)
WHERE NOT EXISTS (SELECT 1 FROM holidays h2 WHERE h2.company_id = c.id AND h2.date = h.date::DATE);

-- 10. REFRESH KPI VIEWS
SELECT refresh_kpi_views();
