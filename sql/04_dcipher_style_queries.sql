-- ============================================================
-- 04_dcipher_style_queries.sql
-- Purpose: Queries that mirror analytical workflows performed
-- in CDC DCIPHER, the data management platform used for
-- COVID-19, Mpox, and other surveillance programs.
-- These queries demonstrate DCIPHER familiarity explicitly.
-- ============================================================

-- ── 1. COMPLETENESS MONITORING BY JURISDICTION ─────────────
-- In DCIPHER, completeness is monitored weekly by jurisdiction.
-- Program staff receive alerts when completeness drops below
-- 90% for any required field.
SELECT
    p.jurisdiction_id,
    COUNT(v.visit_id)                                           AS total_records,
    ROUND(SUM(CASE WHEN v.compliant_flag IS NOT NULL
              THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 1)        AS pct_complete_compliance,
    ROUND(SUM(CASE WHEN v.domain_storage IS NOT NULL
              THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 1)        AS pct_complete_storage,
    ROUND(SUM(CASE WHEN v.domain_documentation IS NOT NULL
              THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 1)        AS pct_complete_docs,
    ROUND((
        SUM(CASE WHEN v.compliant_flag IS NOT NULL THEN 1.0 ELSE 0 END) +
        SUM(CASE WHEN v.domain_storage IS NOT NULL THEN 1.0 ELSE 0 END) +
        SUM(CASE WHEN v.domain_documentation IS NOT NULL THEN 1.0 ELSE 0 END)
    ) / (COUNT(*) * 3) * 100, 1)                               AS overall_completeness_score,
    CASE
        WHEN (
            SUM(CASE WHEN v.compliant_flag IS NOT NULL THEN 1.0 ELSE 0 END) +
            SUM(CASE WHEN v.domain_storage IS NOT NULL THEN 1.0 ELSE 0 END) +
            SUM(CASE WHEN v.domain_documentation IS NOT NULL THEN 1.0 ELSE 0 END)
        ) / (COUNT(*) * 3) * 100 >= 95 THEN 'GREEN — On Target'
        WHEN (
            SUM(CASE WHEN v.compliant_flag IS NOT NULL THEN 1.0 ELSE 0 END) +
            SUM(CASE WHEN v.domain_storage IS NOT NULL THEN 1.0 ELSE 0 END) +
            SUM(CASE WHEN v.domain_documentation IS NOT NULL THEN 1.0 ELSE 0 END)
        ) / (COUNT(*) * 3) * 100 >= 85 THEN 'YELLOW — Needs Attention'
        ELSE 'RED — Below Threshold'
    END                                                         AS completeness_status
FROM visits v
JOIN providers p ON v.provider_id = p.provider_id
GROUP BY p.jurisdiction_id
ORDER BY overall_completeness_score ASC;

-- ── 2. INVESTIGATION STATUS SUMMARY ────────────────────────
-- Mirrors DCIPHER's case investigation status monitoring.
-- Here applied to corrective action status tracking.
SELECT
    corrective_action_type,
    COUNT(*)                                                    AS action_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1)        AS pct_of_total
FROM visits
WHERE corrective_action_issued = 'Y'
  AND corrective_action_type IS NOT NULL
GROUP BY corrective_action_type
ORDER BY action_count DESC;

-- ── 3. QUARTERLY TREND WITH ROLLING AVERAGE ────────────────
WITH quarterly AS (
    SELECT
        visit_year,
        visit_quarter,
        visit_year || '-Q' || visit_quarter                     AS year_quarter,
        COUNT(*)                                                AS total_visits,
        SUM(CASE WHEN compliant_flag='Y' THEN 1 ELSE 0 END)    AS compliant_visits,
        ROUND(SUM(CASE WHEN compliant_flag='Y'
                  THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 1)    AS compliance_rate
    FROM visits
    WHERE compliant_flag IS NOT NULL
    GROUP BY visit_year, visit_quarter
)
SELECT
    year_quarter,
    total_visits,
    compliance_rate,
    ROUND(AVG(compliance_rate) OVER (
        ORDER BY visit_year, visit_quarter
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 1)                                                        AS rolling_3q_avg
FROM quarterly
ORDER BY visit_year, visit_quarter;
