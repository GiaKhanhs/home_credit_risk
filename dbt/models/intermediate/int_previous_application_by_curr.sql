WITH previous_application__source AS (
    SELECT *
    FROM {{ ref('stg_previous_application') }}
),

installments_by_prev AS (
    SELECT *
    FROM {{ ref('int_installments_payments_by_prev') }}
),

pos_cash_by_prev AS (
    SELECT *
    FROM {{ ref('int_pos_cash_balance_by_prev') }}
),

credit_card_by_prev AS (
    SELECT *
    FROM {{ ref('int_credit_card_balance_by_prev') }}
),

base AS (
    SELECT
        sk_id_prev,
        sk_id_curr,

        contract_type,
        last_application_per_contract_flag,
        last_application_in_day_flag,

        annuity_amt,
        application_amt,
        approved_credit_amt,
        down_payment_amt,
        goods_price_amt,

        application_weekday,
        application_hour,
        days_decision,

        down_payment_rate,
        primary_interest_rate,
        privileged_interest_rate,

        cash_loan_purpose,
        contract_status,
        payment_type,
        reject_reason_code,

        accompany_type,
        client_type,
        goods_category,
        portfolio_type,
        product_type,
        product_combination,

        channel_type,
        sellerplace_area,
        seller_industry,

        installment_count,
        yield_group,

        days_first_drawing,
        days_first_due,
        days_last_due_first_version,
        days_last_due,
        days_termination,

        insured_on_approval_flag

    FROM previous_application__source
),

derived AS (
    SELECT
        sk_id_prev,
        sk_id_curr,

        contract_type,
        contract_status,
        portfolio_type,

        annuity_amt,
        application_amt,
        approved_credit_amt,
        down_payment_amt,
        goods_price_amt,
        installment_count,
        days_decision,

        CASE
            WHEN contract_status = 'Approved' THEN 1
            ELSE 0
        END AS flag_status_approved,

        CASE
            WHEN contract_status = 'Refused' THEN 1
            ELSE 0
        END AS flag_status_refused,

        CASE
            WHEN contract_status = 'Canceled' THEN 1
            ELSE 0
        END AS flag_status_canceled,

        CASE
            WHEN contract_status = 'Unused offer' THEN 1
            ELSE 0
        END AS flag_status_unused_offer,

        CASE
            WHEN contract_type = 'Consumer loans' THEN 1
            ELSE 0
        END AS flag_contract_type_consumer,

        CASE
            WHEN contract_type = 'Cash loans' THEN 1
            ELSE 0
        END AS flag_contract_type_cash,

        CASE
            WHEN contract_type = 'Revolving loans' THEN 1
            ELSE 0
        END AS flag_contract_type_revolving,

        CASE
            WHEN portfolio_type = 'POS' THEN 1
            ELSE 0
        END AS flag_portfolio_pos,

        CASE
            WHEN portfolio_type = 'Cash' THEN 1
            ELSE 0
        END AS flag_portfolio_cash,

        CASE
            WHEN portfolio_type = 'Cards' THEN 1
            ELSE 0
        END AS flag_portfolio_cards,

        CASE
            WHEN approved_credit_amt IS NOT NULL
             AND application_amt IS NOT NULL
             AND application_amt <> 0
                THEN approved_credit_amt / application_amt
            ELSE NULL
        END AS approved_to_application_ratio,

        CASE
            WHEN goods_price_amt IS NOT NULL
             AND goods_price_amt <> 0
             AND approved_credit_amt IS NOT NULL
                THEN approved_credit_amt / goods_price_amt
            ELSE NULL
        END AS credit_to_goods_ratio,

        CASE
            WHEN down_payment_amt IS NOT NULL
             AND goods_price_amt IS NOT NULL
             AND goods_price_amt <> 0
                THEN down_payment_amt / goods_price_amt
            ELSE NULL
        END AS down_payment_to_goods_ratio,

        CASE
            WHEN days_first_due IS NOT NULL
             AND days_first_drawing IS NOT NULL
                THEN days_first_due - days_first_drawing
            ELSE NULL
        END AS first_due_after_drawing_days,

        CASE
            WHEN days_last_due IS NOT NULL
             AND days_first_due IS NOT NULL
                THEN days_last_due - days_first_due
            ELSE NULL
        END AS loan_term_days,

        CASE
            WHEN last_application_per_contract_flag = 'Y' THEN 1
            ELSE 0
        END AS flag_last_application_per_contract,

        CASE
            WHEN last_application_in_day_flag = 1 THEN 1
            ELSE 0
        END AS flag_last_application_in_day,

        CASE
            WHEN insured_on_approval_flag = 1 THEN 1
            ELSE 0
        END AS flag_insured_on_approval

    FROM base
),

joined_by_prev AS (
    SELECT
        pa.sk_id_prev,
        pa.sk_id_curr,

        pa.application_amt,
        pa.approved_credit_amt,
        pa.annuity_amt,
        pa.down_payment_amt,
        pa.goods_price_amt,
        pa.installment_count,
        pa.days_decision,

        pa.flag_status_approved,
        pa.flag_status_refused,
        pa.flag_status_canceled,
        pa.flag_status_unused_offer,

        pa.flag_contract_type_consumer,
        pa.flag_contract_type_cash,
        pa.flag_contract_type_revolving,

        pa.flag_portfolio_pos,
        pa.flag_portfolio_cash,
        pa.flag_portfolio_cards,

        pa.approved_to_application_ratio,
        pa.credit_to_goods_ratio,
        pa.down_payment_to_goods_ratio,
        pa.first_due_after_drawing_days,
        pa.loan_term_days,

        pa.flag_last_application_per_contract,
        pa.flag_last_application_in_day,
        pa.flag_insured_on_approval,

        ins.installment_count                           AS prev_installment_record_count,
        ins.avg_payment_delay_days                      AS prev_avg_payment_delay_days,
        ins.max_payment_delay_days                      AS prev_max_payment_delay_days,
        ins.late_payment_count                          AS prev_late_payment_count,
        ins.flag_has_late_payment                       AS flag_prev_has_late_payment,
        ins.total_amt_instalment                        AS prev_total_amt_instalment,
        ins.total_amt_payment                           AS prev_total_amt_payment,
        ins.avg_payment_amount_ratio                    AS prev_avg_payment_amount_ratio,

        pos.pos_cash_month_count                        AS prev_pos_cash_month_count,
        pos.pos_cash_avg_dpd                            AS prev_pos_cash_avg_dpd,
        pos.pos_cash_max_dpd                            AS prev_pos_cash_max_dpd,
        pos.pos_cash_avg_dpd_def                        AS prev_pos_cash_avg_dpd_def,
        pos.pos_cash_max_dpd_def                        AS prev_pos_cash_max_dpd_def,
        pos.pos_cash_dpd_month_count                    AS prev_pos_cash_dpd_month_count,
        pos.pos_cash_dpd_def_month_count                AS prev_pos_cash_dpd_def_month_count,
        pos.flag_pos_cash_has_dpd_history               AS flag_prev_pos_cash_has_dpd_history,
        pos.flag_pos_cash_has_dpd_def_history           AS flag_prev_pos_cash_has_dpd_def_history,

        cc.cc_month_count                               AS prev_cc_month_count,
        cc.cc_avg_balance                               AS prev_cc_avg_balance,
        cc.cc_max_balance                               AS prev_cc_max_balance,
        cc.cc_avg_limit                                 AS prev_cc_avg_limit,
        cc.cc_avg_utilization                           AS prev_cc_avg_utilization,
        cc.cc_max_utilization                           AS prev_cc_max_utilization,
        cc.cc_avg_payment_ratio                         AS prev_cc_avg_payment_ratio,
        cc.cc_min_payment_ratio                         AS prev_cc_min_payment_ratio,
        cc.cc_avg_dpd                                   AS prev_cc_avg_dpd,
        cc.cc_max_dpd                                   AS prev_cc_max_dpd,
        cc.cc_avg_dpd_def                               AS prev_cc_avg_dpd_def,
        cc.cc_max_dpd_def                               AS prev_cc_max_dpd_def,
        cc.cc_dpd_month_count                           AS prev_cc_dpd_month_count,
        cc.cc_dpd_def_month_count                       AS prev_cc_dpd_def_month_count,
        cc.flag_cc_has_dpd_history                      AS flag_prev_cc_has_dpd_history,
        cc.flag_cc_has_dpd_def_history                  AS flag_prev_cc_has_dpd_def_history,
        cc.flag_cc_ever_demand                          AS flag_prev_cc_ever_demand

    FROM derived pa
    LEFT JOIN installments_by_prev ins
        ON pa.sk_id_prev = ins.sk_id_prev
    LEFT JOIN pos_cash_by_prev pos
        ON pa.sk_id_prev = pos.sk_id_prev
    LEFT JOIN credit_card_by_prev cc
        ON pa.sk_id_prev = cc.sk_id_prev
),

aggregate AS (
    SELECT
        sk_id_curr,

        COUNT(*) AS previous_application_count,

        SUM(flag_status_approved) AS previous_approved_count,
        SUM(flag_status_refused) AS previous_refused_count,
        SUM(flag_status_canceled) AS previous_canceled_count,
        SUM(flag_status_unused_offer) AS previous_unused_offer_count,

        AVG(flag_status_approved) AS previous_approved_ratio,
        AVG(flag_status_refused) AS previous_refused_ratio,

        SUM(flag_contract_type_consumer) AS previous_consumer_loan_count,
        SUM(flag_contract_type_cash) AS previous_cash_loan_count,
        SUM(flag_contract_type_revolving) AS previous_revolving_loan_count,

        SUM(flag_portfolio_pos) AS previous_portfolio_pos_count,
        SUM(flag_portfolio_cash) AS previous_portfolio_cash_count,
        SUM(flag_portfolio_cards) AS previous_portfolio_cards_count,

        AVG(application_amt) AS previous_avg_application_amt,
        MAX(application_amt) AS previous_max_application_amt,

        AVG(approved_credit_amt) AS previous_avg_approved_credit_amt,
        MAX(approved_credit_amt) AS previous_max_approved_credit_amt,

        AVG(annuity_amt) AS previous_avg_annuity_amt,
        MAX(annuity_amt) AS previous_max_annuity_amt,

        AVG(down_payment_amt) AS previous_avg_down_payment_amt,
        MAX(down_payment_amt) AS previous_max_down_payment_amt,

        AVG(goods_price_amt) AS previous_avg_goods_price_amt,
        MAX(goods_price_amt) AS previous_max_goods_price_amt,

        AVG(approved_to_application_ratio) AS previous_avg_approved_to_application_ratio,
        AVG(credit_to_goods_ratio) AS previous_avg_credit_to_goods_ratio,
        AVG(down_payment_to_goods_ratio) AS previous_avg_down_payment_to_goods_ratio,

        AVG(installment_count) AS previous_avg_installment_count,
        MAX(installment_count) AS previous_max_installment_count,

        MIN(days_decision) AS previous_oldest_decision_day,
        MAX(days_decision) AS previous_latest_decision_day,

        AVG(first_due_after_drawing_days) AS previous_avg_first_due_after_drawing_days,
        AVG(loan_term_days) AS previous_avg_loan_term_days,
        MAX(loan_term_days) AS previous_max_loan_term_days,

        SUM(flag_last_application_per_contract) AS previous_last_application_per_contract_count,
        SUM(flag_last_application_in_day) AS previous_last_application_in_day_count,
        SUM(flag_insured_on_approval) AS previous_insured_on_approval_count,

        AVG(prev_avg_payment_delay_days) AS previous_avg_payment_delay_days_mean,
        MAX(prev_max_payment_delay_days) AS previous_max_payment_delay_days_max,
        SUM(COALESCE(prev_late_payment_count, 0)) AS previous_total_late_payment_count,
        SUM(COALESCE(flag_prev_has_late_payment, 0)) AS previous_loan_with_late_payment_count,
        AVG(prev_avg_payment_amount_ratio) AS previous_avg_payment_amount_ratio_mean,

        SUM(COALESCE(prev_pos_cash_month_count, 0)) AS previous_total_pos_cash_month_count,
        AVG(prev_pos_cash_avg_dpd) AS previous_pos_cash_avg_dpd_mean,
        MAX(prev_pos_cash_max_dpd) AS previous_pos_cash_max_dpd_max,
        AVG(prev_pos_cash_avg_dpd_def) AS previous_pos_cash_avg_dpd_def_mean,
        MAX(prev_pos_cash_max_dpd_def) AS previous_pos_cash_max_dpd_def_max,
        SUM(COALESCE(prev_pos_cash_dpd_month_count, 0)) AS previous_total_pos_cash_dpd_month_count,
        SUM(COALESCE(prev_pos_cash_dpd_def_month_count, 0)) AS previous_total_pos_cash_dpd_def_month_count,

        SUM(COALESCE(prev_cc_month_count, 0)) AS previous_total_cc_month_count,
        AVG(prev_cc_avg_balance) AS previous_cc_avg_balance_mean,
        MAX(prev_cc_max_balance) AS previous_cc_max_balance_max,
        AVG(prev_cc_avg_limit) AS previous_cc_avg_limit_mean,
        AVG(prev_cc_avg_utilization) AS previous_cc_avg_utilization_mean,
        MAX(prev_cc_max_utilization) AS previous_cc_max_utilization_max,
        AVG(prev_cc_avg_payment_ratio) AS previous_cc_avg_payment_ratio_mean,
        MIN(prev_cc_min_payment_ratio) AS previous_cc_min_payment_ratio_min,
        AVG(prev_cc_avg_dpd) AS previous_cc_avg_dpd_mean,
        MAX(prev_cc_max_dpd) AS previous_cc_max_dpd_max,
        AVG(prev_cc_avg_dpd_def) AS previous_cc_avg_dpd_def_mean,
        MAX(prev_cc_max_dpd_def) AS previous_cc_max_dpd_def_max,
        SUM(COALESCE(prev_cc_dpd_month_count, 0)) AS previous_total_cc_dpd_month_count,
        SUM(COALESCE(prev_cc_dpd_def_month_count, 0)) AS previous_total_cc_dpd_def_month_count,

        CASE
            WHEN SUM(flag_status_refused) > 0 THEN 1
            ELSE 0
        END AS flag_has_previous_refused_application,

        CASE
            WHEN SUM(flag_status_canceled) > 0 THEN 1
            ELSE 0
        END AS flag_has_previous_canceled_application,

        CASE
            WHEN SUM(flag_status_approved) > 0 THEN 1
            ELSE 0
        END AS flag_has_previous_approved_application,

        CASE
            WHEN SUM(COALESCE(flag_prev_has_late_payment, 0)) > 0 THEN 1
            ELSE 0
        END AS flag_has_previous_late_payment_history,

        CASE
            WHEN SUM(COALESCE(flag_prev_pos_cash_has_dpd_history, 0)) > 0 THEN 1
            ELSE 0
        END AS flag_has_previous_pos_cash_dpd_history,

        CASE
            WHEN SUM(COALESCE(flag_prev_pos_cash_has_dpd_def_history, 0)) > 0 THEN 1
            ELSE 0
        END AS flag_has_previous_pos_cash_dpd_def_history,

        CASE
            WHEN SUM(COALESCE(flag_prev_cc_has_dpd_history, 0)) > 0 THEN 1
            ELSE 0
        END AS flag_has_previous_cc_dpd_history,

        CASE
            WHEN SUM(COALESCE(flag_prev_cc_has_dpd_def_history, 0)) > 0 THEN 1
            ELSE 0
        END AS flag_has_previous_cc_dpd_def_history,

        CASE
            WHEN SUM(COALESCE(flag_prev_cc_ever_demand, 0)) > 0 THEN 1
            ELSE 0
        END AS flag_has_previous_cc_demand_history

    FROM joined_by_prev
    GROUP BY sk_id_curr
),

final AS (
    SELECT *
    FROM aggregate
)

SELECT *
FROM final