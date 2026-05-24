import streamlit as st
import os
import altair as alt

st.set_page_config(page_title="Healthcare Claims Pipeline", layout="wide")

conn = st.connection("snowflake", ttl=os.getenv("SNOWFLAKE_CONNECTION_TTL"))

st.title("Healthcare Insurance Claims Pipeline Dashboard")

tab1, tab2, tab3, tab4, tab5, tab6 = st.tabs([
    "Overview", "Claims by Hospital", "Fraud Detection",
    "Duplicate Claims", "Patient Summary", "Pipeline Status"
])

with tab1:
    st.header("Claims Overview")

    df_status = conn.query("SELECT STATUS, COUNT(*) AS CLAIM_COUNT, SUM(CLAIM_AMOUNT) AS TOTAL_AMOUNT FROM HEALTHCARE_DB.PROCESSED.CLAIMS_CLEAN GROUP BY STATUS")

    col1, col2, col3, col4 = st.columns(4)
    total_claims = df_status["CLAIM_COUNT"].sum()
    total_amount = df_status["TOTAL_AMOUNT"].sum()
    approved = df_status[df_status["STATUS"] == "Approved"]["CLAIM_COUNT"].sum()
    pending = df_status[df_status["STATUS"] == "Pending"]["CLAIM_COUNT"].sum()

    col1.metric("Total Claims", int(total_claims))
    col2.metric("Total Amount", f"₹{total_amount:,.0f}")
    col3.metric("Approved", int(approved))
    col4.metric("Pending", int(pending))

    col_left, col_right = st.columns(2)

    with col_left:
        st.subheader("Claims Amount by Status (Bar)")
        st.bar_chart(df_status, x="STATUS", y="TOTAL_AMOUNT", x_label="Status", y_label="Total Amount (₹)")

    with col_right:
        st.subheader("Claims Distribution (Pie)")
        pie_chart = alt.Chart(df_status).mark_arc(innerRadius=50).encode(
            theta=alt.Theta("CLAIM_COUNT:Q", title="Claims"),
            color=alt.Color("STATUS:N", title="Status"),
            tooltip=["STATUS", "CLAIM_COUNT", "TOTAL_AMOUNT"]
        ).properties(height=300)
        st.altair_chart(pie_chart)

    st.subheader("All Claims Data")
    df_all = conn.query("SELECT * FROM HEALTHCARE_DB.PROCESSED.CLAIMS_CLEAN ORDER BY CLAIM_AMOUNT DESC")
    st.dataframe(df_all, hide_index=True)

with tab2:
    st.header("Hospital-wise Analytics")

    df_hospital = conn.query("SELECT * FROM HEALTHCARE_DB.ANALYTICS.CLAIMS_BY_HOSPITAL ORDER BY TOTAL_AMOUNT DESC")

    col_left, col_right = st.columns(2)

    with col_left:
        st.subheader("Total Amount by Hospital (Bar)")
        bar_chart = alt.Chart(df_hospital).mark_bar().encode(
            x=alt.X("TOTAL_AMOUNT:Q", title="Total Amount (₹)"),
            y=alt.Y("HOSPITAL:N", sort="-x", title="Hospital"),
            color=alt.Color("HOSPITAL:N", legend=None),
            tooltip=["HOSPITAL", "TOTAL_CLAIMS", "TOTAL_AMOUNT"]
        ).properties(height=350)
        st.altair_chart(bar_chart)

    with col_right:
        st.subheader("Claims Share by Hospital (Pie)")
        pie_hospital = alt.Chart(df_hospital).mark_arc().encode(
            theta=alt.Theta("TOTAL_AMOUNT:Q"),
            color=alt.Color("HOSPITAL:N", title="Hospital"),
            tooltip=["HOSPITAL", "TOTAL_AMOUNT", "TOTAL_CLAIMS"]
        ).properties(height=350)
        st.altair_chart(pie_hospital)

    st.subheader("Approved vs Rejected vs Pending (Stacked Bar)")
    df_stacked = df_hospital[["HOSPITAL", "APPROVED_CLAIMS", "REJECTED_CLAIMS", "PENDING_CLAIMS"]].melt(
        id_vars="HOSPITAL", var_name="STATUS_TYPE", value_name="COUNT"
    )
    stacked_bar = alt.Chart(df_stacked).mark_bar().encode(
        x=alt.X("HOSPITAL:N", title="Hospital"),
        y=alt.Y("COUNT:Q", title="Claim Count"),
        color=alt.Color("STATUS_TYPE:N", title="Status"),
        tooltip=["HOSPITAL", "STATUS_TYPE", "COUNT"]
    ).properties(height=300)
    st.altair_chart(stacked_bar)

    st.subheader("Hospital Data")
    st.dataframe(df_hospital, hide_index=True)

with tab3:
    st.header("Fraud Detection - Suspicious Claims")
    st.info("Claims above ₹5,00,000 are flagged for review")

    df_fraud = conn.query("SELECT * FROM HEALTHCARE_DB.ANALYTICS.FRAUD_CLAIMS ORDER BY CLAIM_AMOUNT DESC")

    if len(df_fraud) > 0:
        col1, col2, col3 = st.columns(3)
        high_risk = len(df_fraud[df_fraud["FRAUD_RISK_LEVEL"] == "HIGH RISK"])
        med_risk = len(df_fraud[df_fraud["FRAUD_RISK_LEVEL"] == "MEDIUM RISK"])
        col1.metric("High Risk (>₹10L)", high_risk)
        col2.metric("Medium Risk (₹5L-10L)", med_risk)
        col3.metric("Total Flagged", len(df_fraud))

        col_left, col_right = st.columns(2)

        with col_left:
            st.subheader("Fraud Risk Distribution (Donut)")
            risk_counts = df_fraud["FRAUD_RISK_LEVEL"].value_counts().reset_index()
            risk_counts.columns = ["RISK_LEVEL", "COUNT"]
            donut = alt.Chart(risk_counts).mark_arc(innerRadius=60).encode(
                theta=alt.Theta("COUNT:Q"),
                color=alt.Color("RISK_LEVEL:N", scale=alt.Scale(domain=["HIGH RISK", "MEDIUM RISK"], range=["#ff4b4b", "#ffa500"]), title="Risk Level"),
                tooltip=["RISK_LEVEL", "COUNT"]
            ).properties(height=300)
            st.altair_chart(donut)

        with col_right:
            st.subheader("Flagged Claims by Amount (Scatter)")
            scatter = alt.Chart(df_fraud).mark_circle(size=100).encode(
                x=alt.X("PATIENT_NAME:N", title="Patient"),
                y=alt.Y("CLAIM_AMOUNT:Q", title="Claim Amount (₹)"),
                color=alt.Color("FRAUD_RISK_LEVEL:N", title="Risk"),
                size=alt.Size("CLAIM_AMOUNT:Q", legend=None),
                tooltip=["PATIENT_NAME", "DIAGNOSIS", "CLAIM_AMOUNT", "FRAUD_RISK_LEVEL"]
            ).properties(height=300)
            st.altair_chart(scatter)

        st.subheader("Flagged Claims Details")
        st.dataframe(df_fraud, hide_index=True)
    else:
        st.success("No suspicious claims detected")

with tab4:
    st.header("Duplicate Claim Detection")

    df_dup = conn.query("SELECT * FROM HEALTHCARE_DB.ANALYTICS.DUPLICATE_CLAIMS")

    if len(df_dup) > 0:
        st.warning(f"Found {len(df_dup)} duplicate claim IDs!")

        dup_bar = alt.Chart(df_dup).mark_bar(color="#ff4b4b").encode(
            x=alt.X("CLAIM_ID:N", title="Claim ID"),
            y=alt.Y("DUPLICATE_COUNT:Q", title="Occurrences"),
            tooltip=["CLAIM_ID", "DUPLICATE_COUNT"]
        ).properties(height=250)
        st.altair_chart(dup_bar)

        st.subheader("Duplicate Claim Details")
        for _, row in df_dup.iterrows():
            claim_id = row["CLAIM_ID"]
            details = conn.query(f"SELECT * FROM HEALTHCARE_DB.PROCESSED.CLAIMS_CLEAN WHERE CLAIM_ID = '{claim_id}'")
            st.write(f"**Claim ID: {claim_id}** (appears {int(row['DUPLICATE_COUNT'])} times)")
            st.dataframe(details, hide_index=True)
    else:
        st.success("No duplicate claims found")

with tab5:
    st.header("Patient Claims Summary")

    df_patients = conn.query("SELECT * FROM HEALTHCARE_DB.ANALYTICS.PATIENT_CLAIMS_SUMMARY ORDER BY TOTAL_CLAIM_AMOUNT DESC")

    col_left, col_right = st.columns(2)

    with col_left:
        st.subheader("Top Patients by Claim Amount (Bar)")
        top_patients = alt.Chart(df_patients.head(10)).mark_bar().encode(
            x=alt.X("TOTAL_CLAIM_AMOUNT:Q", title="Total Claim Amount (₹)"),
            y=alt.Y("NAME:N", sort="-x", title="Patient"),
            color=alt.Color("GENDER:N", title="Gender"),
            tooltip=["NAME", "AGE", "CITY", "TOTAL_CLAIMS", "TOTAL_CLAIM_AMOUNT"]
        ).properties(height=350)
        st.altair_chart(top_patients)

    with col_right:
        st.subheader("Claims by Gender (Pie)")
        gender_claims = df_patients.groupby("GENDER")["TOTAL_CLAIM_AMOUNT"].sum().reset_index()
        gender_pie = alt.Chart(gender_claims).mark_arc(innerRadius=50).encode(
            theta=alt.Theta("TOTAL_CLAIM_AMOUNT:Q"),
            color=alt.Color("GENDER:N", title="Gender"),
            tooltip=["GENDER", "TOTAL_CLAIM_AMOUNT"]
        ).properties(height=350)
        st.altair_chart(gender_pie)

    st.subheader("Age vs Claim Amount (Scatter)")
    scatter_age = alt.Chart(df_patients).mark_circle(size=80).encode(
        x=alt.X("AGE:Q", title="Patient Age"),
        y=alt.Y("TOTAL_CLAIM_AMOUNT:Q", title="Total Claim Amount (₹)"),
        color=alt.Color("CITY:N", title="City"),
        size=alt.Size("TOTAL_CLAIMS:Q", title="Number of Claims"),
        tooltip=["NAME", "AGE", "CITY", "TOTAL_CLAIMS", "TOTAL_CLAIM_AMOUNT"]
    ).properties(height=350)
    st.altair_chart(scatter_age)

    st.subheader("Claims by Diagnosis (Area)")
    df_diag = conn.query("SELECT * FROM HEALTHCARE_DB.ANALYTICS.CLAIMS_BY_DIAGNOSIS")
    diag_bar = alt.Chart(df_diag).mark_bar().encode(
        x=alt.X("TOTAL_AMOUNT:Q", title="Total Amount (₹)"),
        y=alt.Y("DIAGNOSIS:N", sort="-x", title="Diagnosis"),
        color=alt.Color("CLAIM_COUNT:Q", scale=alt.Scale(scheme="blues"), title="Claims"),
        tooltip=["DIAGNOSIS", "CLAIM_COUNT", "TOTAL_AMOUNT", "AVG_AMOUNT"]
    ).properties(height=400)
    st.altair_chart(diag_bar)

    st.subheader("Patient Details")
    st.dataframe(df_patients, hide_index=True)

with tab6:
    st.header("Pipeline Status")

    st.subheader("Stream Status")
    try:
        df_stream = conn.query("SELECT SYSTEM$STREAM_HAS_DATA('HEALTHCARE_DB.RAW.CLAIMS_STREAM') AS HAS_DATA")
        has_data = df_stream["HAS_DATA"].iloc[0]
        if has_data == "True":
            st.warning("Stream has unprocessed data")
        else:
            st.success("Stream is up to date - no pending changes")
    except Exception:
        st.info("Stream status unavailable")

    st.subheader("Task Status")
    try:
        df_task = conn.query("SHOW TASKS IN SCHEMA HEALTHCARE_DB.RAW")
        st.dataframe(df_task, hide_index=True)
    except Exception:
        st.info("Task information unavailable")

    st.subheader("Raw vs Processed Record Counts")
    col1, col2 = st.columns(2)
    raw_count = conn.query("SELECT COUNT(*) AS CNT FROM HEALTHCARE_DB.RAW.CLAIMS_RAW")
    processed_count = conn.query("SELECT COUNT(*) AS CNT FROM HEALTHCARE_DB.PROCESSED.CLAIMS_CLEAN")
    col1.metric("Raw Records", int(raw_count["CNT"].iloc[0]))
    col2.metric("Processed Records", int(processed_count["CNT"].iloc[0]))

    st.subheader("Time Travel Example")
    st.code("SELECT * FROM HEALTHCARE_DB.PROCESSED.CLAIMS_CLEAN AT(OFFSET => -60*5);", language="sql")
    st.caption("Query data as it was 5 minutes ago")

    st.subheader("Zero-Copy Clone")
    st.code("CREATE TABLE HEALTHCARE_DB.PROCESSED.CLAIMS_BACKUP CLONE HEALTHCARE_DB.PROCESSED.CLAIMS_CLEAN;", language="sql")
    st.caption("Create instant backup without additional storage")
