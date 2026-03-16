WITH source AS (

    SELECT *
    FROM {{ source('raw','application_train') }}

)

SELECT *
FROM source