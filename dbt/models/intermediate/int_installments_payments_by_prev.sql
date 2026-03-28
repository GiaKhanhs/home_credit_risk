WITH  installments_payments__source AS (
    SELECT * 
    FROM {{ ref('stg_installments_payments') }}
)
    
    , previous_application__source AS (
        SELECT 
            DISTINCT sk_id_prev

        FROM {{ ref('stg_previous_application') }}
    )

    , valid_installments_payments AS (
        SELECT ips.*
        FROM installments_payments__source ips
        INNER JOIN previous_application__source pa
        ON ips.sk_id_prev = pa.sk_id_prev
    )

    , base AS (
        SELECT
            sk_id_curr,
            sk_id_prev,

            num_instalment_version,
            num_instalment_number,

            days_instalment,
            days_entry_payment,

            amt_instalment,
            amt_payment

        FROM valid_installments_payments
    )

    , derived AS (
        SELECT
            sk_id_prev,
            sk_id_curr,
            num_instalment_version,
            num_instalment_number,
            days_instalment,
            days_entry_payment,
            amt_instalment,
            amt_payment,

            days_entry_payment - days_instalment AS payment_delay_days,

            CASE
                WHEN days_entry_payment > days_instalment 
                    THEN 1
                    ELSE 0
            END AS flag_late_payment,

            CASE
                WHEN days_entry_payment < days_instalment 
                    THEN 1
                    ELSE 0
            END AS flag_early_payment,

            CASE
                WHEN days_entry_payment = days_instalment 
                    THEN 1
                    ELSE 0
            END AS flag_on_time_payment,

            amt_payment - amt_instalment AS payment_amount_diff,

            CASE
                WHEN amt_instalment <> 0 
                    THEN amt_payment / amt_instalment
                    ELSE NULL
            END AS payment_amount_ratio

        FROM valid_installments_payments
    )

    , aggregate AS (
        SELECT
            sk_id_prev,

            COUNT(*) AS installment_count,

            MIN(days_instalment)            AS installment_first_day,
            MAX(days_instalment)            AS installment_last_day,

            AVG(payment_delay_days)         AS avg_payment_delay_days,
            MAX(payment_delay_days)         AS max_payment_delay_days,
            MIN(payment_delay_days)         AS min_payment_delay_days,

            SUM(flag_late_payment)          AS late_payment_count,
            SUM(flag_early_payment)         AS early_payment_count,
            SUM(flag_on_time_payment)       AS on_time_payment_count,

            CASE
                WHEN SUM(flag_late_payment) > 0 
                    THEN 1
                    ELSE 0
            END AS flag_has_late_payment,

            SUM(amt_instalment)             AS total_amt_instalment,
            SUM(amt_payment)                AS total_amt_payment,

            AVG(payment_amount_diff)        AS avg_payment_amount_diff,
            MAX(payment_amount_diff)        AS max_payment_amount_diff,
            MIN(payment_amount_diff)        AS min_payment_amount_diff,

            AVG(payment_amount_ratio)       AS avg_payment_amount_ratio

        FROM derived
        GROUP BY sk_id_prev
    )

    , final AS (
        SELECT * 
        FROM aggregate
    )

SELECT *
FROM final