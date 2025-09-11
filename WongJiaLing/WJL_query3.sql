SET DEFINE OFF
SET PAGESIZE 35
SET LINESIZE 130
SET VERIFY OFF
SET FEEDBACK OFF
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '.,';

TTITLE LEFT 'Date: ' _DATE RIGHT 'Page ' FORMAT FM99 SQL.PNO SKIP 2 -
       CENTER 'Room Category Performance Trend Analysis (ADR, RevPAR)' SKIP 1 -
       CENTER 'Analysis Period: 2010 - 2025 (YTD)' SKIP 2

BREAK ON "Analysis_Year" SKIP 1

COLUMN "Analysis_Year"             FORMAT 9999     HEADING 'Year'
COLUMN "Room_Type"                 FORMAT A20      HEADING 'Room Category'
COLUMN "Occupancy_Rate"            FORMAT A18      HEADING 'Room Occupancy (%)'
COLUMN "ADR"                       FORMAT A20      HEADING 'Average Daily Rate|(RM)'
COLUMN "RevPAR"                    FORMAT A22      HEADING 'Revenue per|Available Room (RM)'
COLUMN "Strategic_Insight"         FORMAT A30      HEADING 'Strategic Insight'

WITH
  DateFacts AS (
    SELECT Year, COUNT(FullDate) AS DaysInPeriod
    FROM DimDate
    WHERE Year >= 2010 AND FullDate <= SYSDATE
    GROUP BY Year
  ),
  RoomPerformance AS (
    SELECT
      dd.Year AS AnalysisYear,
      dr.RoomType,
      SUM(fbr.CalculatedBookingAmount) AS TotalRevenue,
      SUM(fbr.DurationDays) AS TotalNightsSold,
      (SELECT COUNT(*) FROM Room r WHERE r.room_type = dr.RoomType) AS NumberOfPhysicalRooms
    FROM FactBookingRoom fbr
    JOIN DimRoom dr ON fbr.RoomKey = dr.RoomKey AND dr.CurrentFlag = 'Y'
    JOIN DimDate dd ON fbr.DateKey = dd.DateKey
    WHERE dd.Year >= 2010 AND dd.FullDate <= SYSDATE
    GROUP BY dd.Year, dr.RoomType
  ),
  PerformanceMetrics AS (
    SELECT
      rp.AnalysisYear,
      rp.RoomType,
      (rp.TotalNightsSold / NULLIF(rp.NumberOfPhysicalRooms * df.DaysInPeriod, 0)) * 100 AS OccupancyRate,
      rp.TotalRevenue / NULLIF(rp.TotalNightsSold, 0) AS ADR,
      rp.TotalRevenue / NULLIF(rp.NumberOfPhysicalRooms * df.DaysInPeriod, 0) AS RevPAR
    FROM RoomPerformance rp
    JOIN DateFacts df ON rp.AnalysisYear = df.Year
  )
SELECT
  pm.AnalysisYear AS "Analysis_Year",
  pm.RoomType AS "Room_Type",
  TO_CHAR(pm.OccupancyRate, 'FM990.0') AS "Occupancy_Rate",
  TO_CHAR(pm.ADR, 'FM99,990.00') AS "ADR",
  TO_CHAR(pm.RevPAR, 'FM99,990.00') AS "RevPAR",
  CASE
    WHEN pm.RevPAR > (SELECT AVG(RevPAR) * 1.25 FROM PerformanceMetrics) AND pm.OccupancyRate > 75 THEN 'Volume & Efficiency Driver'
    WHEN pm.ADR > (SELECT AVG(ADR) * 1.5 FROM PerformanceMetrics) AND pm.OccupancyRate < 60 THEN 'High ADR, Low Occupancy'
    WHEN pm.RevPAR < (SELECT AVG(RevPAR) * 0.75 FROM PerformanceMetrics) THEN 'Low Performer - Review'
    ELSE 'Standard Performer'
  END AS "Strategic_Insight"
FROM PerformanceMetrics pm
ORDER BY pm.AnalysisYear, pm.RevPAR DESC;

CLEAR BREAKS
CLEAR COLUMNS
TTITLE OFF
BTITLE OFF