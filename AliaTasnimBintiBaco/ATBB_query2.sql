-- REPORT 2: 3.2.2 Seasonal Revenue Analysis for Extra Services (2023-2024)

SET DEFINE ON
SET PAGESIZE 100
SET LINESIZE 150
SET VERIFY OFF
SET FEEDBACK OFF
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '.,';

DEFINE v_start_year = 2023
DEFINE v_end_year   = 2024

TTITLE 'Seasonal Revenue Analysis for Extra Services' SKIP 1 'Analysis Period: &v_start_year - &v_end_year' SKIP 2
BTITLE 'Generated on: ' &_DATE '   Page: ' FORMAT 999 SQL.PNO

COLUMN "Season"         FORMAT A25 HEADING 'Season'
COLUMN "Recreation"     FORMAT 999,999,990.00 HEADING 'Recreation'
COLUMN "Transport"      FORMAT 999,999,990.00 HEADING 'Transport'
COLUMN "Convenience"    FORMAT 999,999,990.00 HEADING 'Convenience'
COLUMN "Wellness"       FORMAT 999,999,990.00 HEADING 'Wellness'
COLUMN "Dining"         FORMAT 999,999,990.00 HEADING 'Dining'
COLUMN "Business"       FORMAT 999,999,990.00 HEADING 'Business'
COLUMN "Total_Revenue"  FORMAT 999,999,990.00 HEADING 'Total Revenue'

WITH
  SeasonalData AS (
    SELECT
        CASE
            WHEN TO_CHAR(dd.FullDate, 'MM') IN ('12', '01', '02') THEN 'Peak Season (Dec-Feb)'
            WHEN TO_CHAR(dd.FullDate, 'MM') IN ('03', '04', '05') THEN 'Spring Season (Mar-May)'
            WHEN TO_CHAR(dd.FullDate, 'MM') IN ('06', '07', '08') THEN 'Holiday Season (Jun-Aug)'
            ELSE 'Low Season (Sep-Nov)'
        END AS Season,
        df.FacilityType AS ServiceType,
        ffb.FacilityTotalAmount AS Revenue
    FROM FactFacilityBooking ffb
    JOIN DimDate dd ON ffb.DateKey = dd.DateKey
    JOIN DimFacility df ON ffb.FacilityKey = df.FacilityKey
    WHERE dd.Year BETWEEN &v_start_year AND &v_end_year
  )
SELECT
    Season AS "Season",
    NVL(Recreation, 0)  AS "Recreation",
    NVL(Transport, 0)   AS "Transport",
    NVL(Convenience, 0) AS "Convenience",
    NVL(Wellness, 0)    AS "Wellness",
    NVL(Dining, 0)      AS "Dining",
    NVL(Business, 0)    AS "Business",
    (NVL(Recreation, 0) + NVL(Transport, 0) + NVL(Convenience, 0) + NVL(Wellness, 0) + NVL(Dining, 0) + NVL(Business, 0)) AS "Total_Revenue"
FROM SeasonalData
PIVOT (
    SUM(Revenue)
    FOR ServiceType IN (
        'Recreation'  AS Recreation,
        'Transport'   AS Transport,
        'Convenience' AS Convenience,
        'Wellness'    AS Wellness,
        'Dining'      AS Dining,
        'Business'    AS Business
    )
)
ORDER BY
    CASE Season
        WHEN 'Peak Season (Dec-Feb)'    THEN 1
        WHEN 'Spring Season (Mar-May)'  THEN 2
        WHEN 'Holiday Season (Jun-Aug)' THEN 3
        WHEN 'Low Season (Sep-Nov)'     THEN 4
    END;

CLEAR COLUMNS
TTITLE OFF
BTITLE OFF

