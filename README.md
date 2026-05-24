# Healthcare Insurance Claims Data Pipeline

An end-to-end Healthcare Claims Processing System built entirely using Snowflake.
This project demonstrates automated ETL pipelines, Change Data Capture (CDC), fraud detection, analytics engineering, and interactive dashboarding using Streamlit.

---

# Architecture

```text
CSV Files
   ↓
Snowflake Internal Stage
   ↓
Raw Tables (HEALTHCARE_DB.RAW)
   ↓
Streams (CDC)
   ↓
Tasks (Automated Processing)
   ↓
Processed Tables (HEALTHCARE_DB.PROCESSED)
   ↓
Analytics Views (HEALTHCARE_DB.ANALYTICS)
   ↓
Streamlit Dashboard
```

---

# Project Structure

```text
healthcare_dataanalysis/
├── sql/
│   └── setup.sql
├── streamlit/
│   ├── .streamlit/config.toml
│   ├── snowflake.yml
│   ├── pyproject.toml
│   └── streamlit_app.py
└── README.md
```

---

# Dataset

| Table     | Description                         |
| --------- | ----------------------------------- |
| patients  | Patient demographic information     |
| claims    | Insurance claim transaction records |
| hospitals | Hospital master dataset             |

### Patients

* patient_id
* name
* age
* gender
* city

### Claims

* claim_id
* patient_id
* hospital
* diagnosis
* claim_amount
* status

### Hospitals

* hospital_id
* hospital_name
* city

---

# Snowflake Concepts Covered

## Beginner Level

* Database & Schema Creation
* Tables & Views
* Internal Stages
* COPY INTO
* File Formats

## Intermediate Level

* Streams (CDC)
* Tasks (Automation)
* Stored Procedures

## Advanced Level

* Time Travel
* Zero-Copy Cloning
* Role-Based Access Control (RBAC)

---

# Pipeline Features

| Feature             | Description                                |
| ------------------- | ------------------------------------------ |
| Data Ingestion      | CSV → Internal Stage → Raw Tables          |
| Data Cleaning       | Standardization, null handling, validation |
| Duplicate Detection | Detects repeated claim IDs                 |
| Fraud Detection     | Flags suspicious high-value claims         |
| Incremental Loading | Stream + Task based automation             |
| Analytics Layer     | Business-ready reporting views             |
| Backup & Recovery   | Zero-copy clone and Time Travel            |

---

# Fraud Detection Logic

Claims are categorized based on claim amount:

| Claim Amount          | Risk Level  |
| --------------------- | ----------- |
| > ₹5,00,000           | HIGH RISK   |
| ₹2,00,000 – ₹5,00,000 | MEDIUM RISK |
| < ₹2,00,000           | LOW RISK    |

---

# Streamlit Dashboard

Interactive dashboard built using Streamlit in Snowflake with Altair visualizations.

## Dashboard Tabs

### 1. Overview

* KPI Metrics
* Claims Distribution
* Summary Charts

### 2. Claims by Hospital

* Hospital-wise claim analysis
* Horizontal bar charts
* Stacked bar charts

### 3. Fraud Detection

* Fraud monitoring dashboard
* Donut chart
* Scatter plot analysis

### 4. Duplicate Claims

* Duplicate claim insights
* Data quality monitoring

### 5. Patient Summary

* Age vs Claim Amount analysis
* Diagnosis distribution
* Demographic insights

### 6. Pipeline Status

* Stream status
* Task execution monitoring
* Time Travel examples
* Clone validation

---

# Chart Types Used

* Bar Chart
* Horizontal Bar Chart
* Pie Chart
* Donut Chart
* Scatter Plot
* Stacked Bar Chart

---

# Setup Instructions

## Prerequisites

* Snowflake Account
* ACCOUNTADMIN or equivalent access
* Active Warehouse (e.g., COMPUTE_WH)

---

## Step 1: Run SQL Setup

Execute `sql/setup.sql` inside Snowsight.

This script will:

* Create database and schemas
* Create stages and file formats
* Create raw and processed tables
* Load sample healthcare datasets
* Create Streams and Tasks
* Build analytics views
* Create zero-copy clone backups

---

## Step 2: Run Streamlit App

1. Upload the `streamlit/` folder to Snowflake Workspace
2. Open the project in Snowsight
3. Click **Run**

---

# Key SQL Examples

## Fraud Detection

```sql
SELECT *
FROM HEALTHCARE_DB.ANALYTICS.FRAUD_CLAIMS
WHERE FRAUD_RISK_LEVEL = 'HIGH RISK';
```

## Duplicate Claims

```sql
SELECT *
FROM HEALTHCARE_DB.ANALYTICS.DUPLICATE_CLAIMS;
```

## Time Travel Example

```sql
SELECT *
FROM HEALTHCARE_DB.PROCESSED.CLAIMS_CLEAN
AT(OFFSET => -60*5);
```

## Zero-Copy Clone

```sql
CREATE TABLE CLAIMS_BACKUP
CLONE HEALTHCARE_DB.PROCESSED.CLAIMS_CLEAN;
```

---

# Technologies Used

* Snowflake
* SQL
* Python
* Streamlit
* Altair

---

# Skills Demonstrated

* ETL Pipeline Development
* Data Warehousing
* Incremental Data Processing
* Change Data Capture (CDC)
* Healthcare Analytics
* Fraud Detection
* Data Quality Engineering
* Dashboard Development

---

# Author

Built by **Cyril** as a portfolio project to demonstrate end-to-end Data Engineering using Snowflake.

---

# License

This project is intended for educational and portfolio purposes.
