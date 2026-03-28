WITH application_train__source AS (
    SELECT *
    FROM {{ ref('stg_application_train') }}
)

    , base AS (
        SELECT *
        FROM application_train__source
    )

    , derived AS (
        SELECT
            *,

            -- =========================
            -- Cleaned relative day fields
            -- =========================
            CASE
                WHEN days_employed = 365243 THEN NULL
                ELSE days_employed
            END AS days_employed_clean,

            -- =========================
            -- Age / tenure in years
            -- =========================
            ABS(days_birth) / 365.25 AS age_years,

            CASE
                WHEN days_employed = 365243 THEN NULL
                ELSE ABS(days_employed) / 365.25
            END AS employment_years,

            ABS(days_registration) / 365.25 AS registration_years,
            ABS(days_id_publish) / 365.25 AS id_publish_years,
            ABS(days_last_phone_change) / 365.25 AS last_phone_change_years,

            -- =========================
            -- Core financial ratios
            -- =========================
            CASE
                WHEN income_total_amt IS NOT NULL
                AND income_total_amt <> 0
                    THEN credit_amt / income_total_amt
                    ELSE NULL
            END AS credit_to_income_ratio,

            CASE
                WHEN income_total_amt IS NOT NULL
                AND income_total_amt <> 0
                    THEN annuity_amt / income_total_amt
                    ELSE NULL
            END AS annuity_to_income_ratio,

            CASE
                WHEN credit_amt IS NOT NULL
                AND credit_amt <> 0
                    THEN annuity_amt / credit_amt
                    ELSE NULL
            END AS annuity_to_credit_ratio,

            CASE
                WHEN goods_price_amt IS NOT NULL
                AND goods_price_amt <> 0
                    THEN credit_amt / goods_price_amt
                    ELSE NULL
            END AS credit_to_goods_ratio,

            CASE
                WHEN income_total_amt IS NOT NULL
                AND income_total_amt <> 0
                    THEN goods_price_amt / income_total_amt
                    ELSE NULL
            END AS goods_to_income_ratio,

            CASE
                WHEN family_member_count IS NOT NULL
                AND family_member_count <> 0
                    THEN income_total_amt / family_member_count
                    ELSE NULL
            END AS income_per_family_member,

            CASE
                WHEN children_count IS NOT NULL
                    THEN income_total_amt / (children_count + 1)
                    ELSE NULL
            END AS income_per_child_adjusted,

            -- =========================
            -- Family structure
            -- =========================
            CASE
                WHEN family_member_count IS NOT NULL
                    THEN family_member_count - children_count
                    ELSE NULL
            END AS non_children_family_member_count,

            CASE
                WHEN children_count > 0 
                    THEN 1
                    ELSE 0
            END AS flag_has_children,

            -- =========================
            -- Asset / ownership flags
            -- =========================
            CASE
                WHEN owns_car_flag = 'Y' 
                    THEN 1
                    ELSE 0
            END AS flag_owns_car,

            CASE
                WHEN owns_realty_flag = 'Y' 
                    THEN 1
                    ELSE 0
            END AS flag_owns_realty,

            CASE
                WHEN own_car_age IS NOT NULL 
                    THEN 1
                    ELSE 0
            END AS flag_has_car_age,

            -- =========================
            -- Contact availability
            -- =========================
            COALESCE(flag_mobile, 0)
            + COALESCE(flag_emp_phone, 0)
            + COALESCE(flag_work_phone, 0)
            + COALESCE(flag_cont_mobile, 0)
            + COALESCE(flag_phone, 0)
            + COALESCE(flag_email, 0) AS contact_info_flag_count,

            -- =========================
            -- Address mismatch burden
            -- =========================
            COALESCE(reg_region_not_live_region, 0)
            + COALESCE(reg_region_not_work_region, 0)
            + COALESCE(live_region_not_work_region, 0)
            + COALESCE(reg_city_not_live_city, 0)
            + COALESCE(reg_city_not_work_city, 0)
            + COALESCE(live_city_not_work_city, 0) AS address_mismatch_flag_count,

            CASE
                WHEN
                    COALESCE(reg_region_not_live_region, 0)
                    + COALESCE(reg_region_not_work_region, 0)
                    + COALESCE(live_region_not_work_region, 0)
                    + COALESCE(reg_city_not_live_city, 0)
                    + COALESCE(reg_city_not_work_city, 0)
                    + COALESCE(live_city_not_work_city, 0) > 0
                    THEN 1
                    ELSE 0
            END AS flag_has_address_mismatch,

            -- =========================
            -- External score summary
            -- =========================
            (
                COALESCE(ext_source_1, 0)
                + COALESCE(ext_source_2, 0)
                + COALESCE(ext_source_3, 0)
            )
            /
            NULLIF(
                (CASE WHEN ext_source_1 IS NOT NULL THEN 1 ELSE 0 END)
                + (CASE WHEN ext_source_2 IS NOT NULL THEN 1 ELSE 0 END)
                + (CASE WHEN ext_source_3 IS NOT NULL THEN 1 ELSE 0 END),
                0
            ) AS ext_source_mean,

            GREATEST(
                COALESCE(ext_source_1, -1),
                COALESCE(ext_source_2, -1),
                COALESCE(ext_source_3, -1)
            ) AS ext_source_max,

            LEAST(
                COALESCE(ext_source_1, 999),
                COALESCE(ext_source_2, 999),
                COALESCE(ext_source_3, 999)
            ) AS ext_source_min,

            -- =========================
            -- Social circle summary
            -- =========================
            COALESCE(obs_30_cnt_social_circle, 0)
            + COALESCE(def_30_cnt_social_circle, 0)
            + COALESCE(obs_60_cnt_social_circle, 0)
            + COALESCE(def_60_cnt_social_circle, 0) AS social_circle_total_count,

            COALESCE(def_30_cnt_social_circle, 0)
            + COALESCE(def_60_cnt_social_circle, 0) AS social_circle_default_count,

            -- =========================
            -- Document summary
            -- =========================
            COALESCE(flag_document_2, 0)
            + COALESCE(flag_document_3, 0)
            + COALESCE(flag_document_4, 0)
            + COALESCE(flag_document_5, 0)
            + COALESCE(flag_document_6, 0)
            + COALESCE(flag_document_7, 0)
            + COALESCE(flag_document_8, 0)
            + COALESCE(flag_document_9, 0)
            + COALESCE(flag_document_10, 0)
            + COALESCE(flag_document_11, 0)
            + COALESCE(flag_document_12, 0)
            + COALESCE(flag_document_13, 0)
            + COALESCE(flag_document_14, 0)
            + COALESCE(flag_document_15, 0)
            + COALESCE(flag_document_16, 0)
            + COALESCE(flag_document_17, 0)
            + COALESCE(flag_document_18, 0)
            + COALESCE(flag_document_19, 0)
            + COALESCE(flag_document_20, 0)
            + COALESCE(flag_document_21, 0) AS document_flag_count,

            -- =========================
            -- Bureau request summary
            -- =========================
            COALESCE(req_credit_bureau_hour_cnt, 0)
            + COALESCE(req_credit_bureau_day_cnt, 0)
            + COALESCE(req_credit_bureau_week_cnt, 0)
            + COALESCE(req_credit_bureau_month_cnt, 0)
            + COALESCE(req_credit_bureau_quarter_cnt, 0)
            + COALESCE(req_credit_bureau_year_cnt, 0) AS total_credit_bureau_request_count,

            -- =========================
            -- Simple business flags
            -- =========================
            CASE
                WHEN contract_type = 'Cash loans' 
                    THEN 1
                    ELSE 0
            END AS flag_contract_type_cash,

            CASE
                WHEN contract_type = 'Revolving loans' 
                    THEN 1
                    ELSE 0
            END AS flag_contract_type_revolving,

            CASE
                WHEN gender_code = 'M' 
                    THEN 1
                    ELSE 0
            END AS flag_gender_male,

            CASE
                WHEN education_type = 'Higher education' 
                    THEN 1
                    ELSE 0
            END AS flag_higher_education,

            CASE
                WHEN income_type = 'Working' 
                    THEN 1
                    ELSE 0
            END AS flag_income_working,

            CASE
                WHEN income_type = 'Pensioner' 
                    THEN 1
                    ELSE 0
            END AS flag_income_pensioner

        FROM base
    )

    , final AS (
        SELECT *
        FROM derived
    )

SELECT *
FROM final