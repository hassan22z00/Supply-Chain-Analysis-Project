SELECT
    'dim_procurement_case' AS table_name,
    COUNT(*) AS total_rows
FROM procurement.dim_procurement_case

UNION ALL

SELECT
    'fact_procurement_event',
    COUNT(*)
FROM procurement.fact_procurement_event

UNION ALL

SELECT
    'mart_invoice_monitoring',
    COUNT(*)
FROM procurement.mart_invoice_monitoring;


-- =========================================
-- 1. PERFORMANCE INDEXES
-- =========================================

CREATE INDEX IF NOT EXISTS idx_event_case_timestamp
ON procurement.fact_procurement_event
(case_id, event_timestamp, source_row);

CREATE INDEX IF NOT EXISTS idx_event_activity
ON procurement.fact_procurement_event
(activity);

CREATE INDEX IF NOT EXISTS idx_invoice_company
ON procurement.mart_invoice_monitoring
(company);


-- =========================================
-- 2. OVERALL INVOICE KPI VIEW
-- =========================================

CREATE OR REPLACE VIEW procurement.vw_invoice_kpis_overall AS

SELECT

    COUNT(*) AS total_invoice_cases,

    COUNT(*) FILTER (
        WHERE invoice_clearing_status = 'CLEARED_AFTER_RECEIPT'
    ) AS cleared_after_receipt,

    COUNT(*) FILTER (
        WHERE invoice_clearing_status = 'NO_RECORDED_CLEARING'
    ) AS no_recorded_clearing,

    COUNT(*) FILTER (
        WHERE invoice_clearing_status = 'CLEARING_NOT_AFTER_RECEIPT'
    ) AS clearing_not_after_receipt,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE invoice_clearing_status = 'NO_RECORDED_CLEARING'
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS no_recorded_clearing_pct,

    ROUND((
        PERCENTILE_CONT(0.50)
        WITHIN GROUP (
            ORDER BY invoice_cycle_days::double precision
        )
        FILTER (WHERE invoice_cycle_days IS NOT NULL)
    )::numeric, 2) AS median_cycle_days,

    ROUND((
        PERCENTILE_CONT(0.90)
        WITHIN GROUP (
            ORDER BY invoice_cycle_days::double precision
        )
        FILTER (WHERE invoice_cycle_days IS NOT NULL)
    )::numeric, 2) AS p90_cycle_days,

    COUNT(*) FILTER (
        WHERE invoice_cycle_days > 30
    ) AS cases_over_30_days,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE invoice_cycle_days > 30
        ) / NULLIF(COUNT(invoice_cycle_days), 0),
        2
    ) AS over_30_days_pct,

    ROUND((
        PERCENTILE_CONT(0.50)
        WITHIN GROUP (
            ORDER BY payment_block_to_clearing_days::double precision
        )
        FILTER (
            WHERE payment_block_to_clearing_days IS NOT NULL
        )
    )::numeric, 2) AS median_block_to_clearing_days

FROM procurement.mart_invoice_monitoring;


CREATE OR REPLACE VIEW procurement.vw_invoice_kpis_by_company AS

SELECT

    company,

    COUNT(*) AS invoice_cases,

    COUNT(*) FILTER (
        WHERE invoice_clearing_status = 'NO_RECORDED_CLEARING'
    ) AS cases_without_clearing,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE invoice_clearing_status = 'NO_RECORDED_CLEARING'
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS no_clearing_pct,

    COUNT(invoice_cycle_days) AS cleared_cases,

    ROUND((
        PERCENTILE_CONT(0.50)
        WITHIN GROUP (
            ORDER BY invoice_cycle_days::double precision
        )
        FILTER (WHERE invoice_cycle_days IS NOT NULL)
    )::numeric, 2) AS median_days,

    ROUND((
        PERCENTILE_CONT(0.90)
        WITHIN GROUP (
            ORDER BY invoice_cycle_days::double precision
        )
        FILTER (WHERE invoice_cycle_days IS NOT NULL)
    )::numeric, 2) AS p90_days,

    COUNT(*) FILTER (
        WHERE invoice_cycle_days > 30
    ) AS cases_over_30_days

FROM procurement.mart_invoice_monitoring

GROUP BY company;


CREATE OR REPLACE VIEW procurement.vw_activity_frequency AS

WITH activity_stats AS (

    SELECT
        activity,

        COUNT(*) AS event_count,

        COUNT(DISTINCT case_id) AS affected_cases

    FROM procurement.fact_procurement_event

    GROUP BY activity
)

SELECT

    activity,

    event_count,

    affected_cases,

    ROUND(
        100.0 * affected_cases /
        NULLIF(
            (SELECT COUNT(*) FROM procurement.dim_procurement_case),
            0
        ),
        2
    ) AS case_coverage_pct

FROM activity_stats;
SELECT *
FROM procurement.vw_invoice_kpis_overall;

SELECT *
FROM procurement.vw_invoice_kpis_by_company
ORDER BY median_days DESC;

SELECT *
FROM procurement.vw_activity_frequency
ORDER BY event_count DESC
LIMIT 15;

SELECT
    activity,
    COUNT(*) AS event_count,
    COUNT(DISTINCT case_id) AS affected_cases
FROM procurement.fact_procurement_event
WHERE activity ILIKE '%delete%'
GROUP BY activity
ORDER BY event_count DESC;

SELECT
    COUNT(DISTINCT case_id) AS cases_with_any_delete
FROM procurement.fact_procurement_event
WHERE activity ILIKE '%delete%';

SELECT *
FROM procurement.vw_invoice_kpis_overall;

SELECT *
FROM procurement.vw_invoice_kpis_by_company
ORDER BY median_days DESC;