WITH source AS (
    SELECT * 
    FROM {{ ref('stg_bureau') }}
)

    , base as (
        SELECT
            b.sk_id_curr,
            b.sk_id_bureau,
            b.credit_active,
            b.credit_currency,
            b.days_credit,
            b.credit_day_overdue,
            b.days_credit_enddate,
            b.days_enddate_fact,
            b.amt_credit_max_overdue,
            b.cnt_credit_prolong,
            b.amt_credit_sum,
            b.amt_credit_sum_debt,
            b.amt_credit_sum_limit,
            b.amt_credit_sum_overdue,
            b.credit_type,
            b.days_credit_update,
            b.amt_annuity,

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
            CASE WHEN credit_active = 'Active' 
                THEN 1 
                ELSE 0 
            END AS flag_active_credit,

            CASE WHEN credit_active = 'Closed' 
                THEN 1 
                ELSE 0 
            END AS flag_closed_credit,

            CASE WHEN credit_active = 'Sold' 
                THEN 1 
                ELSE 0 
            END AS flag_sold_credit,

            CASE WHEN credit_active = 'Bad debt' 
                THEN 1 
                ELSE 0 
            END AS flag_bad_debt_credit,


    )

SELECT *
FROM source