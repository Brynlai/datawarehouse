-- REPORT 1 : 3.2.1 Stay Duration vs. Extra Service Spend Analysis

SET DEFINE ON
SET PAGESIZE 100
SET LINESIZE 150
SET VERIFY OFF
SET FEEDBACK OFF
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '.,';

DEFINE v_start_year = 2020
DEFINE v_end_year   = 2025

TTITLE 'Stay Duration vs. Extra Service Spend Analysis' SKIP 1 'Analysis Period: &v_start_year - &v_end_year' SKIP 2
BTITLE 'Generated on: ' &_DATE '   Page: ' FORMAT 999 SQL.PNO

COLUMN "Stay_Duration_Bucket"      FORMAT A35      HEADING 'Stay Duration Bucket'
COLUMN "Guest_Count"               FORMAT 999,999  HEADING 'Guest Count'
COLUMN "Service_Adoption_Rate"     FORMAT A20      HEADING 'Service Adoption|Rate (%)'
COLUMN "Avg_Ancillary_Spend"       FORMAT A25      HEADING 'Avg. Ancillary Spend|per Service User (RM)'

WITH
  GuestStayDuration AS (
    SELECT GuestKey, SUM(DurationDays) AS TotalDuration
    FROM FactBookingRoom fbr JOIN DimDate dd ON fbr.DateKey = dd.DateKey
    WHERE dd.Year BETWEEN &v_start_year AND &v_end_year GROUP BY GuestKey
  ),
  GuestServiceSpend AS (
    SELECT GuestKey, SUM(FacilityTotalAmount) AS TotalServiceSpend
    FROM FactFacilityBooking ffb JOIN DimDate dd ON ffb.DateKey = dd.DateKey
    WHERE dd.Year BETWEEN &v_start_year AND &v_end_year GROUP BY GuestKey
  ),
  GuestAnalysisData AS (
    SELECT
        gsd.GuestKey,
        CASE
            WHEN gsd.TotalDuration BETWEEN 1 AND 2   THEN 'Short Stay (1-2 Nights)'
            WHEN gsd.TotalDuration BETWEEN 3 AND 5   THEN 'Standard Stay (3-5 Nights)'
            WHEN gsd.TotalDuration BETWEEN 6 AND 10  THEN 'Long Stay (6-10 Nights)'
            ELSE 'Extended Stay (11+ Nights)'
        END AS Stay_Duration_Bucket,
        gss.TotalServiceSpend
    FROM GuestStayDuration gsd
    LEFT JOIN GuestServiceSpend gss ON gsd.GuestKey = gss.GuestKey
  )
SELECT
  gad.Stay_Duration_Bucket AS "Stay_Duration_Bucket",
  COUNT(DISTINCT gad.GuestKey) AS "Guest_Count",
  TO_CHAR((COUNT(gad.TotalServiceSpend) * 100.0) / COUNT(gad.GuestKey), 'FM990.0') || '%' AS "Service_Adoption_Rate",
  TO_CHAR(NVL(AVG(gad.TotalServiceSpend), 0), 'FM99,999.00') AS "Avg_Ancillary_Spend"
FROM GuestAnalysisData gad
GROUP BY gad.Stay_Duration_Bucket
ORDER BY
    CASE gad.Stay_Duration_Bucket
        WHEN 'Short Stay (1-2 Nights)'      THEN 1
        WHEN 'Standard Stay (3-5 Nights)'   THEN 2
        WHEN 'Long Stay (6-10 Nights)'      THEN 3
        WHEN 'Extended Stay (11+ Nights)'   THEN 4
    END;

CLEAR COLUMNS
CLEAR BREAKS
CLEAR COMPUTES
TTITLE OFF
BTITLE OFF
