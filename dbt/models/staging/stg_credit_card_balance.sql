WITH stg_credit_card_balance__source AS (
    SELECT *
    FROM {{ source('raw', 'credit_card_balance') }}
),

stg_credit_card_balance__redefined AS (
    SELECT
        CAST(sk_id_prev AS BIGINT)                         AS sk_id_prev,
        CAST(sk_id_curr AS BIGINT)                         AS sk_id_curr,
        CAST(months_balance AS INTEGER)                    AS months_balance,
        CAST(amt_balance AS NUMERIC)                       AS amt_balance,
        CAST(amt_credit_limit_actual AS NUMERIC)           AS amt_credit_limit_actual,
        CAST(amt_drawings_atm_current AS NUMERIC)          AS amt_drawings_atm_current,
        CAST(amt_drawings_current AS NUMERIC)              AS amt_drawings_current,
        CAST(amt_drawings_other_current AS NUMERIC)        AS amt_drawings_other_current,
        CAST(amt_drawings_pos_current AS NUMERIC)          AS amt_drawings_pos_current,
        CAST(amt_inst_min_regularity AS NUMERIC)           AS amt_inst_min_regularity,
        CAST(amt_payment_current AS NUMERIC)               AS amt_payment_current,
        CAST(amt_payment_total_current AS NUMERIC)         AS amt_payment_total_current,
        CAST(amt_receivable_principal AS NUMERIC)          AS amt_receivable_principal,
        CAST(amt_recivable AS NUMERIC)                     AS amt_recivable,
        CAST(amt_total_receivable AS NUMERIC)              AS amt_total_receivable,
        CAST(cnt_drawings_atm_current AS INTEGER)          AS cnt_drawings_atm_current,
        CAST(cnt_drawings_current AS INTEGER)              AS cnt_drawings_current,
        CAST(cnt_drawings_other_current AS INTEGER)        AS cnt_drawings_other_current,
        CAST(cnt_drawings_pos_current AS INTEGER)          AS cnt_drawings_pos_current,
        CAST(cnt_instalment_mature_cum AS INTEGER)         AS cnt_instalment_mature_cum,
        CAST(name_contract_status AS TEXT)                 AS name_contract_status,
        CAST(sk_dpd AS INTEGER)                            AS sk_dpd,
        CAST(sk_dpd_def AS INTEGER)                        AS sk_dpd_def
    FROM stg_credit_card_balance__source
)

SELECT *
FROM stg_credit_card_balance__redefined