-- ============================================================
-- 02_data_quality_checks.sql
-- Purpose: Validate completeness, validity, and integrity
-- of the immunization provider compliance dataset.
-- Mirrors data quality monitoring performed in CDC DCIPHER.
-- ============================================================

-- ── 1. ROW COUNTS ──────────────────────────────────────────
SELECT 'providers'    AS table_name, COUNT(*) AS row_count FROM providers
UNION ALL
SELECT 'visits',                     COUNT(*)              FROM visits
UNION ALL
SELECT 'unenrollments',              COUNT(*)              FROM unenrollments;

-- ── 2. COMPLETENESS REPORT — VISITS TABLE ──────────────────
-- Shows percent missing for each field.
-- Mirrors the completeness dashboard in CDC DCIPHER.
SELECT
    COUNT(*)                                                AS total_visits,
    ROUND(SUM(CASE WHEN compliant_flag IS NULL
              THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 1)   AS pct_missing_compliant,
    ROUND(SUM(CASE WHEN domain_storage IS NULL
              THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 1)   AS pct_missing_storage,
    ROUND(SUM(CASE WHEN domain_temperature IS NULL
              THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 1)   AS pct_missing_temperature,
    ROUND(SUM(CASE WHEN domain_documentation IS NULL
              THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 1)   AS pct_missing_documentation,
    ROUND(SUM(CASE WHEN domain_inventory IS NULL
              THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 1)   AS pct_missing_inventory,
    ROUND(SUM(CASE WHEN domain_patient_eligibility IS NULL
              THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 1)   AS pct_missing_eligibility,
    ROUND(SUM(CASE WHEN corrective_action_issued IS NULL
              THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 1)   AS pct_missing_ca_issued
FROM visits;

-- ── 3. DUPLICATE DETECTION ─────────────────────────────────
SELECT visit_id, COUNT(*) AS record_count
FROM visits
GROUP BY visit_id
HAVING COUNT(*) > 1;

-- ── 4. REFERENTIAL INTEGRITY ───────────────────────────────
-- Any provider_id in visits that does not exist in providers
-- would indicate a referential integrity failure.
SELECT v.provider_id,
       COUNT(*) AS orphaned_visit_count
FROM visits v
LEFT JOIN providers p ON v.provider_id = p.provider_id
WHERE p.provider_id IS NULL
GROUP BY v.provider_id;

-- ── 5. INVALID CODED VALUES ────────────────────────────────
SELECT visit_id, compliant_flag, domain_storage,
       corrective_action_issued, helpdesk_tickets
FROM visits
WHERE
    (compliant_flag NOT IN ('Y','N') AND compliant_flag IS NOT NULL)
    OR (domain_storage NOT IN ('Y','N') AND domain_storage IS NOT NULL)
    OR (corrective_action_issued NOT IN ('Y','N')
        AND corrective_action_issued IS NOT NULL)
    OR helpdesk_tickets < 0;

-- ── 6. CORRECTIVE ACTION LOGIC CHECK ───────────────────────
-- corrective_action_type should be null when no CA was issued
SELECT visit_id, corrective_action_issued, corrective_action_type
FROM visits
WHERE corrective_action_issued = 'N'
  AND corrective_action_type IS NOT NULL
  AND corrective_action_type <> 'None';

-- ── 7. DATE RANGE VALIDATION ───────────────────────────────
SELECT visit_id, visit_date
FROM visits
WHERE visit_date < '2022-01-01'
   OR visit_date > '2024-12-31';
