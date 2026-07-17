This is a comprehensive update to your **README.md**. It is now tailored for **Apache Superset**, including a technical deployment guide for the Docker container and instructions on how to import the provided database backups and dashboard assets.

---

# 📊 Superstore Strategic BI: Industrial Performance Analysis

This project is a high-level **Business Intelligence (BI) Lifecycle** implementation using the Global Superstore dataset. It moves beyond basic charts into advanced diagnostic analytics, including RFM segmentation, basket analysis, and supply chain optimization.

## 🚀 Project Overview
The goal of this analysis is to identify "Value Leakage" and growth opportunities for the Superstore. By normalizing the data into a **Star Schema** and deploying **Apache Superset** as the visualization layer, we provide stakeholders with a scalable, interactive platform for data-driven decision-making.

---

## 📈 The Analysis (Business Insights)

The project delivers 10 industrial-standard analyses, implemented via **SQL Views** and visualized in Superset:

### 1. Executive Performance
*   **Executive Sales Overview:** YoY Growth tracks and high-level health checks.
*   **Profit Margin Analysis:** Identification of loss-leading products and "Value Leakage."
*   **Regional Heatmaps:** Geographic identification of inefficient operations.

### 2. Customer Intelligence
*   **RFM Segmentation:** Grouping customers into "Champions," "Loyal," and "At-Risk" based on Recency, Frequency, and Monetary scores.
*   **Customer Lifetime Value (CLV):** Predicting long-term worth by segment (Consumer vs. Corporate).

### 3. Strategy & Operations
*   **Discount Impact Study:** Statistical correlation between discount levels and net profit.
*   **Shipping & Logistics:** Fulfillment gap analysis against a 4-day industrial standard.
*   **Market Basket Analysis:** Identifying product co-occurrence to drive cross-selling and bundling.
*   **Pareto (80/20) Analysis:** Finding the 20% of products driving 80% of total revenue.

---

## 🛠 Tech Stack
*   **Database:** MS SQL Server (Primary Data Warehouse)
*   **ETL:** Python (Pandas & SQLAlchemy)
*   **BI Platform:** Apache Superset (Deployed via Docker)
*   **Infrastructure:** Docker Compose (PostgreSQL for metadata, Redis for caching, Celery for async tasks)

---

## ⚙️ Setup & Installation Guide

Follow these steps to replicate the environment and view the reports.

### 1. Prerequisites
*   Docker & Docker Compose installed.
*   MS SQL Server (local or remote) to host the source data.
*   The `SuperStoreOrder_Backup.bak` file (included in the `backup/` folder).

### 2. Database Restoration (Data Warehouse)
1.  Open **SQL Server Management Studio (SSMS)**.
2.  Right-click "Databases" -> **Restore Database**.
3.  Select the provided `.bak` file to restore the `AmingoStore` database.
4.  Run the `sqlscript.txt` provided in this repository to generate the **Star Schema** and the **10 Business Views**.

### 3. Deploying Apache Superset
The visualization layer runs in a containerized environment.

1.  Navigate to the project root directory.
2.  Build and start the containers:
    ```bash
    docker-compose up -d --build
    ```
3.  The `superset-init.sh` script will automatically:
    *   Create an admin user (`admin`/`admin`).
    *   Initialize the metadata database.
    *   Set up roles and permissions.
4.  Access the UI at: `http://localhost:8088`

### 4. Connecting Data & Importing Reports
1.  **Database Connection:** 
    *   Inside Superset, go to **Settings -> Database Connections**.
    *   Add a new MS SQL Server connection using the URI format:
        `mssql+pyodbc://<user>:<password>@<host_ip>:1433/AmingoStore?driver=ODBC+Driver+17+for+SQL+Server`
2.  **Importing Dashboards:**
    *   Go to **Dashboards**.
    *   Click the **Import Dashboard** (Arrow icon) in the top right.
    *   Upload the provided `Superstore_Dashboard_Export.zip` file.
    *   This will automatically import all charts, datasets, and layout configurations.

---

## 📂 File Structure
```text
├── config/
│   ├── superset_config.py   # Advanced Superset & Redis configuration
│   └── superset-init.sh     # Automation script for first-time setup
├── backup/
│   └── AmingoStore.bak      # MS SQL Server Database Backup
├── scripts/
│   ├── data_load.py         # Python ETL script
│   └── warehouse_logic.sql  # SQL Star Schema & Views
├── docker-compose.yml       # Orchestration for Superset, Postgres, Redis
└── Dockerfile               # Custom Superset build with SQL drivers
```

---

## 💡 Key Findings & Recommendations
*   **Operational:** Reduce "Standard Class" shipping in the East Region; fulfillment is lagging by 1.8 days vs. benchmark.
*   **Marketing:** Target the "At-Risk" RFM segment with a 10% discount on "Technology" products (high-margin category).
*   **Financial:** Cap discounts at 20%. Data shows that discounts >30% in the "Furniture" category result in a 95% probability of negative profit.

---
*Developed as a Strategic BI Capstone Project.*
