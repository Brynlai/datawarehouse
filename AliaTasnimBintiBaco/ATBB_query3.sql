-- REPORT 3: 3.2.3 Seasonal Top Contributor Analysis (Service-Level Drill-Down)
SET DEFINE ON
SET PAGESIZE 35
SET LINESIZE 130
SET VERIFY OFF
SET FEEDBACK OFF
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '.,';

DEFINE v_start_year = 2022
DEFINE v_end_year   = 2024

TTITLE CENTER 'Seasonal Top Contributor Analysis (Service-Level Drill-Down)' SKIP 1 -
CENTER 'Analysis Period: &v_start_year - &v_end_year' SKIP 2 -
LEFT 'Report Generated on: ' _DATE COL 115 'Page: ' FORMAT 999 SQL.PNO SKIP 2

COLUMN "Season"           FORMAT A25 HEADING 'Season'
COLUMN "Service_Name"     FORMAT A30 HEADING 'Service Name'
COLUMN "Seasonal_Revenue" FORMAT A22 HEADING 'Seasonal Revenue (RM)'
COLUMN "Pct_Contribution" FORMAT A15 HEADING '% of Total'
COLUMN "Cumulative_Pct"   FORMAT A20 HEADING 'Cumulative %'

BREAK ON "Season" SKIP 1

WITH
  SeasonalServiceRevenue AS (
    SELECT
        CASE
            WHEN TO_CHAR(dd.FullDate, 'MM') IN ('12', '01', '02') THEN 'Peak Season (Dec-Feb)'
            WHEN TO_CHAR(dd.FullDate, 'MM') IN ('03', '04', '05') THEN 'Spring Season (Mar-May)'
            WHEN TO_CHAR(dd.FullDate, 'MM') IN ('06', '07', '08') THEN 'Holiday Season (Jun-Aug)'
            ELSE 'Low Season (Sep-Nov)'
        END AS Season,
        df.FacilityName AS Service_Name,
        SUM(ffb.FacilityTotalAmount) AS TotalRevenue
    FROM FactFacilityBooking ffb
    JOIN DimDate dd ON ffb.DateKey = dd.DateKey
    JOIN DimFacility df ON ffb.FacilityKey = df.FacilityKey
    WHERE dd.Year BETWEEN &v_start_year AND &v_end_year
    GROUP BY
        CASE
            WHEN TO_CHAR(dd.FullDate, 'MM') IN ('12', '01', '02') THEN 'Peak Season (Dec-Feb)'
            WHEN TO_CHAR(dd.FullDate, 'MM') IN ('03', '04', '05') THEN 'Spring Season (Mar-May)'
            WHEN TO_CHAR(dd.FullDate, 'MM') IN ('06', '07', '08') THEN 'Holiday Season (Jun-Aug)'
            ELSE 'Low Season (Sep-Nov)'
        END, df.FacilityName
  ),
  ContributionAnalysis AS (
    SELECT
      Season,
      Service_Name,
      TotalRevenue,
      (TotalRevenue * 100) / SUM(TotalRevenue) OVER (PARTITION BY Season) AS Pct_Contribution,
      (SUM(TotalRevenue) OVER (PARTITION BY Season ORDER BY TotalRevenue DESC) * 100) /
       SUM(TotalRevenue) OVER (PARTITION BY Season) AS Cumulative_Pct
    FROM SeasonalServiceRevenue
  )
SELECT
  Season AS "Season",
  Service_Name AS "Service_Name",
  LPAD(TO_CHAR(TotalRevenue, 'FM999,999,990.00'), 22) AS "Seasonal_Revenue",
  LPAD(TO_CHAR(Pct_Contribution, 'FM990.0') || '%', 15) AS "Pct_Contribution",
  LPAD(TO_CHAR(Cumulative_Pct, 'FM990.0') || '%', 20) AS "Cumulative_Pct"
FROM ContributionAnalysis
ORDER BY
    CASE Season
        WHEN 'Peak Season (Dec-Feb)'    THEN 1
        WHEN 'Spring Season (Mar-May)'  THEN 2
        WHEN 'Holiday Season (Jun-Aug)' THEN 3
        WHEN 'Low Season (Sep-Nov)'     THEN 4
    END, TotalRevenue DESC;

CLEAR COLUMNS
CLEAR BREAKS
TTITLE OFF
BTITLE OFF
