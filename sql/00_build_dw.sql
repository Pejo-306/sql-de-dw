-- duckdb dw.duckdb -c ".read sql/00_build_dw.sql

-- Step 1: Create star schema tables
.read sql/01_create_tables_dw.sql

-- Step 2: Load data into data warehouse from GCS
.read sql/02_load_schema_dw.sql

-- Step 3: Create flat mart
.read sql/03_create_flat_mart.sql

