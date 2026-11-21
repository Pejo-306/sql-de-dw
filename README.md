# Data Warehouse for Job Market Data

An end-to-end data engineering pipeline that transforms raw CSV files from Google Cloud Storage into a normalized star schema data warehouse, then builds analytical data marts.

![Data Warehouse Project Overview](./assets/01_dw_pipeline.png)

As part of my 2026 search for a senior engineering role, I took on [Luke Barousse's SQL for Data Engineering Course](https://lukeb.co/sql-de). My goals are to improve my skills on data engineering, data warehousing, and data modeling with job market data.

You can check out [Luke's Free SQL for Data Engineering Course on YouTube](https://www.youtube.com/watch?v=UjhFbq4uU2Y). The data analyzed in this query is for remote data engineering job postings from 2023 - Sep 2026, hailing from [datanerd.tech](https://datanerd.tech).

## Summary

- **Project scope:** Built a simple, complete ETL pipeline from raw CSVs in GCS buckets to star schema warehouse to analytical marts
- **Data modeling:** Desinged central star schema with fact tables, dimensions, and bridge tables for many-to-many relationships. Designed analytical marts with star and snowflake schema.
- **SQL complexity:** Used DDL to create tables & schemas, DML to load & merge data, DQL for data validation. Includes advanced self-join SQL queries to generate numeric, unique, deterministic surrogate key IDs.
- **Outcomes:** Implemented end-to-end ETL as a simple, idempotent [SQL script](./sql/00_build_dw.sql). Builds and loads a data warehouse, ready for analytical queries on recent job market data.

```md
.
├── README.md                           # You are here
└── sql
    ├── 00_build_dw.sql                 # ETL pipeline as a script
    ├── 01_create_tables_dw.sql         # Create data warehouse tables
    ├── 02_load_schema_dw.sql           # Load data from CSVs into DW
    ├── 03_create_flat_mart.sql         # Build denormalized flat fact mart
    ├── 04_create_skills_mart.sql       # Build time-series skill demand mart
    ├── 05_create_priority_mart.sql     # Build priority roles mart and snapshot
    ├── 06_update_priority_mart.sql     # Incremental merge into priority roles mart
    └── 07_create_company_mart.sql      # Build company hiring trends mart
```

## Overview

Raw job posting data lives in Google Cloud Storage as flat CSV files, not structured for analytical queries. Data analysts need to answer analytical queries like:
- *Which skills are most in-demand over time?*
- *What are hiring trends by company and location?*
- *How do salary patterns vary by role and skill?*

This project builds a central data warehouse using star schema design. It loads data from GCS, remodels it into a star schema pattern, then produces specialized data marts with pre-aggregated data for specific business use cases.

## Tech Stack

- SQL
- [DuckDB](https://duckdb.org): OLAP SQL engine
- [MotherDuck](https://motherduck.com): Cloud-based data warehouse
- [Google Cloud Storage](https://cloud.google.com/storage): GCP's object storage solution

## Setup

Make sure you have DuckDB and DuckDB CLI installed locally. For MotherDuck deployment, also create an account (free tier should be enough).

For local DuckDB deployment, run from project root:

```bash
duckdb dw.duckdb -c ".read sql/00_build_dw.sql"
```

For MotherDuck deployment:
1. Create a database named `dw_marts` (or something else) via `duckdb` CLI
2. Run from project root:

```bash
duckdb md:dw_marts -c ".read sql/00_build_dw.sql"
```

> [!WARNING]
> Building the company mart is computationally intensive, even on modern MacBooks (I'm with an M5 Pro). That's why the company mart build is intentionally commented out in [`sql/00_build_dw.sql`](./sql/00_build_dw.sql). If your laptop or MotherDuck limits can handle it, edit the file and uncomment the final 7th step. You have been warned.

Refer to [Luke Barousse's free YouTube course](https://www.youtube.com/watch?v=UjhFbq4uU2Y&t=45156s).

## Pipeline Architecture

![Pipeline Architecture](./assets/01_dw_pipeline.png)

The pipeline transforms job posting CSVs from Google Cloud Storage into a normalized star schema, then builds specialized analytical data marts. BI tools (Excel, Power BI, Tableau, Python) consume from both the warehouse and marts.

### Data Warehouse

The data warehouse implements a star schema with facts on job postings and dimensions on skills and companies hiring.

![Data Warehouse Star Schema](./assets/02_dw_star_schema.png)

- **Tables:**
    * `job_postings_fact` - Facts about job postings
    * `company_dim` - Company information linked to job postings
    * `skills_dim` - Skills catalog with skill names and types
    * `skills_job_dim` - Bridge between associated job postings and skills (resolves many-to-many relationship)
- **SQL Files:**
    * [`sql/01_create_tables_dw.sql`](./sql/01_create_tables_dw.sql) - Defines star schema with 4 core tables
    * [`sql/02_load_schema_dw.sql`](./sql/02_load_schema_dw.sql) - Extracts CSVs from GCS and loads into warehouse tables
- **Purpose:** Star schema serving as single source of truth for analytical queries
- **Grain:** One row per job posting in the fact table (`job_postings_fact`)

### Flat Mart

Denormalized table with all dimensions joined for ad-hoc queries.

![Flat Mart Schema](./assets/03_flat_mart_schema.png)

- **Tables:**
    * `job_postings` - Denormalized facts about job postings
- **SQL Files:**
    * [`sql/03_create_flat_mart.sql`](./sql/03_create_flat_mart.sql) - Builds denormalized table with all dimensions joined
- **Purpose:** Denormalized table for quick ad-hoc queries
- **Grain:** One row per job posting with all dimensions joined

### Skills Mart

Time-series skill demand analysis with additive measures.

![Skills Mart Schema](./assets/04_skills_mart_schema.png)

- **Tables:**
    * `fact_skill_demand_monthly` - Monthly demand data for each job title
    * `dim_date_month` - Enriched calendar months
    * `dim_skill` - Skills catalog with skill names and types
- **SQL Files:**
    * [`sql/04_create_skills_mart.sql`](./sql/04_create_skills_mart.sql) - Builds time-series skill demand mart
- **Purpose:** Time-series analysis of skill demand over time with additive meaures
- **Grain:** One row per `skill_id + month_start_date + job_title_short`
- **Key Features:** All measures are additive (counts/sum) for safe re-aggregation

### Priority Mart

Priority role tracking with incremental updates using MERGE operations.

![Priority Mart Schema](./assets/05_priority_mart_schema.png)

- **Tables:**
    * `priority_jobs_snapshot` - Incrementally updated snapshot of priority job postings
    * `priority_roles` - Frequently updated business-defined priority roles
    * `job_postings_fact` (from Data Warehouse) - Facts about job postings
    * `company_dim` (from Data Warehouse) - Company information linked to job postings
- **SQL Files:**
    * [`sql/05_create_priority_mart.sql`](./sql/05_create_priority_mart.sql) - Initial build of priority roles and jobs snapshot
    * [`sql/06_update_priority_mart.sql`](./sql/06_update_priority_mart.sql) - Incremental update with upsert
- **Purpose:** Track priority roles and job snapshots with incremental update capabilities
- **Grain:** One row per job posting with priority role assignment
- **Key Features:** Incrementally updated with `MERGE` statement

### Company Mart

Company hiring trends by role, location, and month.

![Company Mart Schema](./assets/06_company_mart_schema.png)

- **Tables:**
    * `fact_company_hiring_monthly` - Hiring measures about companies hiring
    * `dim_date_month` - Enriched calendar months
    * `dim_company` - Company information linked to job postings
    * `dim_location` - Associates specific locations in job postings to countries
    * `bridge_company_location` - M2M bridge between companies and locations they are hiring in
    * `dim_job_title_short` - Distinct categorical job titles, derived from job titles in postings
    * `dim_job_title` - Specific job titles in job postings
    * `bridge_job_title` - M2M bridge between specific job titles and derived categorical job titles
- **SQL Files:**
    * [`sql/07_create_company_mart.sql`](./sql/07_create_company_mart.sql) - Build company hiring trends mart
- **Purpose:** Analyze company hiring trends by role, location, month
- **Grain:** One row per `company_id + job_title_short_id + location_id + month_start_date`
- **Key Features:** Surrogate key generation via advanced SQL self-join. Snowflake schema with bridge tables for many-to-many relationships.

## Skills Demonstrated

- **ETL Pipeline Development:** Load raw CSV data from GCS into DuckDB into star schema tables. Idempotently orchestrate ETL operations.
- **Data Modeling:** Design star schema data warehouse and marts with fact and dimension tables. Use bridge tables to resolve many-to-many relationships, properly define fact table granularity, generate deterministic, sequential surrogate keys with self-joins.
- **Advanced SQL Techniques:** DDL & DML operations between multiple schemas and tables. Incremental upsert updates with `MERGE` statements. Convert boolean flags into numeric values and aggregate shares. Use string, array, struct, date functions.
- **Data Quality Practices:** Verify successful table creation and load queries at each pipeline step. Separate schemas for separate marts (logical separation). Proper data type definitions.

## Credits

- [Luke Barousse](https://www.lukebarousse.com) for his [SQL for Data Engineering Course](https://www.youtube.com/watch?v=UjhFbq4uU2Y)

## License

This project is distributed under the [MIT license](LICENSE).

