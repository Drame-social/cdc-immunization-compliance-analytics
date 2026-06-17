-- ============================================================
-- 03_compliance_analysis.sql
-- Purpose: Epidemiologic analysis of immunization provider
-- compliance patterns.
-- Public health question: Which provider characteristics are
-- associated with noncompliance and unenrollment?
-- ============================================================

-- ── 1. OVERALL COMPLIANCE RATE ─────────────────────────────
SELECT
    COUNT(*)                                                    AS total_visits,
    SUM(CASE WHEN compliant_flag='Y' THEN 1 ELSE 0 END)        AS compliant_visits,
    ROUND(SUM(CASE WHEN compliant_flag='Y'
              THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 1)        AS overall_compliance_rate
FROM visits
WHERE compliant_flag IS NOT NULL;

-- ── 2. COMPLIANCE RATE BY PROVIDER TYPE ────────────────────
-- Ranked by compliance rate — tells program managers which
-- provider types need the most technical assistance.
WITH compliance_by_type AS (
    SELECT
        p.provider_type,
        COUNT(DISTINCT v.provider_id)                           AS provider_count,
        COUNT(v.visit_id)                                       AS total_visits,
        SUM(CASE WHEN v.compliant_flag='Y' THEN 1 ELSE 0 END)  AS compliant_visits,
        ROUND(
            SUM(CASE WHEN v.compliant_flag='Y' THEN 1.0 ELSE 0 END) /
            NULLIF(COUNT(v.visit_id), 0) * 100, 1
        )                                                        AS compliance_rate
    FROM visits v
    JOIN providers p ON v.provider_id = p.provider_id
    WHERE v.compliant_flag IS NOT NULL
    GROUP BY p.provider_type
)
SELECT *,
    RANK() OVER (ORDER BY compliance_rate DESC) AS compliance_rank
FROM compliance_by_type
ORDER BY compliance_rate DESC;

-- ── 3. YEAR-OVER-YEAR COMPLIANCE TREND ─────────────────────
-- Uses LAG window function to calculate year-over-year change.
-- Mirrors the trending output produced in CDC DCIPHER reports.
WITH yearly AS (
    SELECT
        visit_year,
        COUNT(*)                                                AS total_visits,
        SUM(CASE WHEN compliant_flag='Y' THEN 1 ELSE 0 END)    AS compliant_visits,
        ROUND(
            SUM(CASE WHEN compliant_flag='Y' THEN 1.0 ELSE 0 END) /
            COUNT(*) * 100, 1
        )                                                        AS compliance_rate
    FROM visits
    WHERE compliant_flag IS NOT NULL
    GROUP BY visit_year
)
SELECT
    visit_year,
    total_visits,
    compliant_visits,
    compliance_rate,
    LAG(compliance_rate, 1) OVER (ORDER BY visit_year)         AS prior_year_rate,
    ROUND(
        compliance_rate
        - LAG(compliance_rate, 1) OVER (ORDER BY visit_year), 1
    )                                                           AS yoy_change
FROM yearly
ORDER BY visit_year;

-- ── 4. DOMAIN-LEVEL FAILURE RATES ──────────────────────────
-- Which compliance domain fails most often?
-- This tells program managers where to focus education.
SELECT
    'Storage and Handling'       AS domain,
    ROUND(SUM(CASE WHEN domain_storage='N'
              THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 1)         AS failure_rate
FROM visits WHERE domain_storage IS NOT NULL
UNION ALL
SELECT
    'Temperature Monitoring',
    ROUND(SUM(CASE WHEN domain_temperature='N'
              THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 1)
FROM visits WHERE domain_temperature IS NOT NULL
UNION ALL
SELECT
    'Documentation',
    ROUND(SUM(CASE WHEN domain_documentation='N'
              THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 1)
FROM visits WHERE domain_documentation IS NOT NULL
UNION ALL
SELECT
    'Inventory Management',
    ROUND(SUM(CASE WHEN domain_inventory='N'
              THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 1)
FROM visits WHERE domain_inventory IS NOT NULL
UNION ALL
SELECT
    'Patient Eligibility',
    ROUND(SUM(CASE WHEN domain_patient_eligibility='N'
              THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 1)
FROM visits WHERE domain_patient_eligibility IS NOT NULL
ORDER BY failure_rate DESC;

-- ── 5. COMPLIANCE BY JURISDICTION ──────────────────────────
SELECT
    p.jurisdiction_id,
    COUNT(DISTINCT v.provider_id)                               AS provider_count,
    COUNT(v.visit_id)                                           AS total_visits,
    ROUND(SUM(CASE WHEN v.compliant_flag='Y'
              THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 1)        AS compliance_rate,
    RANK() OVER (
        ORDER BY
        SUM(CASE WHEN v.compliant_flag='Y' THEN 1.0 ELSE 0 END) /
        COUNT(*) DESC
    )                                                           AS jurisdiction_rank
FROM visits v
JOIN providers p ON v.provider_id = p.provider_id
WHERE v.compliant_flag IS NOT NULL
GROUP BY p.jurisdiction_id
ORDER BY compliance_rate DESC;
