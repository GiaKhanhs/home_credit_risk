WITH bureau_balance__source AS (
    SELECT *
    FROM {{ ref( "stg_bureau_balance") }}
) 

    , bureau__source AS (
        SELECT DISTINCT sk_id_bureau
        FROM {{ ref('stg_bureau') }}
    )

    , valid_bureau_balance AS (
        SELECT
            bb.*
        FROM bureau_balance__source bb
        INNER JOIN bureau__source b
        ON bb.sk_id_bureau = b.sk_id_bureau
    )

    , base AS (
        SELECT 
            sk_id_bureau,
            months_balance,
            status
        FROM valid_bureau_balance
    )
    
    , derived AS (
        SELECT 
            sk_id_bureau,
            months_balance,
            status,

            -- status flag
            CASE WHEN status = '0' THEN 1 ELSE 0 END AS flag_status_0,
            CASE WHEN status = '1' THEN 1 ELSE 0 END AS flag_status_1,
            CASE WHEN status = '2' THEN 1 ELSE 0 END AS flag_status_2,
            CASE WHEN status = '3' THEN 1 ELSE 0 END AS flag_status_3,
            CASE WHEN status = '4' THEN 1 ELSE 0 END AS flag_status_4,
            CASE WHEN status = '5' THEN 1 ELSE 0 END AS flag_status_5,
            CASE WHEN status = 'C' THEN 1 ELSE 0 END AS flag_status_closed,
            CASE WHEN status = 'X' THEN 1 ELSE 0 END AS flag_status_unknown,

            -- Check DPD (Day Past Due)
            CASE 
                WHEN status IN ('1', '2', '3', '4', '5') 
                    THEN 1 
                    ELSE 0 
            END AS flag_has_dpd,

            -- Check severity
            CASE 
                WHEN status = '0' THEN 0
                WHEN status = '1' THEN 1
                WHEN status = '2' THEN 2
                WHEN status = '3' THEN 3
                WHEN status = '4' THEN 4
                WHEN status = '5' THEN 5
                ELSE NULL
            END AS dpd_severity

        FROM base
    )

    , aggregate AS (
        SELECT
            sk_id_bureau,

            COUNT(*) AS bureau_balance_month_count,

            MIN(months_balance) AS bureau_balance_oldest_month,
            MAX(months_balance) AS bureau_balance_latest_month,

            SUM(flag_status_0) AS bureau_balance_status_0_count,
            SUM(flag_status_1) AS bureau_balance_status_1_count,
            SUM(flag_status_2) AS bureau_balance_status_2_count,
            SUM(flag_status_3) AS bureau_balance_status_3_count,
            SUM(flag_status_4) AS bureau_balance_status_4_count,
            SUM(flag_status_5) AS bureau_balance_status_5_count,
            SUM(flag_status_closed) AS bureau_balance_status_closed_count,
            SUM(flag_status_unknown) AS bureau_balance_status_unknown_count,

            SUM(flag_has_dpd) AS bureau_balance_dpd_month_count,

            MAX(dpd_severity) AS bureau_balance_max_dpd_severity,

            CASE
                WHEN SUM(flag_has_dpd) > 0 THEN 1
                ELSE 0
            END AS flag_bureau_balance_has_dpd_history,

            CASE
                WHEN SUM(flag_status_closed) = COUNT(*) THEN 1
                ELSE 0
            END AS flag_bureau_balance_all_closed

        FROM derived
        GROUP BY sk_id_bureau
    )

    , final AS (
        SELECT *
        FROM aggregate
    )

SELECT * 
FROM final