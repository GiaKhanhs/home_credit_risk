WITH bureau_source AS (
    SELECT * 
    FROM {{ ref('stg_bureau') }}
)

    , bureau_balance_agg AS (
        SELECT *
        FROM {{ ref('int_bureau_balance_by_bureau') }}
    ) 

    , base AS (
        SELECT
            b.sk_id_curr,
            b.sk_id_bureau,
            b.credit_status,
            b.credit_currency,
            b.credit_type,

            b.days_credit_open,
            b.days_overdue_current,
            b.days_credit_end_expected,
            b.days_credit_end_actual,
            b.days_since_credit_update,

            b.credit_prolong_count,

            b.credit_amount_total,
            b.credit_debt_amount_current,
            b.credit_limit_amount_current,
            b.credit_overdue_amount_current,
            b.credit_overdue_amount_max,
            b.credit_annuity_amount,


            bb.bureau_balance_month_count,
            bb.bureau_balance_oldest_month,
            bb.bureau_balance_latest_month,
            bb.bureau_balance_dpd_month_count,
            bb.bureau_balance_max_dpd_severity,
            bb.flag_bureau_balance_has_dpd_history,
            bb.flag_bureau_balance_all_closed

        FROM bureau_source b
        LEFT JOIN bureau_balance_agg bb
             ON b.sk_id_bureau = bb.sk_id_bureau
    )

    , derived AS (
        SELECT
            *,

            -- credit_active flag
            CASE 
                WHEN credit_status = 'Active' 
                    THEN 1 
                    ELSE 0 
            END AS flag_active_credit,

            CASE 
                WHEN credit_status = 'Closed' 
                    THEN 1 
                    ELSE 0 
            END AS flag_closed_credit,

            CASE 
                WHEN credit_status = 'Sold' 
                    THEN 1 
                    ELSE 0 
            END AS flag_sold_credit,

            CASE 
                WHEN credit_status = 'Bad debt' 
                    THEN 1 
                    ELSE 0 
            END AS flag_bad_debt_credit,

            -- overdue / debt flags
            CASE
                WHEN COALESCE(days_overdue_current, 0) > 0 
                    THEN 1
                    ELSE 0
            END AS flag_has_credit_day_overdue,

            CASE
                WHEN COALESCE(credit_overdue_amount_current, 0) > 0 
                    THEN 1
                    ELSE 0
            END AS flag_has_amt_credit_overdue,

            CASE
                WHEN COALESCE(credit_debt_amount_current, 0) > 0 
                    THEN 1
                    ELSE 0
            END AS flag_has_credit_debt,

            CASE
                WHEN COALESCE(credit_overdue_amount_max, 0) > 0 
                    THEN 1
                    ELSE 0
            END AS flag_has_max_overdue_history,

            CASE
                WHEN COALESCE(credit_prolong_count, 0) > 0 
                    THEN 1
                    ELSE 0
            END AS flag_has_credit_prolong,

            CASE
                WHEN credit_annuity_amount IS NULL 
                    THEN 1
                    ELSE 0
            END AS flag_missing_amt_annuity,

            CASE
                WHEN days_credit_end_actual IS NULL 
                    THEN 1
                    ELSE 0
            END AS flag_missing_days_enddate_fact

        FROM base

    )

    , aggregated AS (
        SELECT
            sk_id_curr,

            COUNT(*) AS bureau_record_count,
            COUNT(DISTINCT sk_id_bureau) AS bureau_distinct_bureau_count,
            COUNT(DISTINCT credit_type) AS bureau_distinct_credit_type_count,

            SUM(flag_active_credit) AS bureau_active_credit_count,
            SUM(flag_closed_credit) AS bureau_closed_credit_count,
            SUM(flag_sold_credit) AS bureau_sold_credit_count,
            SUM(flag_bad_debt_credit) AS bureau_bad_debt_credit_count,

            SUM(flag_has_credit_day_overdue) AS bureau_overdue_day_record_count,
            SUM(flag_has_amt_credit_overdue) AS bureau_overdue_amount_record_count,
            SUM(flag_has_credit_debt) AS bureau_debt_record_count,
            SUM(flag_has_max_overdue_history) AS bureau_max_overdue_record_count,
            SUM(flag_has_credit_prolong) AS bureau_credit_prolong_record_count,

            SUM(COALESCE(credit_prolong_count, 0)) AS bureau_total_credit_prolong_count,

            AVG(days_credit_open) AS bureau_avg_days_credit,
            MIN(days_credit_open) AS bureau_min_days_credit,
            MAX(days_credit_open) AS bureau_max_days_credit,

            AVG(days_overdue_current) AS bureau_avg_credit_day_overdue,
            MAX(days_overdue_current) AS bureau_max_credit_day_overdue,

            AVG(days_credit_end_expected) AS bureau_avg_days_credit_enddate,
            AVG(days_credit_end_actual) AS bureau_avg_days_enddate_fact,
            AVG(days_since_credit_update) AS bureau_avg_days_credit_update,

            SUM(COALESCE(credit_amount_total, 0)) AS bureau_total_credit_sum,
            SUM(COALESCE(credit_debt_amount_current, 0)) AS bureau_total_credit_sum_debt,
            SUM(COALESCE(credit_limit_amount_current, 0)) AS bureau_total_credit_sum_limit,
            SUM(COALESCE(credit_overdue_amount_current, 0)) AS bureau_total_credit_sum_overdue,

            AVG(credit_amount_total) AS bureau_avg_credit_sum,
            AVG(credit_debt_amount_current) AS bureau_avg_credit_sum_debt,
            AVG(credit_limit_amount_current) AS bureau_avg_credit_sum_limit,
            AVG(credit_overdue_amount_current) AS bureau_avg_credit_sum_overdue,

            MAX(credit_overdue_amount_max) AS bureau_max_credit_max_overdue,
            AVG(credit_overdue_amount_max) AS bureau_avg_credit_max_overdue,

            AVG(credit_annuity_amount) AS bureau_avg_amt_annuity,
            MAX(credit_annuity_amount) AS bureau_max_amt_annuity,

            SUM(flag_missing_amt_annuity) AS bureau_missing_amt_annuity_count,
            SUM(flag_missing_days_enddate_fact) AS bureau_missing_days_enddate_fact_count,

            -- features from bureau_balance
            SUM(COALESCE(bureau_balance_month_count, 0)) AS bureau_balance_total_month_count,
            SUM(COALESCE(bureau_balance_dpd_month_count, 0)) AS bureau_balance_total_dpd_month_count,
            MAX(bureau_balance_max_dpd_severity) AS bureau_balance_max_dpd_severity,
            SUM(COALESCE(flag_bureau_balance_has_dpd_history, 0)) AS bureau_balance_dpd_history_bureau_count,
            SUM(COALESCE(flag_bureau_balance_all_closed, 0)) AS bureau_balance_all_closed_bureau_count

        FROM derived
        GROUP BY sk_id_curr

    )

    , final AS (
        SELECT *
        FROM aggregated

    )

SELECT *
FROM final