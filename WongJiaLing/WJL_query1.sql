SET LINESIZE 130
SET PAGESIZE 35

SET DEFINE OFF
SET VERIFY OFF
SET FEEDBACK OFF
SET NEWPAGE 1
SET HEADING ON
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '.,';

TTITLE LEFT 'Date: ' _DATE RIGHT 'Page ' FORMAT 99 SQL.PNO SKIP 2 -
       CENTER 'Advance Booking Window Analysis' SKIP 1 -
       CENTER 'Analysis Period: 2023 - 2025 (YTD)' SKIP 2

COLUMN "Booking Window Category"      FORMAT A28      HEADING 'Booking Window Category'
COLUMN "Total Bookings"               FORMAT A15      HEADING 'Total Bookings' JUSTIFY RIGHT
COLUMN "Booking Pct"                  FORMAT A18      HEADING 'Percentage|of Total' JUSTIFY RIGHT
COLUMN "Total Duration (Days)"        FORMAT A18      HEADING 'Total Duration|(Days)' JUSTIFY RIGHT
COLUMN "Total Revenue (RM)"           FORMAT A22      HEADING 'Total Revenue|(RM)' JUSTIFY RIGHT
COLUMN "Average Daily Rate (RM)"      FORMAT A22      HEADING 'Average Daily Rate|(RM)' JUSTIFY RIGHT

WITH
  BookingLeadTime AS (
    SELECT
      (bd.checkin_date - b.payment_date) AS LeadDays,
      fbr.BookingID,
      fbr.CalculatedBookingAmount AS RoomRevenue,
      fbr.DurationDays
    FROM FactBookingRoom fbr
    JOIN DimDate dd ON fbr.DateKey = dd.DateKey
    JOIN Booking b ON fbr.BookingID = b.booking_id
    JOIN BookingDetail bd ON fbr.BookingID = bd.booking_id AND fbr.BookingDetailID = bd.room_id
    WHERE dd.Year IN (2023, 2024, 2025) AND dd.FullDate <= SYSDATE
  ),
  AnalysisData AS (
    SELECT
      CASE
        WHEN LeadDays BETWEEN 1 AND 7 THEN 'Last-Minute (1-7 Days)'
        WHEN LeadDays BETWEEN 8 AND 30 THEN 'Short-Term (8-30 Days)'
        WHEN LeadDays BETWEEN 31 AND 90 THEN 'Standard (31-90 Days)'
        ELSE 'Long-Lead (>90 Days)'
      END AS Category,
      COUNT(BookingID) AS NumBookings,
      SUM(RoomRevenue) AS TotalRevenue,
      SUM(DurationDays) AS TotalDuration
    FROM BookingLeadTime
    GROUP BY
      CASE
        WHEN LeadDays BETWEEN 1 AND 7 THEN 'Last-Minute (1-7 Days)'
        WHEN LeadDays BETWEEN 8 AND 30 THEN 'Short-Term (8-30 Days)'
        WHEN LeadDays BETWEEN 31 AND 90 THEN 'Standard (31-90 Days)'
        ELSE 'Long-Lead (>90 Days)'
      END
  ),
  TotalOverallBookings AS (
    SELECT SUM(NumBookings) AS TotalBooks FROM AnalysisData
  )
SELECT
  ad.Category AS "Booking Window Category",
  TO_CHAR(ad.NumBookings, 'FM999,999') AS "Total Bookings",
  TO_CHAR((ad.NumBookings * 100 / tb.TotalBooks), 'FM990.0') AS "Booking Pct",
  TO_CHAR(ad.TotalDuration, 'FM999,999') AS "Total Duration (Days)",
  TO_CHAR(ad.TotalRevenue, 'FM99,999,990.00') AS "Total Revenue (RM)",
  TO_CHAR(ad.TotalRevenue / NULLIF(ad.TotalDuration, 0), 'FM99,990.00') AS "Average Daily Rate (RM)"
FROM
  AnalysisData ad,
  TotalOverallBookings tb
ORDER BY
  CASE ad.Category
    WHEN 'Last-Minute (1-7 Days)' THEN 1
    WHEN 'Short-Term (8-30 Days)' THEN 2
    WHEN 'Standard (31-90 Days)' THEN 3
    ELSE 4
  END;

CLEAR COLUMNS
TTITLE OFF
BTITLE OFF