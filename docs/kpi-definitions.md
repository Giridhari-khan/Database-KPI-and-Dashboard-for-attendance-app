# KPI Definitions

All KPIs computed in materialized views from `sql/schema.sql`.

## Attendance Rate (%)

```
(present + late) × 100 / total_expected
```

```sql
ROUND((COUNT(*) FILTER (WHERE status IN ('present','late')) * 100.0 / NULLIF(COUNT(*), 0)), 1)
```

Healthy: >95%. Below 85% = chronic absenteeism.

## Late Percentage (%)

```
late × 100 / (present + late)
```

```sql
ROUND((COUNT(*) FILTER (WHERE status = 'late') * 100.0 / NULLIF(COUNT(*) FILTER (WHERE status IN ('present','late')), 0)), 1)
```

High late% + high attendance = shift timing issue, not discipline.

## Absenteeism Rate (%)

```
absent × 100 / total_expected
```

```sql
ROUND((COUNT(*) FILTER (WHERE status = 'absent') * 100.0 / NULLIF(COUNT(*), 0)), 1)
```

## Today's Cards

| Card | Query |
|------|-------|
| Present | `WHERE date = CURRENT_DATE AND status = 'present'` |
| Late | `WHERE date = CURRENT_DATE AND status = 'late'` |
| Absent | `WHERE date = CURRENT_DATE AND status = 'absent'` |
| Half-Day | `WHERE status = 'half_day'` |

## Monthly Trend

```sql
SELECT month, attendance_rate FROM mv_monthly_kpi
WHERE company_id = :id ORDER BY month DESC LIMIT 12;
```

## Branch Comparison (Today)

```sql
SELECT branch_name, present, late, absent, attendance_rate
FROM mv_today_branch_snapshot WHERE company_id = :id;
```

## Leave Utilization

```sql
SELECT SUM(used) * 100.0 / NULLIF(SUM(total), 0) FROM leave_balances
WHERE year = EXTRACT(YEAR FROM CURRENT_DATE) AND employee_id = :eid;
```

## Pending Approvals

```sql
SELECT COUNT(*) FROM leave_requests WHERE company_id = :id AND status = 'pending';
```

## Dashboard Query (Header Cards)

```sql
SELECT
  SUM(total_expected) AS total, SUM(present_count) AS present,
  SUM(late_count) AS late, SUM(absent_count) AS absent,
  ROUND((SUM(present_count + late_count) * 100.0 / NULLIF(SUM(total_expected), 0)), 1) AS rate
FROM mv_daily_attendance WHERE company_id = :id AND date = CURRENT_DATE;
```

## MV Refresh Strategy

| View | Frequency | Trigger |
|------|-----------|---------|
| `mv_today_branch_snapshot` | Every 5 min | Edge Function / pg_cron |
| `mv_daily_attendance` | Every 15 min | Edge Function / pg_cron |
| `mv_monthly_kpi` | Daily (midnight) | Edge Function / pg_cron |
