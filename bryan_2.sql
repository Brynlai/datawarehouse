-- Report 2: Quarterly Performance Deep Dive

-- Setup the page and title for the report
SET PAGESIZE 70
SET LINESIZE 150
TTITLE CENTER 'Hotel Analytics Inc.' SKIP 1 CENTER 'Quarterly Performance Deep Dive' SKIP 2
BTITLE CENTER 'Report Generated on: ' _DATE

-- Define the column formats and headings
COLUMN "Year"           FORMAT 9999 HEADING 'Year'
COLUMN "Qtr"            FORMAT A4   HEADING 'Qtr'
COLUMN "Qtr Rank"       FORMAT A8   HEADING 'Rank'
COLUMN "Room Revenue"   FORMAT A18  HEADING 'Room Revenue'
COLUMN "Rev YoY %"      FORMAT A11  HEADING 'Rev YoY %'
COLUMN "Bookings"       FORMAT A12  HEADING 'Bookings'
COLUMN "Vol YoY %"      FORMAT A11  HEADING 'Vol YoY %'
COLUMN "Avg Lead Time"  FORMAT A14  HEADING 'Avg Lead Time'
COLUMN "Lead Time Chg"  FORMAT A17  HEADING 'Lead Time YoY Chg'

-- Main Query
WITH
  QuarterlyMetrics AS (
    SELECT
      dd.Year, dd.Quarter, SUM(fbr.CalculatedBookingAmount) AS TotalRevenue,
      COUNT(fbr.BookingID) AS BookingVolume, AVG(dd.FullDate - b.payment_date) AS AvgLeadTime
    FROM FactBookingRoom fbr
    JOIN DimDate dd ON fbr.DateKey = dd.DateKey
    JOIN Booking b ON fbr.BookingID = b.booking_id
    WHERE b.payment_date < dd.FullDate
    GROUP BY dd.Year, dd.Quarter
  ),
  MetricsWithYoY AS (
    SELECT
      Year, Quarter, TotalRevenue, BookingVolume, AvgLeadTime,
      LAG(TotalRevenue, 1, 0) OVER (PARTITION BY Quarter ORDER BY Year) AS PrevYearRevenue,
      LAG(BookingVolume, 1, 0) OVER (PARTITION BY Quarter ORDER BY Year) AS PrevYearVolume,
      LAG(AvgLeadTime, 1, 0) OVER (PARTITION BY Quarter ORDER BY Year) AS PrevYearLeadTime
    FROM QuarterlyMetrics
  ),
  FinalMetrics AS (
    SELECT
      Year, 'Q' || Quarter AS Quarter, TotalRevenue, BookingVolume, AvgLeadTime,
      CASE WHEN PrevYearRevenue = 0 THEN NULL ELSE (TotalRevenue - PrevYearRevenue) * 100 / PrevYearRevenue END AS RevenueYoY,
      CASE WHEN PrevYearVolume = 0 THEN NULL ELSE (BookingVolume - PrevYearVolume) * 100 / PrevYearVolume END AS VolumeYoY,
      AvgLeadTime - PrevYearLeadTime AS LeadTimeYoY_Change,
      RANK() OVER (PARTITION BY Year ORDER BY TotalRevenue DESC) AS QuarterRank
    FROM MetricsWithYoY
  )
SELECT
  Year AS "Year", Quarter AS "Qtr", '#' || QuarterRank AS "Qtr Rank",
  TO_CHAR(TotalRevenue, 'FM$999,999,990') AS "Room Revenue",
  CASE WHEN RevenueYoY IS NULL THEN 'N/A' ELSE TO_CHAR(RevenueYoY, 'FM990.0') || '%' END AS "Rev YoY %",
  TO_CHAR(BookingVolume, 'FM999,999,990') AS "Bookings",
  CASE WHEN VolumeYoY IS NULL THEN 'N/A' ELSE TO_CHAR(VolumeYoY, 'FM990.0') || '%' END AS "Vol YoY %",
  TO_CHAR(AvgLeadTime, 'FM999,990.0') AS "Avg Lead Time",
  CASE
    WHEN LeadTimeYoY_Change IS NULL THEN 'N/A'
    ELSE TO_CHAR(LeadTimeYoY_Change, 'FMS999,990.0') || ' Days'
  END AS "Lead Time Chg"
FROM FinalMetrics
ORDER BY Year, Quarter;

-- Clean up the report settings
CLEAR COLUMNS
TTITLE OFF
BTITLE OFF