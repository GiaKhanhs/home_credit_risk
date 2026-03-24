WITH stg_bureau_balance__source AS (
    SELECT * 
    FROM {{ source("raw", "bureau_balance") }}
)
    , stg_bureau_balance__redefined AS (
        SELECT 
            CAST(sk_id_bureau AS BIGINT)                AS sk_id_bureau,
            CAST(months_balance AS INTEGER)             AS months_balance,
            CAST(status AS TEXT)                        AS status

        FROM stg_bureau_balance__source
    )

SELECT * 
FROM stg_bureau_balance__redefined