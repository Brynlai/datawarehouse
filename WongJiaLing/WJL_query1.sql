SET LINESIZE 130
SET PAGESIZE 35

SET DEFINE OFF
SET VERIFY OFF
SET FEEDBACK OFF
SET NEWPAGE 1
SET HEADING ON
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '.,';

TTITLE CENTER 'Advance Booking Window Analysis' SKIP 1 -
       CENTER 'Analysis Period: 2022 - 2024' SKIP 2 -
       LEFT 'Date: ' _DATE RIGHT 'Page ' FORMAT 99 SQL.PNO SKIP 2

COLUMN "Booking Window Category"      FORMAT A28           HEADING 'Booking Window Category'
COLUMN "Total Bookings"               FORMAT 999,999       HEADING 'Total Bookings'
COLUMN "Booking Pct"                  FORMAT 990.0         HEADING 'Percentage of|Total (%)'
COLUMN "Total Duration (Days)"        FORMAT 9,999,999     HEADING 'Total Duration|(Days)'
COLUMN "Total Revenue (RM)"           FORMAT 99,999,990.00 HEADING 'Total Revenue|(RM)'
COLUMN "Average Daily Rate (RM)"      FORMAT 99,990.00     HEADING 'Average Daily Rate|(RM)'

COLUMN spacer1 FORMAT A2 HEADING ''
COLUMN spacer2 FORMAT A2 HEADING ''
COLUMN spacer3 FORMAT A2 HEADING ''
COLUMN spacer4 FORMAT A2 HEADING ''
COLUMN spacer5 FORMAT A2 HEADING ''


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
    WHERE dd.Year IN (2022, 2023, 2024)
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
  '' AS spacer1,
  ad.NumBookings AS "Total Bookings",
  '' AS spacer2,
  (ad.NumBookings * 100 / tb.TotalBooks) AS "Booking Pct",
  '' AS spacer3,
  ad.TotalDuration AS "Total Duration (Days)",
  '' AS spacer4,
  ad.TotalRevenue AS "Total Revenue (RM)",
  '' AS spacer5,
  ad.TotalRevenue / NULLIF(ad.TotalDuration, 0) AS "Average Daily Rate (RM)"
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
