-- Create flat mart table

DROP SCHEMA IF EXISTS flat_mart CASCADE;
CREATE SCHEMA flat_mart;

SELECT CONCAT(strftime(CURRENT_TIMESTAMP, '%Y-%m-%d %H:%M:%S'), ' [INFO]: Creating flat_mart.job_postings table from data warehouse') AS info;

CREATE OR REPLACE TABLE flat_mart.job_postings AS
SELECT
    -- Job postings fields
    jpf.job_id,
    jpf.company_id,
    jpf.job_title_short,
    jpf.job_title,
    jpf.job_location,
    jpf.job_via,
    jpf.job_schedule_type,
    jpf.job_work_from_home,
    jpf.search_location,
    jpf.job_posted_date,
    jpf.job_no_degree_mention,
    jpf.job_health_insurance,
    jpf.job_country,
    jpf.salary_rate,
    jpf.salary_year_avg,
    jpf.salary_hour_avg,
    -- Company dimension fields
    cd.company_id,
    cd.name AS company_name,
    ARRAY_AGG(
        STRUCT_PACK(
            type := sd.type,
            name := sd.skills
        )
    ) AS skills_and_types
FROM
    job_postings_fact AS jpf
    LEFT JOIN company_dim AS cd
        ON jpf.company_id = cd.company_id
    LEFT JOIN skills_job_dim AS sjd
        ON jpf.job_id = sjd.job_id
    LEFT JOIN skills_dim AS sd
        ON sjd.skill_id = sd.skill_id
GROUP BY ALL;

-- Data Validation

SELECT 'flat_mart.job_postings' AS table_name, COUNT(*) AS record_count FROM flat_mart.job_postings;

SELECT CONCAT(strftime(CURRENT_TIMESTAMP, '%Y-%m-%d %H:%M:%S'), ' [INFO]: flat_mart.job_postings sample') AS info;
SELECT * FROM flat_mart.job_postings LIMIT 5;
