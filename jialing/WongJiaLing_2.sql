SET DEFINE OFF
SET PAGESIZE 35
SET LINESIZE 130
SET VERIFY OFF
SET FEEDBACK OFF
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '.,';

TTITLE LEFT 'Date: ' _DATE RIGHT 'Page ' FORMAT FM99 SQL.PNO SKIP 2 -
       CENTER 'Room Stay Value & Behavior Analysis (Weekend vs. Weekday)' SKIP 1 -
       CENTER 'Analysis Period: 2023 - 2025 (YTD)' SKIP 2

COLUMN "Room Type"                 FORMAT A12      HEADING 'Room Type'
COLUMN "Total_Booking_Count"       FORMAT A10      HEADING 'Total|Bookings'
COLUMN "Booking_Pct"               FORMAT A15      HEADING 'Booking|Percentage (%)'
COLUMN "Avg_Stay_Duration"         FORMAT A10      HEADING 'Avg Stay|Days'
COLUMN "Avg_Weekend_Stay_Value"    FORMAT A15      HEADING 'Avg Weekend|Value (RM)'
COLUMN "Avg_Weekday_Stay_Value"    FORMAT A15      HEADING 'Avg Weekday|Value (RM)'
COLUMN "Value_Index"               FORMAT A9       HEADING 'Value|Index'
COLUMN "Strategic_Insight"         FORMAT A36      HEADING 'Strategic Insight'

WITH
  BookingStats AS (
    SELECT
      dr.RoomType,
      fbr.BookingID,
      fbr.DurationDays,
      fbr.CalculatedBookingAmount,
      CASE WHEN dd.IsWeekend = 'Y' THEN 'Weekend' ELSE 'Weekday' END AS StayType
    FROM FactBookingRoom fbr
    JOIN DimRoom dr ON fbr.RoomKey = dr.RoomKey AND dr.CurrentFlag = 'Y'
    JOIN DimDate dd ON fbr.DateKey = dd.DateKey
    WHERE dd.Year IN (2023, 2024, 2025) AND dd.FullDate <= SYSDATE
  ),
  RoomTypeSummary AS (
    SELECT
      RoomType,
      COUNT(DISTINCT BookingID) AS TotalBookingCount,
      AVG(DurationDays) AS AvgStayDuration,
      AVG(CASE WHEN StayType = 'Weekend' THEN CalculatedBookingAmount END) AS AvgWeekendStayValue,
      AVG(CASE WHEN StayType = 'Weekday' THEN CalculatedBookingAmount END) AS AvgWeekdayStayValue
    FROM BookingStats
    GROUP BY RoomType
  ),
  OverallTotals AS (
    SELECT
      SUM(TotalBookingCount) AS GrandTotalBookings,
      AVG(TotalBookingCount) AS OverallAvgBookings,
      AVG(NVL(AvgWeekendStayValue, 0) + NVL(AvgWeekdayStayValue, 0)) / 2 AS OverallAvgValue
    FROM RoomTypeSummary
  )
SELECT
  rts.RoomType AS "Room Type",
  TO_CHAR(rts.TotalBookingCount, 'FM99,999') AS "Total_Booking_Count",
  TO_CHAR(rts.TotalBookingCount * 100 / ot.GrandTotalBookings, 'FM99.0') AS "Booking_Pct",
  TO_CHAR(ROUND(rts.AvgStayDuration, 0), 'FM99') AS "Avg_Stay_Duration",
  TO_CHAR(rts.AvgWeekendStayValue, 'FM9,999.00') AS "Avg_Weekend_Stay_Value",
  TO_CHAR(rts.AvgWeekdayStayValue, 'FM9,999.00') AS "Avg_Weekday_Stay_Value",
  TO_CHAR((rts.TotalBookingCount / ot.OverallAvgBookings) * ((NVL(rts.AvgWeekendStayValue, 0) + NVL(rts.AvgWeekdayStayValue, 0)) / 2 / ot.OverallAvgValue), 'FM0.9') AS "Value_Index",
  CASE
    WHEN rts.TotalBookingCount > ot.OverallAvgBookings * 1.5 THEN 'Volume Driver: High popularity'
    ELSE 'Niche / Balanced Appeal'
  END AS "Strategic_Insight"
FROM RoomTypeSummary rts
CROSS JOIN OverallTotals ot
ORDER BY rts.TotalBookingCount DESC;

CLEAR COLUMNS
TTITLE OFF
BTITLE OFF