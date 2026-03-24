WITH stg_application_test__source AS (
    SELECT *
    FROM {{ source('raw','application_test') }}
)
    , stg_application_test__redefined AS (
        SELECT
            -- =========================
            -- Primary key / target
            -- =========================
            CAST(sk_id_curr AS INTEGER)                            AS sk_id_curr,

            -- =========================
            -- Contract / identity
            -- =========================
            CAST(name_contract_type AS TEXT)                       AS contract_type,
            CAST(code_gender AS TEXT)                              AS gender_code,
            CAST(flag_own_car AS TEXT)                             AS owns_car_flag,
            CAST(flag_own_realty AS TEXT)                          AS owns_realty_flag,

            -- =========================
            -- Household / family
            -- =========================
            CAST(cnt_children AS SMALLINT)                         AS children_count,
            CAST(cnt_fam_members AS NUMERIC(10,2))                 AS family_member_count,
            CAST(name_family_status AS TEXT)                       AS family_status,
            CAST(name_type_suite AS TEXT)                          AS accompany_type,

            -- =========================
            -- Financial amounts
            -- =========================
            CAST(amt_income_total AS NUMERIC(18,2))                AS income_total_amt,
            CAST(amt_credit AS NUMERIC(18,2))                      AS credit_amt,
            CAST(amt_annuity AS NUMERIC(18,2))                     AS annuity_amt,
            CAST(amt_goods_price AS NUMERIC(18,2))                 AS goods_price_amt,

            -- =========================
            -- Education / occupation / housing
            -- =========================
            CAST(name_income_type AS TEXT)                         AS income_type,
            CAST(name_education_type AS TEXT)                      AS education_type,
            CAST(name_housing_type AS TEXT)                        AS housing_type,
            CAST(occupation_type AS TEXT)                          AS occupation_type,
            CAST(organization_type AS TEXT)                        AS organization_type,

            -- =========================
            -- Region / application timing
            -- =========================
            CAST(region_population_relative AS NUMERIC(12,8))      AS region_population_relative,
            CAST(region_rating_client AS SMALLINT)                 AS region_rating_client,
            CAST(region_rating_client_w_city AS SMALLINT)          AS region_rating_client_with_city,
            CAST(weekday_appr_process_start AS TEXT)               AS application_weekday,
            CAST(hour_appr_process_start AS SMALLINT)              AS application_hour,

            -- =========================
            -- Relative time columns (days)
            -- keep as integer for now
            -- =========================
            CAST(days_birth AS INTEGER)                                 AS days_birth,
            CAST(days_employed AS INTEGER)                              AS days_employed,
            CAST(CAST(days_registration AS NUMERIC) AS INTEGER)         AS days_registration,
            CAST(days_id_publish AS INTEGER)                            AS days_id_publish,
            CAST(CAST(days_last_phone_change AS NUMERIC) AS INTEGER)    AS days_last_phone_change,

            -- =========================
            -- Asset ownership / age
            -- =========================
            CAST(own_car_age AS NUMERIC(10,2))                     AS own_car_age,

            -- =========================
            -- Mobile / phone / email flags
            -- =========================
            CAST(flag_mobil AS SMALLINT)                           AS flag_mobile,
            CAST(flag_emp_phone AS SMALLINT)                       AS flag_emp_phone,
            CAST(flag_work_phone AS SMALLINT)                      AS flag_work_phone,
            CAST(flag_cont_mobile AS SMALLINT)                     AS flag_cont_mobile,
            CAST(flag_phone AS SMALLINT)                           AS flag_phone,
            CAST(flag_email AS SMALLINT)                           AS flag_email,

            -- =========================
            -- Address mismatch flags
            -- =========================
            CAST(reg_region_not_live_region AS SMALLINT)           AS reg_region_not_live_region,
            CAST(reg_region_not_work_region AS SMALLINT)           AS reg_region_not_work_region,
            CAST(live_region_not_work_region AS SMALLINT)          AS live_region_not_work_region,
            CAST(reg_city_not_live_city AS SMALLINT)               AS reg_city_not_live_city,
            CAST(reg_city_not_work_city AS SMALLINT)               AS reg_city_not_work_city,
            CAST(live_city_not_work_city AS SMALLINT)              AS live_city_not_work_city,

            -- =========================
            -- External sources
            -- =========================
            CAST(ext_source_1 AS NUMERIC(18,10))                   AS ext_source_1,
            CAST(ext_source_2 AS NUMERIC(18,10))                   AS ext_source_2,
            CAST(ext_source_3 AS NUMERIC(18,10))                   AS ext_source_3,

            -- =========================
            -- Building / property (AVG)
            -- =========================
            CAST(apartments_avg AS NUMERIC(12,6))                  AS apartments_avg,
            CAST(basementarea_avg AS NUMERIC(12,6))                AS basementarea_avg,
            CAST(years_beginexpluatation_avg AS NUMERIC(12,6))     AS years_beginexpluatation_avg,
            CAST(years_build_avg AS NUMERIC(12,6))                 AS years_build_avg,
            CAST(commonarea_avg AS NUMERIC(12,6))                  AS commonarea_avg,
            CAST(elevators_avg AS NUMERIC(12,6))                   AS elevators_avg,
            CAST(entrances_avg AS NUMERIC(12,6))                   AS entrances_avg,
            CAST(floorsmax_avg AS NUMERIC(12,6))                   AS floorsmax_avg,
            CAST(floorsmin_avg AS NUMERIC(12,6))                   AS floorsmin_avg,
            CAST(landarea_avg AS NUMERIC(12,6))                    AS landarea_avg,
            CAST(livingapartments_avg AS NUMERIC(12,6))            AS livingapartments_avg,
            CAST(livingarea_avg AS NUMERIC(12,6))                  AS livingarea_avg,
            CAST(nonlivingapartments_avg AS NUMERIC(12,6))         AS nonlivingapartments_avg,
            CAST(nonlivingarea_avg AS NUMERIC(12,6))               AS nonlivingarea_avg,

            -- =========================
            -- Building / property (MODE)
            -- =========================
            CAST(apartments_mode AS NUMERIC(12,6))                 AS apartments_mode,
            CAST(basementarea_mode AS NUMERIC(12,6))               AS basementarea_mode,
            CAST(years_beginexpluatation_mode AS NUMERIC(12,6))    AS years_beginexpluatation_mode,
            CAST(years_build_mode AS NUMERIC(12,6))                AS years_build_mode,
            CAST(commonarea_mode AS NUMERIC(12,6))                 AS commonarea_mode,
            CAST(elevators_mode AS NUMERIC(12,6))                  AS elevators_mode,
            CAST(entrances_mode AS NUMERIC(12,6))                  AS entrances_mode,
            CAST(floorsmax_mode AS NUMERIC(12,6))                  AS floorsmax_mode,
            CAST(floorsmin_mode AS NUMERIC(12,6))                  AS floorsmin_mode,
            CAST(landarea_mode AS NUMERIC(12,6))                   AS landarea_mode,
            CAST(livingapartments_mode AS NUMERIC(12,6))           AS livingapartments_mode,
            CAST(livingarea_mode AS NUMERIC(12,6))                 AS livingarea_mode,
            CAST(nonlivingapartments_mode AS NUMERIC(12,6))        AS nonlivingapartments_mode,
            CAST(nonlivingarea_mode AS NUMERIC(12,6))              AS nonlivingarea_mode,

            -- =========================
            -- Building / property (MEDI)
            -- =========================
            CAST(apartments_medi AS NUMERIC(12,6))                 AS apartments_medi,
            CAST(basementarea_medi AS NUMERIC(12,6))               AS basementarea_medi,
            CAST(years_beginexpluatation_medi AS NUMERIC(12,6))    AS years_beginexpluatation_medi,
            CAST(years_build_medi AS NUMERIC(12,6))                AS years_build_medi,
            CAST(commonarea_medi AS NUMERIC(12,6))                 AS commonarea_medi,
            CAST(elevators_medi AS NUMERIC(12,6))                  AS elevators_medi,
            CAST(entrances_medi AS NUMERIC(12,6))                  AS entrances_medi,
            CAST(floorsmax_medi AS NUMERIC(12,6))                  AS floorsmax_medi,
            CAST(floorsmin_medi AS NUMERIC(12,6))                  AS floorsmin_medi,
            CAST(landarea_medi AS NUMERIC(12,6))                   AS landarea_medi,
            CAST(livingapartments_medi AS NUMERIC(12,6))           AS livingapartments_medi,
            CAST(livingarea_medi AS NUMERIC(12,6))                 AS livingarea_medi,
            CAST(nonlivingapartments_medi AS NUMERIC(12,6))        AS nonlivingapartments_medi,
            CAST(nonlivingarea_medi AS NUMERIC(12,6))              AS nonlivingarea_medi,

            -- =========================
            -- Building categorical
            -- =========================
            CAST(fondkapremont_mode AS TEXT)                       AS fondkapremont_mode,
            CAST(housetype_mode AS TEXT)                           AS housetype_mode,
            CAST(totalarea_mode AS NUMERIC(12,6))                  AS totalarea_mode,
            CAST(wallsmaterial_mode AS TEXT)                       AS wallsmaterial_mode,
            CAST(emergencystate_mode AS TEXT)                      AS emergency_state_mode,

            -- =========================
            -- Social circle
            -- =========================
            CAST(obs_30_cnt_social_circle AS NUMERIC(10,2))        AS obs_30_cnt_social_circle,
            CAST(def_30_cnt_social_circle AS NUMERIC(10,2))        AS def_30_cnt_social_circle,
            CAST(obs_60_cnt_social_circle AS NUMERIC(10,2))        AS obs_60_cnt_social_circle,
            CAST(def_60_cnt_social_circle AS NUMERIC(10,2))        AS def_60_cnt_social_circle,

            -- =========================
            -- Document flags
            -- =========================
            CAST(flag_document_2 AS SMALLINT)                      AS flag_document_2,
            CAST(flag_document_3 AS SMALLINT)                      AS flag_document_3,
            CAST(flag_document_4 AS SMALLINT)                      AS flag_document_4,
            CAST(flag_document_5 AS SMALLINT)                      AS flag_document_5,
            CAST(flag_document_6 AS SMALLINT)                      AS flag_document_6,
            CAST(flag_document_7 AS SMALLINT)                      AS flag_document_7,
            CAST(flag_document_8 AS SMALLINT)                      AS flag_document_8,
            CAST(flag_document_9 AS SMALLINT)                      AS flag_document_9,
            CAST(flag_document_10 AS SMALLINT)                     AS flag_document_10,
            CAST(flag_document_11 AS SMALLINT)                     AS flag_document_11,
            CAST(flag_document_12 AS SMALLINT)                     AS flag_document_12,
            CAST(flag_document_13 AS SMALLINT)                     AS flag_document_13,
            CAST(flag_document_14 AS SMALLINT)                     AS flag_document_14,
            CAST(flag_document_15 AS SMALLINT)                     AS flag_document_15,
            CAST(flag_document_16 AS SMALLINT)                     AS flag_document_16,
            CAST(flag_document_17 AS SMALLINT)                     AS flag_document_17,
            CAST(flag_document_18 AS SMALLINT)                     AS flag_document_18,
            CAST(flag_document_19 AS SMALLINT)                     AS flag_document_19,
            CAST(flag_document_20 AS SMALLINT)                     AS flag_document_20,
            CAST(flag_document_21 AS SMALLINT)                     AS flag_document_21,

            -- =========================
            -- Bureau request counts
            -- =========================
            CAST(amt_req_credit_bureau_hour AS NUMERIC(10,2))      AS req_credit_bureau_hour_cnt,
            CAST(amt_req_credit_bureau_day AS NUMERIC(10,2))       AS req_credit_bureau_day_cnt,
            CAST(amt_req_credit_bureau_week AS NUMERIC(10,2))      AS req_credit_bureau_week_cnt,
            CAST(amt_req_credit_bureau_mon AS NUMERIC(10,2))       AS req_credit_bureau_month_cnt,
            CAST(amt_req_credit_bureau_qrt AS NUMERIC(10,2))       AS req_credit_bureau_quarter_cnt,
            CAST(amt_req_credit_bureau_year AS NUMERIC(10,2))      AS req_credit_bureau_year_cnt

        FROM stg_application_test__source 
        )

SELECT *
FROM stg_application_test__redefined