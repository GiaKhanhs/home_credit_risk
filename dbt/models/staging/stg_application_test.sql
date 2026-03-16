WITH source AS (

    SELECT *
    FROM {{ source('raw','application_test') }}

)

SELECT *
FROM source