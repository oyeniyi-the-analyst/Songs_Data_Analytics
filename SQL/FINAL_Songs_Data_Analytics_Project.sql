-- ==================================================================
-- Project: DBIN Songs Data ETL (Extract, Transform, Load) & Analysis
-- Author : Oyeniyi Akinyemi
-- Date   : 2026-03-09
-- Description:
--   PostgreSQL workflow for songs dataset:
--   1) Staging table for raw import
--   2) Data validation & cleaning
--   3) Production table with strict constraints
--   4) Analytics queries
--   5) Export cleaned data for reporting
-- ===================================================================

-- ==================================================
-- 1. Drop existing tables (staging and production)
-- ==================================================

DROP TABLE IF EXISTS staging_dbin_songs_data_v2_tb CASCADE;
DROP TABLE IF EXISTS dbin_songs_data_v2_prod_tb CASCADE;

-- =============================================
-- 2. Create staging table (raw, NULL-tolerant)
-- =============================================
CREATE TABLE staging_dbin_songs_data_v2_tb
(
    song_id        INT NOT NULL,
    title          TEXT,
    artist         TEXT,
    album          TEXT,
    year_released  INT,
    duration       NUMERIC(10,2),
    tempo          NUMERIC(10,2),
    loudness       NUMERIC(10,2)
);

-- ================================
-- 3. Load CSV into staging
-- ================================
COPY staging_dbin_songs_data_v2_tb
FROM 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/PERSONAL PROJECT/dbin_songs_data_v2.csv'
DELIMITER ','
CSV HEADER;

-- Quick check
SELECT COUNT(*) AS total_rows, COUNT(title) AS non_null_titles
FROM staging_dbin_songs_data_v2_tb;

-- ================================
-- 4. Data Cleaning & Validation
-- ================================
START TRANSACTION;

-- 4.1 Remove rows with missing mandatory fields
DELETE FROM staging_dbin_songs_data_v2_tb
WHERE title IS NULL OR artist IS NULL;

-- 4.2 Remove rows with invalid years
DELETE FROM staging_dbin_songs_data_v2_tb
WHERE year_released <= 0 OR year_released IS NULL;

-- 4.3 Remove rows with invalid tempos
DELETE FROM staging_dbin_songs_data_v2_tb
WHERE tempo <= 0 OR tempo IS NULL;

-- 4.4 Remove rows with invalid loudness
DELETE FROM staging_dbin_songs_data_v2_tb
WHERE loudness >= 0 OR loudness IS NULL;

COMMIT;

-- Verify cleaning
SELECT COUNT(*) AS remaining_rows,
       MIN(year_released) AS min_year,
       MAX(year_released) AS max_year,
       MIN(tempo) AS min_tempo,
       MAX(tempo) AS max_tempo,
       MIN(loudness) AS min_loudness,
       MAX(loudness) AS max_loudness
FROM staging_dbin_songs_data_v2_tb;

-- ===============================================
-- 5. Create production table (strict constraints)
-- ===============================================
CREATE TABLE dbin_songs_data_v2_prod_tb
(
    song_id        INT PRIMARY KEY,
    title          TEXT NOT NULL,
    artist         TEXT NOT NULL,
    album          TEXT,
    year_released  INT NOT NULL CHECK (year_released > 0),
    duration       NUMERIC(6,2) CHECK (duration >= 0),
    tempo          NUMERIC(5,2) NOT NULL CHECK (tempo > 0),
    loudness       NUMERIC(5,2) NOT NULL CHECK (loudness < 0)
);

CREATE INDEX idx_year_released ON dbin_songs_data_v2_prod_tb(year_released);

-- ==============================================
-- 6. Insert cleaned data into production table
-- ==============================================
INSERT INTO dbin_songs_data_v2_prod_tb(song_id, title, artist, album, year_released, duration, tempo, loudness)
SELECT song_id, title, artist, album, year_released, duration, tempo, loudness
FROM staging_dbin_songs_data_v2_tb;

-- ================================
-- 7. Data Analysis Queries
-- ================================
-- Number of songs per year
SELECT year_released, COUNT(song_id) AS total_songs
FROM dbin_songs_data_v2_prod_tb
GROUP BY year_released
ORDER BY total_songs DESC;

-- Average tempo per year
SELECT year_released, ROUND(AVG(tempo),2) AS avg_tempo
FROM dbin_songs_data_v2_prod_tb
GROUP BY year_released
ORDER BY avg_tempo DESC;

-- Loudness trend over time
SELECT year_released, ROUND(AVG(loudness),2) AS avg_loudness
FROM dbin_songs_data_v2_prod_tb
GROUP BY year_released
ORDER BY year_released;

-- Extract specific song records
SELECT song_id, artist, album, title, year_released, duration, loudness, tempo
FROM dbin_songs_data_v2_prod_tb
WHERE song_id IN (1632,1184,385,352,8573,1676,4174,681,3083,3289);

-- ================================
-- 8. Export Clean Data
-- ================================
COPY (
    SELECT song_id, title, artist, album, year_released, duration, tempo, loudness
    FROM dbin_songs_data_v2_prod_tb
)
TO 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/PERSONAL PROJECT/cleaned_dbin_songs_data_v2_prod.csv'
DELIMITER ','
CSV HEADER;

-- ==================
-- 9. Create Graphs
-- ==================

-- The exported CSV can be opened in Microsoft Excel or Microsoft Power BI
-- to generate graphs such as:

-- Graph 1 – Songs Released Per Year

-- Chart Type: Bar Chart

-- X-axis: year_released
-- Y-axis: number of songs

-- Graph 2 – Average Tempo Per Year

-- Chart Type: Line Chart

-- X-axis: year_released
-- Y-axis: average tempo

-- Graph 3 – Loudness Trend Over Time

-- Chart Type: Line Chart

-- X-axis: year_released
-- Y-axis: average loudness


-- ==================
-- 9.0 Notes
-- ==================
-- 1) Staging table is raw, allows NULLs for safe import.
-- 2) Data cleaning ensures only valid records move to production.
-- 3) Production table enforces NOT NULLs, primary key, and constraints.
-- 4) Index improves analytics performance.
-- 5) Exported CSV is ready for Excel or Power BI visualization.