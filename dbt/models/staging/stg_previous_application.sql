WITH stg_previous_application__source AS (
    SELECT *
    FROM {{ source("raw", "previous_application") }}
)
    , stg_previous_application__redefined AS (
        SELECT
            -- =========================
            -- Primary / foreign keys
            -- =========================
            CAST(sk_id_prev AS BIGINT)                             AS sk_id_prev,
            CAST(sk_id_curr AS BIGINT)                             AS sk_id_curr,

            -- =========================
            -- Contract / application type
            -- =========================
            CAST(name_contract_type AS TEXT)                       AS contract_type,
            CAST(flag_last_appl_per_contract AS TEXT)              AS last_application_per_contract_flag,
            CAST(nflag_last_appl_in_day AS SMALLINT)               AS last_application_in_day_flag,

            -- =========================
            -- Financial amounts
            -- =========================
            CAST(amt_annuity AS NUMERIC(18,2))                     AS annuity_amt,
            CAST(amt_application AS NUMERIC(18,2))                 AS application_amt,
            CAST(amt_credit AS NUMERIC(18,2))                      AS approved_credit_amt,
            CAST(amt_down_payment AS NUMERIC(18,2))                AS down_payment_amt,
            CAST(amt_goods_price AS NUMERIC(18,2))                 AS goods_price_amt,

            -- =========================
            -- Application timing
            -- =========================
            CAST(weekday_appr_process_start AS TEXT)               AS application_weekday,
            CAST(hour_appr_process_start AS SMALLINT)              AS application_hour,
            CAST(days_decision AS INTEGER)                         AS days_decision,

            -- =========================
            -- Rate / interest
            -- =========================
            CAST(rate_down_payment AS NUMERIC(18,10))              AS down_payment_rate,
            CAST(rate_interest_primary AS NUMERIC(18,10))          AS primary_interest_rate,
            CAST(rate_interest_privileged AS NUMERIC(18,10))       AS privileged_interest_rate,

            -- =========================
            -- Loan purpose / status / payment
            -- =========================
            CAST(name_cash_loan_purpose AS TEXT)                   AS cash_loan_purpose,
            CAST(name_contract_status AS TEXT)                     AS contract_status,
            CAST(name_payment_type AS TEXT)                        AS payment_type,
            CAST(code_reject_reason AS TEXT)                       AS reject_reason_code,

            -- =========================
            -- Client / suite / product
            -- =========================
            CAST(name_type_suite AS TEXT)                          AS accompany_type,
            CAST(name_client_type AS TEXT)                         AS client_type,
            CAST(name_goods_category AS TEXT)                      AS goods_category,
            CAST(name_portfolio AS TEXT)                           AS portfolio_type,
            CAST(name_product_type AS TEXT)                        AS product_type,
            CAST(product_combination AS TEXT)                      AS product_combination,

            -- =========================
            -- Channel / seller
            -- =========================
            CAST(channel_type AS TEXT)                             AS channel_type,
            CAST(sellerplace_area AS INTEGER)                      AS sellerplace_area,
            CAST(name_seller_industry AS TEXT)                     AS seller_industry,

            -- =========================
            -- Payment / yield
            -- =========================
            CAST(cnt_payment AS NUMERIC(10,2))                     AS installment_count,
            CAST(name_yield_group AS TEXT)                         AS yield_group,

            -- =========================
            -- Relative schedule dates
            -- keep as integer for now
            -- =========================
            CAST(CAST(days_first_drawing AS NUMERIC) AS INTEGER)                         AS days_first_drawing,
            CAST(CAST(days_first_due AS NUMERIC) AS INTEGER)                             AS days_first_due,
            CAST(CAST(days_last_due_1st_version AS NUMERIC) AS INTEGER)                  AS days_last_due_first_version,
            CAST(CAST(days_last_due AS NUMERIC) AS INTEGER)                              AS days_last_due,
            CAST(CAST(days_termination AS NUMERIC) AS INTEGER)                           AS days_termination,

            -- =========================
            -- Insurance
            -- =========================
            CAST(CAST(nflag_insured_on_approval AS NUMERIC) AS SMALLINT)            AS insured_on_approval_flag

        FROM stg_previous_application__source
    )

SELECT *
FROM stg_previous_application__redefined
