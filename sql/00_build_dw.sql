-- Step 1: Create star schema tables
.read sql/01_create_tables_dw.sql

-- Step 2: Load data into data warehouse from GCS
.read sql/02_load_schema_dw.sql

