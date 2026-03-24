WITH stg_bureau__source AS (
    SELECT *
    FROM {{ source("raw", "bureau") }}
)
    , stg_bureau__redefined AS (
        SELECT
            -- =========================
            -- Primary / foreign keys
            -- =========================
            CAST(sk_id_curr AS BIGINT)                                  AS sk_id_curr,
            CAST(sk_id_bureau AS BIGINT)                                AS sk_id_bureau,

            -- =========================
            -- Credit status / descriptors
            -- =========================
            CAST(credit_active AS TEXT)                                 AS credit_status,
            CAST(credit_currency AS TEXT)                               AS credit_currency,
            CAST(credit_type AS TEXT)                                   AS credit_type,

            -- =========================
            -- Relative time columns (days)
            -- negative values indicate the past
            -- =========================
            CAST(days_credit AS INTEGER)                                AS days_credit_open,
            CAST(credit_day_overdue AS INTEGER)                         AS days_overdue_current,
            CAST(CAST(days_credit_enddate AS NUMERIC) AS INTEGER)       AS days_credit_end_expected,
            CAST(CAST(days_enddate_fact AS NUMERIC) AS INTEGER)         AS days_credit_end_actual,
            CAST(days_credit_update AS INTEGER)                         AS days_since_credit_update,

            -- =========================
            -- Credit history / prolongation
            -- =========================
            CAST(cnt_credit_prolong AS SMALLINT)                        AS credit_prolong_count,

            -- =========================
            -- Credit amounts
            -- =========================
            CAST(amt_credit_sum AS NUMERIC(18,2))                       AS credit_amount_total,
            CAST(amt_credit_sum_debt AS NUMERIC(18,2))                  AS credit_debt_amount_current,
            CAST(amt_credit_sum_limit AS NUMERIC(18,2))                 AS credit_limit_amount_current,
            CAST(amt_credit_sum_overdue AS NUMERIC(18,2))               AS credit_overdue_amount_current,
            CAST(amt_credit_max_overdue AS NUMERIC(18,2))               AS credit_overdue_amount_max,
            CAST(amt_annuity AS NUMERIC(18,2))                          AS credit_annuity_amount

        FROM stg_bureau__source
    )

SELECT * 
FROM stg_bureau__redefined