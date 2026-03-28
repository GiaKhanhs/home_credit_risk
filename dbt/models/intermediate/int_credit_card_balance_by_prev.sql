WITH credit_card_balance__source AS (
    SELECT *
    FROM {{ ref('stg_credit_card_balance') }}
)

    , previous_application__source AS (
        SELECT DISTINCT sk_id_prev
        FROM {{ ref('stg_previous_application') }}
    )

    , valid_credit_card_balance AS (
        SELECT
            ccb.*
        FROM credit_card_balance__source ccb
        INNER JOIN previous_application__source pa
            ON ccb.sk_id_prev = pa.sk_id_prev
    )

    , base AS (
        SELECT
            sk_id_curr,
            sk_id_prev,
            months_balance,

            amt_balance,
            amt_credit_limit_actual,

            amt_drawings_current,
            amt_drawings_atm_current,
            amt_drawings_pos_current,
            amt_drawings_other_current,

            amt_payment_current,
            amt_payment_total_current,

            amt_total_receivable,

            cnt_drawings_current,

            name_contract_status,

            sk_dpd,
            sk_dpd_def

        FROM valid_credit_card_balance
    )

    , derived AS (
        SELECT
            *,

            -- utilization
            CASE
                WHEN amt_credit_limit_actual > 0
                    THEN amt_balance / amt_credit_limit_actual
                    ELSE NULL
            END AS credit_utilization_ratio,

            -- payment behavior
            CASE
                WHEN amt_total_receivable > 0
                    THEN amt_payment_total_current / amt_total_receivable
                    ELSE NULL
            END AS payment_ratio,

            -- drawing behavior
            COALESCE(amt_drawings_current, 0) AS amt_drawings_total,

            -- delinquency flags
            CASE WHEN sk_dpd > 0 
                THEN 1 
                ELSE 0 
            END AS flag_has_dpd,

            CASE WHEN sk_dpd_def > 0 
                THEN 1 
                ELSE 0 
            END AS flag_has_dpd_def,

            -- status flags
            CASE WHEN name_contract_status = 'Active' 
                THEN 1
                ELSE 0 
            END AS flag_status_active,

            CASE WHEN name_contract_status = 'Completed' 
                THEN 1 
                ELSE 0 
            END AS flag_status_completed,

            CASE WHEN name_contract_status = 'Demand' 
                THEN 1 
                ELSE 0 
            END AS flag_status_demand

        FROM base
    )

    , aggregate AS (
        SELECT
            sk_id_prev,

            -- time
            COUNT(*) AS cc_month_count,
            MIN(months_balance) AS cc_oldest_month,
            MAX(months_balance) AS cc_latest_month,

            -- balance
            AVG(amt_balance) AS cc_avg_balance,
            MAX(amt_balance) AS cc_max_balance,

            -- limit
            AVG(amt_credit_limit_actual) AS cc_avg_limit,

            -- utilization
            AVG(credit_utilization_ratio) AS cc_avg_utilization,
            MAX(credit_utilization_ratio) AS cc_max_utilization,

            -- payment
            AVG(payment_ratio) AS cc_avg_payment_ratio,
            MIN(payment_ratio) AS cc_min_payment_ratio,

            -- drawing
            AVG(amt_drawings_total) AS cc_avg_drawings,
            MAX(amt_drawings_total) AS cc_max_drawings,

            AVG(cnt_drawings_current) AS cc_avg_drawing_count,
            MAX(cnt_drawings_current) AS cc_max_drawing_count,

            -- delinquency
            AVG(sk_dpd) AS cc_avg_dpd,
            MAX(sk_dpd) AS cc_max_dpd,

            AVG(sk_dpd_def) AS cc_avg_dpd_def,
            MAX(sk_dpd_def) AS cc_max_dpd_def,

            SUM(flag_has_dpd) AS cc_dpd_month_count,
            SUM(flag_has_dpd_def) AS cc_dpd_def_month_count,

            CASE
                WHEN SUM(flag_has_dpd) > 0 
                    THEN 1
                    ELSE 0
            END AS flag_cc_has_dpd_history,

            CASE
                WHEN SUM(flag_has_dpd_def) > 0 
                    THEN 1
                    ELSE 0
            END AS flag_cc_has_dpd_def_history,

            -- status
            SUM(flag_status_active) AS cc_status_active_count,
            SUM(flag_status_completed) AS cc_status_completed_count,
            SUM(flag_status_demand) AS cc_status_demand_count,

            CASE
                WHEN SUM(flag_status_active) > 0 
                    THEN 1
                    ELSE 0
            END AS flag_cc_ever_active,

            CASE
                WHEN SUM(flag_status_demand) > 0 
                    THEN 1
                    ELSE 0
            END AS flag_cc_ever_demand

        FROM derived
        GROUP BY sk_id_prev
    ),

    final AS (
        SELECT *
        FROM aggregate
    )

SELECT *
FROM final