WITH stg_pos_cash_balance__source AS (
    SELECT *
    FROM {{ source("raw","pos_cash_balance") }}
)
    , stg_pos_cash_balance__redefined AS (
        SELECT
            CAST(sk_id_prev AS BIGINT)              AS sk_id_prev,
            CAST(sk_id_curr AS BIGINT)              AS sk_id_curr,
            CAST(months_balance AS INTEGER)         AS months_balance,
            CAST(cnt_instalment AS NUMERIC)         AS cnt_instalment,
            CAST(cnt_instalment_future AS NUMERIC)  AS cnt_instalment_future,
            CAST(name_contract_status AS TEXT)      AS name_contract_status,
            CAST(sk_dpd AS INTEGER)                 AS sk_dpd,
            CAST(sk_dpd_def AS INTEGER)             AS sk_dpd_def
        FROM stg_pos_cash_balance__source
    )

SELECT *
FROM stg_pos_cash_balance__redefined