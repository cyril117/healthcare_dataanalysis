-- ============================================================
-- Healthcare Insurance Claims Data Pipeline - Full Setup
-- ============================================================

-- Step 1: Create Database and Schemas
CREATE DATABASE IF NOT EXISTS HEALTHCARE_DB;
CREATE SCHEMA IF NOT EXISTS HEALTHCARE_DB.RAW;
CREATE SCHEMA IF NOT EXISTS HEALTHCARE_DB.PROCESSED;
CREATE SCHEMA IF NOT EXISTS HEALTHCARE_DB.ANALYTICS;

-- Step 2: Create File Format
CREATE OR REPLACE FILE FORMAT HEALTHCARE_DB.RAW.CSV_FORMAT
    TYPE = CSV
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    NULL_IF = ('NULL', 'null', '');

-- Step 3: Create Internal Stage
CREATE OR REPLACE STAGE HEALTHCARE_DB.RAW.HEALTHCARE_STAGE
    FILE_FORMAT = HEALTHCARE_DB.RAW.CSV_FORMAT;

-- Step 4: Create Raw Tables
CREATE OR REPLACE TABLE HEALTHCARE_DB.RAW.PATIENTS_RAW (
    PATIENT_ID STRING,
    NAME STRING,
    AGE NUMBER,
    GENDER STRING,
    CITY STRING
);

CREATE OR REPLACE TABLE HEALTHCARE_DB.RAW.CLAIMS_RAW (
    CLAIM_ID STRING,
    PATIENT_ID STRING,
    HOSPITAL STRING,
    DIAGNOSIS STRING,
    CLAIM_AMOUNT NUMBER(12,2),
    STATUS STRING
);

CREATE OR REPLACE TABLE HEALTHCARE_DB.RAW.HOSPITALS_RAW (
    HOSPITAL_ID STRING,
    HOSPITAL_NAME STRING,
    CITY STRING
);

-- Step 5: Insert Sample Data - Patients
INSERT INTO HEALTHCARE_DB.RAW.PATIENTS_RAW VALUES
('P001', 'Rahul Sharma', 45, 'Male', 'Mumbai'),
('P002', 'Priya Patel', 32, 'Female', 'Delhi'),
('P003', 'Amit Kumar', 55, 'Male', 'Bangalore'),
('P004', 'Sneha Reddy', 28, 'Female', 'Hyderabad'),
('P005', 'Vikram Singh', 62, 'Male', 'Chennai'),
('P006', 'Anita Desai', 40, 'Female', 'Pune'),
('P007', 'Rajesh Gupta', 50, 'Male', 'Kolkata'),
('P008', 'Meera Joshi', 35, 'Female', 'Mumbai'),
('P009', 'Suresh Nair', 48, 'Male', 'Bangalore'),
('P010', 'Kavita Iyer', 58, 'Female', 'Chennai'),
('P011', 'Arjun Malhotra', 42, 'Male', 'Delhi'),
('P012', 'Deepika Rao', 30, 'Female', 'Hyderabad'),
('P013', 'Manoj Tiwari', 65, 'Male', 'Mumbai'),
('P014', 'Pooja Mehta', 37, 'Female', 'Pune'),
('P015', 'Karthik Subramanian', 52, 'Male', 'Chennai');

-- Step 5b: Insert Sample Data - Hospitals
INSERT INTO HEALTHCARE_DB.RAW.HOSPITALS_RAW VALUES
('H001', 'Apollo Hospital', 'Mumbai'),
('H002', 'Fortis Healthcare', 'Delhi'),
('H003', 'Max Hospital', 'Bangalore'),
('H004', 'AIIMS', 'Delhi'),
('H005', 'Manipal Hospital', 'Hyderabad'),
('H006', 'Narayana Health', 'Chennai'),
('H007', 'Kokilaben Hospital', 'Mumbai'),
('H008', 'Medanta', 'Pune');

-- Step 5c: Insert Sample Data - Claims (including duplicates for detection)
INSERT INTO HEALTHCARE_DB.RAW.CLAIMS_RAW VALUES
('C001', 'P001', 'Apollo Hospital', 'Cardiac Surgery', 750000, 'Approved'),
('C002', 'P002', 'Fortis Healthcare', 'Knee Replacement', 350000, 'Approved'),
('C003', 'P003', 'Max Hospital', 'Diabetes Treatment', 85000, 'Pending'),
('C004', 'P004', 'Manipal Hospital', 'Appendectomy', 120000, 'Approved'),
('C005', 'P005', 'Narayana Health', 'Bypass Surgery', 900000, 'Approved'),
('C006', 'P006', 'Kokilaben Hospital', 'Fracture Treatment', 65000, 'Rejected'),
('C007', 'P007', 'AIIMS', 'Cancer Treatment', 1200000, 'Pending'),
('C008', 'P008', 'Apollo Hospital', 'Maternity', 180000, 'Approved'),
('C009', 'P009', 'Max Hospital', 'Spine Surgery', 550000, 'Approved'),
('C010', 'P010', 'Narayana Health', 'Heart Valve Replacement', 850000, 'Pending'),
('C011', 'P001', 'Apollo Hospital', 'Follow-up Cardiac', 45000, 'Approved'),
('C012', 'P003', 'Max Hospital', 'Diabetes Checkup', 25000, 'Approved'),
('C013', 'P011', 'Fortis Healthcare', 'Liver Transplant', 1500000, 'Pending'),
('C014', 'P012', 'Manipal Hospital', 'Dental Surgery', 95000, 'Approved'),
('C015', 'P013', 'Kokilaben Hospital', 'Hip Replacement', 420000, 'Approved'),
('C016', 'P014', 'Medanta', 'Eye Surgery', 150000, 'Approved'),
('C017', 'P015', 'Narayana Health', 'Kidney Dialysis', 280000, 'Pending'),
('C018', 'P002', 'Fortis Healthcare', 'Physiotherapy', 35000, 'Approved'),
('C019', 'P005', 'Narayana Health', 'Cardiac Rehab', 120000, 'Rejected'),
('C020', 'P008', 'Apollo Hospital', 'General Checkup', 15000, 'Approved'),
('C001', 'P001', 'Apollo Hospital', 'Cardiac Surgery', 750000, 'Approved'),
('C005', 'P005', 'Narayana Health', 'Bypass Surgery', 900000, 'Approved'),
('C021', 'P009', 'Max Hospital', 'Spine Follow-up', 600000, 'Pending'),
('C022', 'P011', 'Fortis Healthcare', 'Liver Checkup', 2000000, 'Pending');

-- Step 6: Create Processed Table (Clean Data)
CREATE OR REPLACE TABLE HEALTHCARE_DB.PROCESSED.CLAIMS_CLEAN AS
SELECT
    CLAIM_ID,
    PATIENT_ID,
    UPPER(HOSPITAL) AS HOSPITAL,
    DIAGNOSIS,
    CLAIM_AMOUNT,
    STATUS
FROM HEALTHCARE_DB.RAW.CLAIMS_RAW
WHERE CLAIM_AMOUNT > 0;

CREATE OR REPLACE TABLE HEALTHCARE_DB.PROCESSED.PATIENTS_CLEAN AS
SELECT
    PATIENT_ID,
    NAME,
    AGE,
    GENDER,
    UPPER(CITY) AS CITY
FROM HEALTHCARE_DB.RAW.PATIENTS_RAW;

CREATE OR REPLACE TABLE HEALTHCARE_DB.PROCESSED.HOSPITALS_CLEAN AS
SELECT
    HOSPITAL_ID,
    UPPER(HOSPITAL_NAME) AS HOSPITAL_NAME,
    UPPER(CITY) AS CITY
FROM HEALTHCARE_DB.RAW.HOSPITALS_RAW;

-- Step 7: Duplicate Claim Detection View
CREATE OR REPLACE VIEW HEALTHCARE_DB.ANALYTICS.DUPLICATE_CLAIMS AS
SELECT
    CLAIM_ID,
    COUNT(*) AS DUPLICATE_COUNT
FROM HEALTHCARE_DB.PROCESSED.CLAIMS_CLEAN
GROUP BY CLAIM_ID
HAVING COUNT(*) > 1;

-- Step 8: Fraud Detection View (Claims > 500000)
CREATE OR REPLACE VIEW HEALTHCARE_DB.ANALYTICS.FRAUD_CLAIMS AS
SELECT
    c.CLAIM_ID,
    c.PATIENT_ID,
    p.NAME AS PATIENT_NAME,
    c.HOSPITAL,
    c.DIAGNOSIS,
    c.CLAIM_AMOUNT,
    c.STATUS,
    CASE
        WHEN c.CLAIM_AMOUNT > 1000000 THEN 'HIGH RISK'
        WHEN c.CLAIM_AMOUNT > 500000 THEN 'MEDIUM RISK'
        ELSE 'LOW RISK'
    END AS FRAUD_RISK_LEVEL
FROM HEALTHCARE_DB.PROCESSED.CLAIMS_CLEAN c
LEFT JOIN HEALTHCARE_DB.PROCESSED.PATIENTS_CLEAN p ON c.PATIENT_ID = p.PATIENT_ID
WHERE c.CLAIM_AMOUNT > 500000;

-- Step 9: Analytics Views
CREATE OR REPLACE VIEW HEALTHCARE_DB.ANALYTICS.CLAIMS_BY_HOSPITAL AS
SELECT
    HOSPITAL,
    COUNT(*) AS TOTAL_CLAIMS,
    SUM(CLAIM_AMOUNT) AS TOTAL_AMOUNT,
    AVG(CLAIM_AMOUNT) AS AVG_AMOUNT,
    COUNT(CASE WHEN STATUS = 'Approved' THEN 1 END) AS APPROVED_CLAIMS,
    COUNT(CASE WHEN STATUS = 'Rejected' THEN 1 END) AS REJECTED_CLAIMS,
    COUNT(CASE WHEN STATUS = 'Pending' THEN 1 END) AS PENDING_CLAIMS
FROM HEALTHCARE_DB.PROCESSED.CLAIMS_CLEAN
GROUP BY HOSPITAL;

CREATE OR REPLACE VIEW HEALTHCARE_DB.ANALYTICS.CLAIMS_BY_STATUS AS
SELECT
    STATUS,
    COUNT(*) AS CLAIM_COUNT,
    SUM(CLAIM_AMOUNT) AS TOTAL_AMOUNT,
    AVG(CLAIM_AMOUNT) AS AVG_AMOUNT
FROM HEALTHCARE_DB.PROCESSED.CLAIMS_CLEAN
GROUP BY STATUS;

CREATE OR REPLACE VIEW HEALTHCARE_DB.ANALYTICS.PATIENT_CLAIMS_SUMMARY AS
SELECT
    p.PATIENT_ID,
    p.NAME,
    p.AGE,
    p.GENDER,
    p.CITY,
    COUNT(c.CLAIM_ID) AS TOTAL_CLAIMS,
    SUM(c.CLAIM_AMOUNT) AS TOTAL_CLAIM_AMOUNT,
    AVG(c.CLAIM_AMOUNT) AS AVG_CLAIM_AMOUNT,
    MAX(c.CLAIM_AMOUNT) AS MAX_CLAIM
FROM HEALTHCARE_DB.PROCESSED.PATIENTS_CLEAN p
LEFT JOIN HEALTHCARE_DB.PROCESSED.CLAIMS_CLEAN c ON p.PATIENT_ID = c.PATIENT_ID
GROUP BY p.PATIENT_ID, p.NAME, p.AGE, p.GENDER, p.CITY;

CREATE OR REPLACE VIEW HEALTHCARE_DB.ANALYTICS.CLAIMS_BY_DIAGNOSIS AS
SELECT
    DIAGNOSIS,
    COUNT(*) AS CLAIM_COUNT,
    SUM(CLAIM_AMOUNT) AS TOTAL_AMOUNT,
    AVG(CLAIM_AMOUNT) AS AVG_AMOUNT,
    MAX(CLAIM_AMOUNT) AS MAX_AMOUNT
FROM HEALTHCARE_DB.PROCESSED.CLAIMS_CLEAN
GROUP BY DIAGNOSIS
ORDER BY TOTAL_AMOUNT DESC;

-- Step 10: Create Stream for Change Data Capture
CREATE OR REPLACE STREAM HEALTHCARE_DB.RAW.CLAIMS_STREAM
    ON TABLE HEALTHCARE_DB.RAW.CLAIMS_RAW;

-- Step 11: Create Task for Automated Incremental Processing
CREATE OR REPLACE TASK HEALTHCARE_DB.RAW.CLAIMS_TASK
    WAREHOUSE = COMPUTE_WH
    SCHEDULE = '5 MINUTE'
    WHEN SYSTEM$STREAM_HAS_DATA('HEALTHCARE_DB.RAW.CLAIMS_STREAM')
AS
INSERT INTO HEALTHCARE_DB.PROCESSED.CLAIMS_CLEAN
SELECT
    CLAIM_ID,
    PATIENT_ID,
    UPPER(HOSPITAL),
    DIAGNOSIS,
    CLAIM_AMOUNT,
    STATUS
FROM HEALTHCARE_DB.RAW.CLAIMS_STREAM
WHERE CLAIM_AMOUNT > 0
AND METADATA$ACTION = 'INSERT';

ALTER TASK HEALTHCARE_DB.RAW.CLAIMS_TASK RESUME;

-- Step 12: Zero-Copy Clone for Backup
CREATE OR REPLACE TABLE HEALTHCARE_DB.PROCESSED.CLAIMS_BACKUP
    CLONE HEALTHCARE_DB.PROCESSED.CLAIMS_CLEAN;
