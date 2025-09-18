SET DEFINE OFF
SET PAGESIZE 35
SET LINESIZE 130
SET VERIFY OFF
SET FEEDBACK OFF
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '.,';

TTITLE CENTER 'Room Stay Value & Behavior Analysis (Weekend vs. Weekday)' SKIP 1 -
       CENTER 'Analysis Period: 2022 - 2024' SKIP 2 -
       LEFT 'Date: ' _DATE RIGHT 'Page ' FORMAT FM99 SQL.PNO SKIP 2

COLUMN "Room Type"                 FORMAT A12        HEADING 'Room Type'
COLUMN "Total_Booking_Count"       FORMAT 999,999    HEADING 'Total|Bookings'
COLUMN "Booking_Pct"               FORMAT 99.0       HEADING 'Booking|Percentage (%)'
COLUMN "Avg_Stay_Duration"         FORMAT 99         HEADING 'Avg Stay|Days'
COLUMN "Avg_Weekend_Stay_Value"    FORMAT 99,999.00  HEADING 'Avg Weekend|Value (RM)'
COLUMN "Avg_Weekday_Stay_Value"    FORMAT 99,999.00  HEADING 'Avg Weekday|Value (RM)'
COLUMN "Value_Index"               FORMAT 0.9        HEADING 'Value|Index'
COLUMN "Strategic_Insight"         FORMAT A32        HEADING 'Strategic Insight'

COLUMN spacer1 FORMAT A2 HEADING ''
COLUMN spacer2 FORMAT A2 HEADING ''
COLUMN spacer3 FORMAT A2 HEADING ''
COLUMN spacer4 FORMAT A2 HEADING ''
COLUMN spacer5 FORMAT A2 HEADING ''
COLUMN spacer6 FORMAT A2 HEADING ''
COLUMN spacer7 FORMAT A2 HEADING ''

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
    WHERE dd.Year IN (2022, 2023, 2024)
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
  '' AS spacer1,
  rts.TotalBookingCount AS "Total_Booking_Count",
  '' AS spacer2,
  (rts.TotalBookingCount * 100 / ot.GrandTotalBookings) AS "Booking_Pct",
  '' AS spacer3,
  ROUND(rts.AvgStayDuration, 0) AS "Avg_Stay_Duration",
  '' AS spacer4,
  rts.AvgWeekendStayValue AS "Avg_Weekend_Stay_Value",
  '' AS spacer5,
  rts.AvgWeekdayStayValue AS "Avg_Weekday_Stay_Value",
  '' AS spacer6,
  (rts.TotalBookingCount / ot.OverallAvgBookings) * ((NVL(rts.AvgWeekendStayValue, 0) + NVL(rts.AvgWeekdayStayValue, 0)) / 2 / ot.OverallAvgValue) AS "Value_Index",
  '' AS spacer7,
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
