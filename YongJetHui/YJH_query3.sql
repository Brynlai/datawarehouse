SET DEFINE OFF
SET PAGESIZE 35
SET LINESIZE 130
SET VERIFY OFF
SET FEEDBACK OFF
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '.,'

TTITLE CENTER 'Long-Term Holiday Destination Driver Analysis' SKIP 1 -
       CENTER 'Analysis Period: 2010-2025' SKIP 1 -
       RIGHT 'Date: ' _DATE SKIP 1 -
       RIGHT 'Page: ' FORMAT 999 SQL.PNO SKIP 2

COLUMN "Holiday_Event"             FORMAT A32      HEADING 'Holiday / Festival Event'
COLUMN "Total_Booking_Count"       FORMAT A15      HEADING 'Total Bookings'
COLUMN "Long_Term_Avg_Spend"       FORMAT A25      HEADING 'Long-Term Avg. Spend|per Booking (RM)'
COLUMN "Spend_vs_Avg"              FORMAT A20      HEADING 'Spend vs.|Non-Holiday Avg (%)'

WITH
  AllBookings AS (
    SELECT
      dd.FestivalEvent,
      dd.IsHoliday,
      dd.Year,
      fbr.CalculatedBookingAmount
    FROM FactBookingRoom fbr
    JOIN DimDate dd ON fbr.DateKey = dd.DateKey
    WHERE dd.Year BETWEEN 2010 AND 2025
  ),
  NonHolidayAverage AS (
    SELECT AVG(CalculatedBookingAmount) AS AvgNonHolidaySpend
    FROM AllBookings
    WHERE IsHoliday = 'N'
  ),
  HolidayPerformance AS (
    SELECT
      FestivalEvent,
      AVG(CalculatedBookingAmount) AS LongTermAvgSpend,
      AVG(CASE WHEN Year IN (2023, 2024) THEN CalculatedBookingAmount END) AS RecentAvgSpend,
      COUNT(*) AS TotalBookingCount
    FROM AllBookings
    WHERE FestivalEvent IS NOT NULL
    GROUP BY FestivalEvent
  )
SELECT
  hp.FestivalEvent AS "Holiday_Event",
  TO_CHAR(hp.TotalBookingCount, 'FM9,999') AS "Total_Booking_Count",
  TO_CHAR(hp.LongTermAvgSpend, 'FM99,990.00') AS "Long_Term_Avg_Spend",
  TO_CHAR(((hp.LongTermAvgSpend / nha.AvgNonHolidaySpend) - 1) * 100, 'FMS990.0') || '%' AS "Spend_vs_Avg"
FROM HolidayPerformance hp
CROSS JOIN NonHolidayAverage nha
WHERE hp.TotalBookingCount > 50 
ORDER BY "Long_Term_Avg_Spend" DESC;

CLEAR COLUMNS; 
TTITLE OFF; 


TTITLE CENTER 'Room Demand Analysis for Top-Tier Holidays' SKIP 1 -
       CENTER 'Analysis Period: 2010-2025' SKIP 1 -
       RIGHT 'Date: ' _DATE SKIP 1 -
       RIGHT 'Page: ' FORMAT 999 SQL.PNO SKIP 2

COLUMN "Holiday_Event"             FORMAT A25      HEADING 'Top-Tier Holiday Event'
COLUMN "Room_Type"                 FORMAT A20      HEADING 'Room Type'
COLUMN "Booking_Count"             FORMAT A15      HEADING 'Booking Count|on Holiday'
COLUMN "Room_Revenue_on_Holiday"   FORMAT A25      HEADING 'Room Revenue on|Holiday (RM)'
COLUMN "Share_of_Holiday_Revenue"  FORMAT A25      HEADING 'Share of Holiday''s|Total Revenue (%)'

BREAK ON "Holiday_Event" SKIP 1

WITH
  TopTierHolidays AS (
    SELECT 'New Year''s Eve' AS Holiday FROM DUAL UNION ALL
    SELECT 'Christmas Day' FROM DUAL UNION ALL
    SELECT 'Christmas Eve' FROM DUAL UNION ALL
    SELECT 'Valentine''s Day' FROM DUAL UNION ALL
    SELECT 'Canada Day' FROM DUAL UNION ALL
    SELECT 'Independence Day (US)' FROM DUAL UNION ALL
    SELECT 'Boxing Day' FROM DUAL
  ),
  HolidayRoomBookings AS (
    SELECT
      dd.FestivalEvent,
      dr.RoomType,
      fbr.CalculatedBookingAmount,
      fbr.BookingID
    FROM FactBookingRoom fbr
    JOIN DimDate dd ON fbr.DateKey = dd.DateKey
    JOIN DimRoom dr ON fbr.RoomKey = dr.RoomKey AND dr.CurrentFlag = 'Y'
    WHERE dd.FestivalEvent IN (SELECT Holiday FROM TopTierHolidays)
      AND dd.Year BETWEEN 2010 AND 2025
  )
SELECT
  hrb.FestivalEvent AS "Holiday_Event",
  hrb.RoomType AS "Room_Type",
  TO_CHAR(COUNT(hrb.BookingID), 'FM9,999') AS "Booking_Count",
  TO_CHAR(SUM(hrb.CalculatedBookingAmount), 'FM99,999,990') AS "Room_Revenue_on_Holiday",
  TO_CHAR(SUM(hrb.CalculatedBookingAmount) * 100 / SUM(SUM(hrb.CalculatedBookingAmount)) OVER (PARTITION BY hrb.FestivalEvent), 'FM990.0') || '%' AS "Share_of_Holiday_Revenue"
FROM HolidayRoomBookings hrb
GROUP BY hrb.FestivalEvent, hrb.RoomType
ORDER BY hrb.FestivalEvent,SUM(hrb.CalculatedBookingAmount) DESC;

CLEAR COLUMNS;
CLEAR BREAKS;
TTITLE OFF;
BTITLE OFF;