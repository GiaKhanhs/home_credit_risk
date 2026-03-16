# Structure of project

```text
home_credit_risk/
│
├── data/
│   ├── raw/              # Original datasets (CSV files from Kaggle)
│   └── processed/        # Cleaned and feature-engineered datasets
│
├── create_db/
│   ├── schema.sql        # SQL script to create database tables
│   ├── indexes.sql       # Index creation for query optimization
│   └── import_data.py    # Python script to load CSV data into PostgreSQL
│
├── sql/
│   ├── bureau_agg.sql    # Aggregations for bureau table
│   ├── previous_agg.sql  # Aggregations for previous applications
│   └── final_dataset.sql # SQL pipeline to build the final modeling dataset
│
├── src/
│   ├── export_dataset.py # Export final dataset from database to ML-ready format
│   ├── train.py          # Machine learning model training script
│   └── preprocess.py     # Data preprocessing and feature engineering
│
├── artifacts/            # Saved models, logs, and experiment outputs
│
├── app/                  # Optional application layer (API or inference service)
│
└── Dockerfile            # Container configuration for reproducible environment

```


# Create Environment
`python --version` --> 3.8.17
`python -m venv .venv`
## Activate env
`source .venv/bin/activate`

## Install libraries
`pip install -r requirements.txt`

# Create raw layer
- Load all 8 CSV files into PostgreSQL raw tables.
- Store data exactly as received, even if all columns are initially loaded as `TEXT`.

## Create connection to Postgres
`python /Users/giakhanh/Desktop/AIDE/Projects/home_credit_risk/create_db/db_connection.py`
Output:
```
('PostgreSQL 18.3 on x86_64-apple-darwin24.6.0, compiled by Apple clang version 17.0.0 (clang-1700.6.3.2), 64-bit',)
```
This means connected and show the version

## Create databse
`python /Users/giakhanh/Desktop/AIDE/Projects/home_credit_risk/create_db/create_db.py`

In Postgres, we have to connect to a databse to create another database. You can see in my code that I connect to postgre database to create home_credit database

### Create tables
`python /Users/giakhanh/Desktop/AIDE/Projects/home_credit_risk/create_db/create_tables.py`

### Load data
`python /Users/giakhanh/Desktop/AIDE/Projects/home_credit_risk/create_db/load_data.py`

Now you can check it in database, here I use DBeaver

# Create dbt project
## Initiation
`dbt init`
```
(.venv) giakhanh@192 home_credit_risk % dbt init
08:39:11  Running with dbt=1.6.0
Enter a name for your project (letters, digits, underscore): home_credit_risk
08:39:26  
Your new dbt project "home_credit_risk" was created!

For more information on how to configure the profiles.yml file,
please consult the dbt documentation here:

  https://docs.getdbt.com/docs/configure-your-profile

One more thing:

Need help? Don't hesitate to reach out to us via GitHub issues or on Slack:

  https://community.getdbt.com/

Happy modeling!

08:39:26  Setting up your profile.
Which database would you like to use?
[1] postgres

(Don't see the one you want? https://docs.getdbt.com/docs/available-adapters)

Enter a number: 1
```
## Edit profile.yml
`code /Users/giakhanh/.dbt/profiles.yml`
This will open profiles.yml on VSCode or any other IDE

This `profile.yml` use to connect to database, here is Postgres.

## Edit dbt_project.yml
This file is used to design layers in Data Warehouse, here i will desing it in 3 layers:
```YAML
models:
  home_credit_risk:
    # Config indicated by + and applies to all files under models/example/
    staging:
      +materialized: view
      +schema: staging

    intermediate:
      +materialized: view
      +schema: int
    
    marts:
      +materialize: table
      +schema: marts
```

- At staging layer, I will 
    - Cast columns from `TEXT` to appropriate data types:

        - IDs → integer / bigint

        - numeric measures → numeric / double precision

        - flags → boolean / smallint

        - categorical columns → text / varchar

        - Standardize missing values such as empty strings, `NULL`, `NaN`, or special placeholders.
    - Rename columns only if it improves readability and consistency.
    
