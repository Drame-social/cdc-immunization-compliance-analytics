-- ============================================================
-- 05_provider_risk_flags.sql
-- Purpose: Risk score each provider to identify those most
-- likely to unenroll. Enables proactive technical assistance.
-- ============================================================

WITH provider_metrics AS (
    SELECT
        v.provider_id,
        p.provider_type,
        p.jurisdiction_id,
        p.urban_rural,
        p.practice_size,
        p.months_enrolled,
        p.unenrolled_flag,
        COUNT(v.visit_id)                                       AS total_visits,
        SUM(CASE WHEN v.compliant_flag='N' THEN 1 ELSE 0 END)  AS noncompliant_visits,
        ROUND(SUM(CASE WHEN v.compliant_flag='N'
                  THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 1)    AS noncompliance_rate,
        SUM(v.helpdesk_tickets)                                 AS total_tickets,
        SUM(CASE WHEN v.corrective_action_issued='Y'
                 THEN 1 ELSE 0 END)                             AS corrective_actions,
        SUM(CASE WHEN v.domain_storage='N' THEN 1 ELSE 0 END)  AS storage_failures,
        SUM(CASE WHEN v.domain_documentation='N'
                 THEN 1 ELSE 0 END)                             AS doc_failures
    FROM visits v
    JOIN providers p ON v.provider_id = p.provider_id
    WHERE v.compliant_flag IS NOT NULL
    GROUP BY v.provider_id, p.provider_type, p.jurisdiction_id,
             p.urban_rural, p.practice_size, p.months_enrolled,
             p.unenrolled_flag
),
risk_scored AS (
    SELECT *,
        -- Risk scoring algorithm
        -- Each factor adds risk points; total determines category
        (
          CASE
            WHEN noncompliance_rate > 30 THEN 3
            WHEN noncompliance_rate > 15 THEN 2
            WHEN noncompliance_rate > 5  THEN 1
            ELSE 0
          END
        + CASE
            WHEN total_tickets > 5 THEN 3
            WHEN total_tickets > 2 THEN 2
            WHEN total_tickets > 0 THEN 1
            ELSE 0
          END
        + CASE
            WHEN corrective_actions > 2 THEN 2
            WHEN corrective_actions > 0 THEN 1
            ELSE 0
          END
        + CASE
            WHEN storage_failures > 1 THEN 2
            WHEN storage_failures > 0 THEN 1
            ELSE 0
          END
        + CASE WHEN urban_rural = 'Rural' THEN 1 ELSE 0 END
        )                                                       AS risk_score
    FROM provider_metrics
)
SELECT
    provider_id,
    provider_type,
    jurisdiction_id,
    urban_rural,
    practice_size,
    months_enrolled,
    total_visits,
    noncompliance_rate,
    total_tickets,
    corrective_actions,
    storage_failures,
    doc_failures,
    risk_score,
    CASE
        WHEN risk_score >= 7 THEN 'HIGH RISK — Immediate Outreach'
        WHEN risk_score >= 4 THEN 'MODERATE RISK — Schedule Review'
        WHEN risk_score >= 2 THEN 'LOW RISK — Monitor'
        ELSE 'COMPLIANT — Standard Monitoring'
    END                                                         AS risk_category,
    unenrolled_flag
FROM risk_scored
ORDER BY risk_score DESC, noncompliance_rate DESC;
