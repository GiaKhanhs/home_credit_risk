WITH application AS (
    SELECT *
    FROM {{ ref('int_application_train') }}
),

bureau AS (
    SELECT *
    FROM {{ ref('int_bureau_by_curr') }}
),

previous AS (
    SELECT *
    FROM {{ ref('int_previous_application_by_curr') }}
),

final AS (
    SELECT
        app.*,

        -- =========================
        -- Bureau features
        -- =========================
        COALESCE(bureau.bureau_record_count, 0) AS bureau_record_count,
        COALESCE(bureau.bureau_distinct_bureau_count, 0) AS bureau_distinct_bureau_count,
        COALESCE(bureau.bureau_distinct_credit_type_count, 0) AS bureau_distinct_credit_type_count,

        COALESCE(bureau.bureau_active_credit_count, 0) AS bureau_active_credit_count,
        COALESCE(bureau.bureau_closed_credit_count, 0) AS bureau_closed_credit_count,
        COALESCE(bureau.bureau_sold_credit_count, 0) AS bureau_sold_credit_count,
        COALESCE(bureau.bureau_bad_debt_credit_count, 0) AS bureau_bad_debt_credit_count,

        COALESCE(bureau.bureau_overdue_day_record_count, 0) AS bureau_overdue_day_record_count,
        COALESCE(bureau.bureau_overdue_amount_record_count, 0) AS bureau_overdue_amount_record_count,
        COALESCE(bureau.bureau_debt_record_count, 0) AS bureau_debt_record_count,
        COALESCE(bureau.bureau_max_overdue_record_count, 0) AS bureau_max_overdue_record_count,
        COALESCE(bureau.bureau_credit_prolong_record_count, 0) AS bureau_credit_prolong_record_count,
        COALESCE(bureau.bureau_total_credit_prolong_count, 0) AS bureau_total_credit_prolong_count,

        bureau.bureau_avg_days_credit,
        bureau.bureau_min_days_credit,
        bureau.bureau_max_days_credit,
        bureau.bureau_avg_credit_day_overdue,
        bureau.bureau_max_credit_day_overdue,
        bureau.bureau_avg_days_credit_enddate,
        bureau.bureau_avg_days_enddate_fact,
        bureau.bureau_avg_days_credit_update,

        bureau.bureau_total_credit_sum,
        bureau.bureau_total_credit_sum_debt,
        bureau.bureau_total_credit_sum_limit,
        bureau.bureau_total_credit_sum_overdue,

        bureau.bureau_avg_credit_sum,
        bureau.bureau_avg_credit_sum_debt,
        bureau.bureau_avg_credit_sum_limit,
        bureau.bureau_avg_credit_sum_overdue,

        bureau.bureau_max_credit_max_overdue,
        bureau.bureau_avg_credit_max_overdue,
        bureau.bureau_avg_amt_annuity,
        bureau.bureau_max_amt_annuity,

        COALESCE(bureau.bureau_missing_amt_annuity_count, 0) AS bureau_missing_amt_annuity_count,
        COALESCE(bureau.bureau_missing_days_enddate_fact_count, 0) AS bureau_missing_days_enddate_fact_count,

        COALESCE(bureau.bureau_balance_total_month_count, 0) AS bureau_balance_total_month_count,
        COALESCE(bureau.bureau_balance_total_dpd_month_count, 0) AS bureau_balance_total_dpd_month_count,
        bureau.bureau_balance_max_dpd_severity,
        COALESCE(bureau.bureau_balance_dpd_history_bureau_count, 0) AS bureau_balance_dpd_history_bureau_count,
        COALESCE(bureau.bureau_balance_all_closed_bureau_count, 0) AS bureau_balance_all_closed_bureau_count,

        -- =========================
        -- Previous application features
        -- =========================
        COALESCE(previous.previous_application_count, 0) AS previous_application_count,
        COALESCE(previous.previous_approved_count, 0) AS previous_approved_count,
        COALESCE(previous.previous_refused_count, 0) AS previous_refused_count,
        COALESCE(previous.previous_canceled_count, 0) AS previous_canceled_count,
        COALESCE(previous.previous_unused_offer_count, 0) AS previous_unused_offer_count,

        previous.previous_approved_ratio,
        previous.previous_refused_ratio,

        COALESCE(previous.previous_consumer_loan_count, 0) AS previous_consumer_loan_count,
        COALESCE(previous.previous_cash_loan_count, 0) AS previous_cash_loan_count,
        COALESCE(previous.previous_revolving_loan_count, 0) AS previous_revolving_loan_count,

        COALESCE(previous.previous_portfolio_pos_count, 0) AS previous_portfolio_pos_count,
        COALESCE(previous.previous_portfolio_cash_count, 0) AS previous_portfolio_cash_count,
        COALESCE(previous.previous_portfolio_cards_count, 0) AS previous_portfolio_cards_count,

        previous.previous_avg_application_amt,
        previous.previous_max_application_amt,
        previous.previous_avg_approved_credit_amt,
        previous.previous_max_approved_credit_amt,
        previous.previous_avg_annuity_amt,
        previous.previous_max_annuity_amt,
        previous.previous_avg_down_payment_amt,
        previous.previous_max_down_payment_amt,
        previous.previous_avg_goods_price_amt,
        previous.previous_max_goods_price_amt,

        previous.previous_avg_approved_to_application_ratio,
        previous.previous_avg_credit_to_goods_ratio,
        previous.previous_avg_down_payment_to_goods_ratio,

        previous.previous_avg_installment_count,
        previous.previous_max_installment_count,
        previous.previous_oldest_decision_day,
        previous.previous_latest_decision_day,
        previous.previous_avg_first_due_after_drawing_days,
        previous.previous_avg_loan_term_days,
        previous.previous_max_loan_term_days,

        COALESCE(previous.previous_last_application_per_contract_count, 0) AS previous_last_application_per_contract_count,
        COALESCE(previous.previous_last_application_in_day_count, 0) AS previous_last_application_in_day_count,
        COALESCE(previous.previous_insured_on_approval_count, 0) AS previous_insured_on_approval_count,

        previous.previous_avg_payment_delay_days_mean,
        previous.previous_max_payment_delay_days_max,
        COALESCE(previous.previous_total_late_payment_count, 0) AS previous_total_late_payment_count,
        COALESCE(previous.previous_loan_with_late_payment_count, 0) AS previous_loan_with_late_payment_count,
        previous.previous_avg_payment_amount_ratio_mean,

        COALESCE(previous.previous_total_pos_cash_month_count, 0) AS previous_total_pos_cash_month_count,
        previous.previous_pos_cash_avg_dpd_mean,
        previous.previous_pos_cash_max_dpd_max,
        previous.previous_pos_cash_avg_dpd_def_mean,
        previous.previous_pos_cash_max_dpd_def_max,
        COALESCE(previous.previous_total_pos_cash_dpd_month_count, 0) AS previous_total_pos_cash_dpd_month_count,
        COALESCE(previous.previous_total_pos_cash_dpd_def_month_count, 0) AS previous_total_pos_cash_dpd_def_month_count,

        COALESCE(previous.previous_total_cc_month_count, 0) AS previous_total_cc_month_count,
        previous.previous_cc_avg_balance_mean,
        previous.previous_cc_max_balance_max,
        previous.previous_cc_avg_limit_mean,
        previous.previous_cc_avg_utilization_mean,
        previous.previous_cc_max_utilization_max,
        previous.previous_cc_avg_payment_ratio_mean,
        previous.previous_cc_min_payment_ratio_min,
        previous.previous_cc_avg_dpd_mean,
        previous.previous_cc_max_dpd_max,
        previous.previous_cc_avg_dpd_def_mean,
        previous.previous_cc_max_dpd_def_max,
        COALESCE(previous.previous_total_cc_dpd_month_count, 0) AS previous_total_cc_dpd_month_count,
        COALESCE(previous.previous_total_cc_dpd_def_month_count, 0) AS previous_total_cc_dpd_def_month_count,

        COALESCE(previous.flag_has_previous_refused_application, 0) AS flag_has_previous_refused_application,
        COALESCE(previous.flag_has_previous_canceled_application, 0) AS flag_has_previous_canceled_application,
        COALESCE(previous.flag_has_previous_approved_application, 0) AS flag_has_previous_approved_application,
        COALESCE(previous.flag_has_previous_late_payment_history, 0) AS flag_has_previous_late_payment_history,
        COALESCE(previous.flag_has_previous_pos_cash_dpd_history, 0) AS flag_has_previous_pos_cash_dpd_history,
        COALESCE(previous.flag_has_previous_pos_cash_dpd_def_history, 0) AS flag_has_previous_pos_cash_dpd_def_history,
        COALESCE(previous.flag_has_previous_cc_dpd_history, 0) AS flag_has_previous_cc_dpd_history,
        COALESCE(previous.flag_has_previous_cc_dpd_def_history, 0) AS flag_has_previous_cc_dpd_def_history,
        COALESCE(previous.flag_has_previous_cc_demand_history, 0) AS flag_has_previous_cc_demand_history

    FROM application app
    LEFT JOIN bureau
        ON app.sk_id_curr = bureau.sk_id_curr
    LEFT JOIN previous
        ON app.sk_id_curr = previous.sk_id_curr
)

SELECT *
FROM final