WITH pos_cash_balance__source AS (
    SELECT *
    FROM {{ ref('stg_pos_cash_balance') }}
)
    , previous_application__source AS (
        SELECT DISTINCT
            sk_id_prev
        FROM {{ ref('stg_previous_application') }}
    )

    , valid_pos_cash_balance AS (
        SELECT
            pcb.*
        FROM pos_cash_balance__source pcb
        INNER JOIN previous_application__source pa
            ON pcb.sk_id_prev = pa.sk_id_prev
    )

    , base AS (
        SELECT
            sk_id_curr,
            sk_id_prev,
            months_balance,
            cnt_instalment,
            cnt_instalment_future,
            name_contract_status,
            sk_dpd,
            sk_dpd_def
        FROM valid_pos_cash_balance
    )
    , derived AS (
        SELECT
            sk_id_curr,
            sk_id_prev,
            months_balance,
            cnt_instalment,
            cnt_instalment_future,
            name_contract_status,
            sk_dpd,
            sk_dpd_def,

            CASE
                WHEN sk_dpd > 0 
                    THEN 1
                    ELSE 0
            END AS flag_has_dpd,

            CASE
                WHEN sk_dpd_def > 0 
                    THEN 1
                    ELSE 0
            END AS flag_has_dpd_def,

            CASE
                WHEN name_contract_status = 'Active' 
                    THEN 1
                    ELSE 0
            END AS flag_status_active,

            CASE
                WHEN name_contract_status = 'Completed' 
                    THEN 1
                    ELSE 0
            END AS flag_status_completed,

            CASE
                WHEN name_contract_status = 'Signed' 
                    THEN 1
                    ELSE 0
            END AS flag_status_signed,

            CASE
                WHEN name_contract_status = 'Approved' 
                    THEN 1
                    ELSE 0
            END AS flag_status_approved,

            CASE
                WHEN name_contract_status = 'Returned to the store' 
                    THEN 1
                    ELSE 0
            END AS flag_status_returned_to_store,

            CASE
                WHEN name_contract_status = 'Demand' 
                    THEN 1
                    ELSE 0
            END AS flag_status_demand,

            CASE
                WHEN name_contract_status = 'Amortized debt' 
                    THEN 1
                    ELSE 0
            END AS flag_status_amortized_debt,

            CASE
                WHEN name_contract_status = 'XNA' 
                    THEN 1
                    ELSE 0
            END AS flag_status_xna,

            CASE
                WHEN name_contract_status = 'Canceled' 
                    THEN 1
                    ELSE 0
            END AS flag_status_canceled

        FROM base
    )

    , aggregate AS (
        SELECT
            sk_id_prev,

            COUNT(*) AS pos_cash_month_count,

            MIN(months_balance) AS pos_cash_oldest_month,
            MAX(months_balance) AS pos_cash_latest_month,

            AVG(cnt_instalment) AS pos_cash_avg_cnt_instalment,
            MAX(cnt_instalment) AS pos_cash_max_cnt_instalment,
            MIN(cnt_instalment) AS pos_cash_min_cnt_instalment,

            AVG(cnt_instalment_future) AS pos_cash_avg_cnt_instalment_future,
            MAX(cnt_instalment_future) AS pos_cash_max_cnt_instalment_future,
            MIN(cnt_instalment_future) AS pos_cash_min_cnt_instalment_future,

            AVG(sk_dpd) AS pos_cash_avg_dpd,
            MAX(sk_dpd) AS pos_cash_max_dpd,

            AVG(sk_dpd_def) AS pos_cash_avg_dpd_def,
            MAX(sk_dpd_def) AS pos_cash_max_dpd_def,

            SUM(flag_has_dpd) AS pos_cash_dpd_month_count,
            SUM(flag_has_dpd_def) AS pos_cash_dpd_def_month_count,

            CASE
                WHEN SUM(flag_has_dpd) > 0 
                    THEN 1
                    ELSE 0
            END AS flag_pos_cash_has_dpd_history,

            CASE
                WHEN SUM(flag_has_dpd_def) > 0 
                    THEN 1
                    ELSE 0
            END AS flag_pos_cash_has_dpd_def_history,

            SUM(flag_status_active) AS pos_cash_status_active_count,
            SUM(flag_status_completed) AS pos_cash_status_completed_count,
            SUM(flag_status_signed) AS pos_cash_status_signed_count,
            SUM(flag_status_approved) AS pos_cash_status_approved_count,
            SUM(flag_status_returned_to_store) AS pos_cash_status_returned_to_store_count,
            SUM(flag_status_demand) AS pos_cash_status_demand_count,
            SUM(flag_status_amortized_debt) AS pos_cash_status_amortized_debt_count,
            SUM(flag_status_xna) AS pos_cash_status_xna_count,
            SUM(flag_status_canceled) AS pos_cash_status_canceled_count,

            CASE
                WHEN SUM(flag_status_active) > 0 
                    THEN 1
                    ELSE 0
            END AS flag_pos_cash_ever_active,

            CASE
                WHEN SUM(flag_status_completed) > 0 
                    THEN 1
                    ELSE 0
            END AS flag_pos_cash_ever_completed,

            CASE
                WHEN SUM(flag_status_demand) > 0 
                    THEN 1
                    ELSE 0
            END AS flag_pos_cash_ever_demand

        FROM derived
        GROUP BY sk_id_prev
    )

    , final AS (
        SELECT *
        FROM aggregate
    )

SELECT *
FROM final