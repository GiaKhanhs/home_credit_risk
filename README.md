# Home Credit Risk Prediction Pipeline

End-to-end Machine Learning & Data Engineering project for credit default risk prediction using the Home Credit dataset.

This project focuses on building a production-style workflow:

- PostgreSQL Data Warehouse
- dbt Transformation Pipeline
- Feature Engineering
- ML Training Pipeline
- MLflow Experiment Tracking
- Model Evaluation & Selection

---

# Tech Stack

| Category | Tools |
|---|---|
| Language | Python 3.8.17 |
| Database | PostgreSQL |
| Transformation | dbt |
| ML | Scikit-learn, XGBoost, LightGBM |
| Experiment Tracking | MLflow |
| Visualization | Matplotlib, Seaborn |
| Environment | Virtual Environment (`venv`) |

---

# Project Structure

```bash
home_credit_risk/
│
├── create_db/
│   ├── create_db.py
│   ├── create_tables.py
│   ├── load_data.py
│   └── db_connection.py
│
├── dbt/
│   ├── models/
│   │   ├── staging/
│   │   ├── intermediate/
│   │   └── marts/
│   │
│   ├── macros/
│   └── schema.yml
│
├── notebooks/
├── src/
├── artifacts/
├── images/
├── requirements.txt
└── README.md
```

---

# Environment Setup

## Python Version

```bash
python --version
```

Expected:

```bash
Python 3.8.17
```

---

## Create Virtual Environment

```bash
python -m venv .venv
```

---

## Activate Environment

```bash
source .venv/bin/activate
```

---

## Install Libraries

```bash
pip install -r requirements.txt
```

---

# Dataset

The project uses the Home Credit Default Risk dataset.

Main CSV files:

- `application_train.csv`
- `application_test.csv`
- `bureau.csv`
- `bureau_balance.csv`
- `previous_application.csv`
- `POS_CASH_balance.csv`
- `credit_card_balance.csv`
- `installments_payments.csv`

---

# Data Warehouse Architecture

Overall pipeline:

```text
Raw Sources → Staging Models → Intermediate Features → Mart Tables
Bronze → Silver → Silver (Feature Engineering) → Gold
```

![DWH Architecture](images/dwh_architecture.png)

---

# Data Warehouse Layers

| Layer | Purpose | Output |
|---|---|---|
| Raw | Store original CSV data | Raw tables |
| Staging | Clean & standardize data | Cleaned tables |
| Intermediate | Feature engineering & aggregation | Feature tables |
| Mart | Final dataset for ML training | Customer-level dataset |

---

# Layer Details

| Layer | Input | Models | Key Transformations | Output |
|---|---|---|---|---|
| Raw (Bronze) | CSV files | `raw.*` | Load into PostgreSQL | Raw tables |
| Staging (Silver - Cleaning) | `raw.*` | `stg_*` | Type casting, missing value handling, standardization | Cleaned tables |
| Intermediate (Silver - Feature Engineering) | `stg_*` | `int_*` | Aggregation, behavior features, delinquency signals | Feature tables |
| Mart (Gold) | `int_*` | `mart_application_*` | Join all customer-level features | Final ML dataset |

---

# PostgreSQL Setup

## Test PostgreSQL Connection

```bash
python create_db/db_connection.py
```

Expected output:

```python
('PostgreSQL 18.3 on x86_64-apple-darwin24.6.0 ...')
```

---

## Create Database

```bash
python create_db/create_db.py
```

This script:

- Connects to PostgreSQL
- Creates `home_credit` database

---

## Create Raw Tables

```bash
python create_db/create_tables.py
```

---

## Load CSV Data

```bash
python create_db/load_data.py
```

All CSV files are loaded into PostgreSQL raw tables.

Important design choice:

- Raw layer stores data exactly as received
- Most columns are initially loaded as `TEXT`

This preserves source integrity before transformation.

---

# dbt Setup

## Initialize dbt Project

```bash
dbt init
```

Select:

```text
Database: postgres
```

---

## Configure profiles.yml

Location:

```bash
~/.dbt/profiles.yml
```

Used to connect dbt to PostgreSQL.

---

## Configure dbt_project.yml

```yaml
models:
  home_credit_risk:

    staging:
      +materialized: view
      +schema: staging

    intermediate:
      +materialized: view
      +schema: int

    marts:
      +materialized: table
      +schema: marts
```

---

# Staging Layer

Main responsibilities:

- Cast columns from `TEXT` to correct data types
- Standardize missing values
- Rename inconsistent columns
- Improve readability and consistency

Examples:

| Original Type | Converted Type |
|---|---|
| IDs | integer / bigint |
| Numeric values | numeric / double precision |
| Flags | boolean / smallint |
| Categories | text / varchar |

---

# Intermediate Layer

Feature engineering and aggregation layer.

Main tasks:

- Aggregate historical records
- Generate customer-level behavioral signals
- Convert:
  
```text
SK_ID_PREV → SK_ID_CURR
```

Examples:

- Previous application statistics
- Delinquency behavior
- Credit utilization
- Late payment ratios
- Installment behavior

---

# Mart Layer

Final analytical layer.

Main outputs:

- `mart_application_train`
- `mart_application_test`

These datasets are used directly for:

- Machine Learning
- Model Evaluation
- Experiment Tracking

---

# dbt Lineage Graph

Generated using:

```bash
dbt docs generate
dbt docs serve
```

Example lineage graph:

![dbt docs](images/dbt_docs_serve.png)

---

# Machine Learning Pipeline

The ML pipeline includes:

- Logistic Regression
- Random Forest
- Gradient Boosting Models
- Hyperparameter Tuning
- Threshold Optimization
- Final Model Selection

---

# Experiment Flow

![Experiment Flow](images/experiment_flow.png)

---

# MLflow Tracking

MLflow is used to track:

- Hyperparameters
- Metrics
- Threshold tuning
- Model comparison
- Final model registration

Tracked metrics:

- AUC ROC
- F1 Score
- Precision
- Recall
- Accuracy

---

# Data Versioning with DVC

The project uses DVC (Data Version Control) to version processed datasets and ensure reproducibility across experiments.

Current usage:

- Track processed datasets
- Store dataset versions separately from Git
- Enable reproducible ML experiments
- Support future dataset evolution and feature engineering changes

Typical workflow:

```bash
dvc init

dvc add data/processed/train_v1.parquet

git add .gitignore *.dvc
git commit -m "Track processed datasets with DVC"
```

```text
data/
├── raw/
├── processed/
│   ├── train_v1.parquet
│   ├── train_v1.parquet.dvc
```
---
# Example ML Workflow

## Train/Test Split

```python
train_test_split(
    X,
    y,
    test_size=0.2,
    stratify=y,
    random_state=42
)
```

---

## Hyperparameter Tuning

Examples:

- Grid Search CV
- Randomized Search CV
- Bayesian Optimization

---

## Threshold Optimization

Instead of using default threshold `0.5`, the project searches for the best threshold based on:

- F1 Score
- Recall
- Precision

---

# Final Outputs

Final outputs of the project:

- Production-style Data Warehouse
- Clean customer-level datasets
- Feature engineering pipeline
- Experiment tracking workflow
- Trained ML models
- Reproducible end-to-end pipeline

---

# Future Improvements

Potential next steps:

- Docker deployment
- FastAPI inference service
- CI/CD pipeline
- Feature Store integration
- Airflow orchestration
- Model monitoring
- Data validation with Great Expectations

---

# Author

Gia Khánh

Focused on:

- Data Engineering
- Machine Learning Engineering
- MLOps
- End-to-End ML Systems
