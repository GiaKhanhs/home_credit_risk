WITH stg_installments_payments__source AS (
    SELECT *
    FROM {{ source('raw', 'installments_payments') }}
)
    , stg_installments_payments__redefined AS (
        SELECT
            CAST(sk_id_prev AS BIGINT)                   AS sk_id_prev,
            CAST(sk_id_curr AS BIGINT)                   AS sk_id_curr,
            CAST(num_instalment_version AS INTEGER)      AS num_instalment_version,
            CAST(num_instalment_number AS INTEGER)       AS num_instalment_number,
            CAST(days_instalment AS INTEGER)             AS days_instalment,
            CAST(days_entry_payment AS INTEGER)          AS days_entry_payment,
            CAST(amt_instalment AS NUMERIC)              AS amt_instalment,
            CAST(amt_payment AS NUMERIC)                 AS amt_payment
        FROM stg_installments_payments__source
    )

SELECT *
FROM stg_installments_payments__redefined