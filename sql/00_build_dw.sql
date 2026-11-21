-- duckdb dw.duckdb -c ".read sql/00_build_dw.sql

-- Step 1: Create star schema tables
.read sql/01_create_tables_dw.sql

-- Step 2: Load data into data warehouse from GCS
.read sql/02_load_schema_dw.sql

-- Step 3: Create flat mart
.read sql/03_create_flat_mart.sql

-- Step 4: Create skills mart
.read sql/04_create_skills_mart.sql

-- Step 5: Create priority mart
.read sql/05_create_priority_mart.sql

-- Step 6: Update priority mart
.read sql/06_update_priority_mart.sql

-- Step 7: Create copmany mart
-- WARNING: this is extremely CPU intensive. Make sure your laptop can handle the heat.
.read sql/07_create_company_mart.sql
