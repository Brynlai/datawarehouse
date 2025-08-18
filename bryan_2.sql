--------------------------------------------------------------------------------
-- Report 2 (IMPROVED): Quarterly Performance Deep Dive with YoY Growth & Ranking
-- Purpose: Provides a comprehensive view of seasonal trends by showing
--          absolute values, year-over-year growth, and intra-year ranking
--          for key business metrics.
--------------------------------------------------------------------------------

-- Formatting commands for clean, readable output
SET LINESIZE 160
SET PAGESIZE 100
COLUMN "Year" FORMAT 9999
COLUMN "Qtr" FORMAT A3
COLUMN "Qtr Rank" FORMAT A8
COLUMN "Room Revenue" FORMAT A18
COLUMN "Rev YoY %" FORMAT A11
COLUMN "Bookings" FORMAT A12
COLUMN "Vol YoY %" FORMAT A11
COLUMN "Avg Lead Time" FORMAT 999,990.0
COLUMN "Lead Time YoY Chg" FORMAT A18

-- Main Query
WITH
  QuarterlyMetrics AS (
    -- Step 1: Aggregate core metrics by year and quarter
    SELECT
      dd.Year,
      dd.Quarter,
      SUM(fbr.CalculatedBookingAmount) AS TotalRevenue,
      COUNT(fbr.BookingID) AS BookingVolume,
      AVG(dd.FullDate - b.payment_date) AS AvgLeadTime
    FROM FactBookingRoom fbr
    JOIN DimDate dd ON fbr.DateKey = dd.DateKey
    JOIN Booking b ON fbr.BookingID = b.booking_id
    WHERE b.payment_date < dd.FullDate
    GROUP BY dd.Year, dd.Quarter
  ),
  MetricsWithYoY AS (
    -- Step 2: Use LAG to get the previous year's values for YoY comparison.
    -- The PARTITION BY Quarter is crucial to compare Q1-vs-Q1, Q2-vs-Q2, etc.
    SELECT
      Year,
      Quarter,
      TotalRevenue,
      BookingVolume,
      AvgLeadTime,
      LAG(TotalRevenue, 1, 0) OVER (PARTITION BY Quarter ORDER BY Year) AS PrevYearRevenue,
      LAG(BookingVolume, 1, 0) OVER (PARTITION BY Quarter ORDER BY Year) AS PrevYearVolume,
      LAG(AvgLeadTime, 1, 0) OVER (PARTITION BY Quarter ORDER BY Year) AS PrevYearLeadTime
    FROM QuarterlyMetrics
  ),
  FinalMetrics AS (
    -- Step 3: Calculate the YoY changes and add an intra-year rank
    SELECT
      Year,
      'Q' || Quarter AS Quarter,
      TotalRevenue,
      BookingVolume,
      AvgLeadTime,
      -- Calculate YoY % change, handling the first year
      CASE WHEN PrevYearRevenue = 0 THEN NULL ELSE (TotalRevenue - PrevYearRevenue) * 100 / PrevYearRevenue END AS RevenueYoY,
      CASE WHEN PrevYearVolume = 0 THEN NULL ELSE (BookingVolume - PrevYearVolume) * 100 / PrevYearVolume END AS VolumeYoY,
      -- Calculate the absolute change in days for lead time
      AvgLeadTime - PrevYearLeadTime AS LeadTimeYoY_Change,
      -- Rank quarters within each year by revenue (1 = best, 4 = worst)
      RANK() OVER (PARTITION BY Year ORDER BY TotalRevenue DESC) AS QuarterRank
    FROM MetricsWithYoY
  )
-- Final Presentation Layer
SELECT
  Year,
  Quarter AS "Qtr",
  '#' || QuarterRank AS "Qtr Rank",
  TO_CHAR(TotalRevenue, 'FM$999,999,990') AS "Room Revenue",
  CASE WHEN RevenueYoY IS NULL THEN 'N/A' ELSE TO_CHAR(RevenueYoY, 'FM990.0') || '%' END AS "Rev YoY %",
  TO_CHAR(BookingVolume, 'FM999,999,990') AS "Bookings",
  CASE WHEN VolumeYoY IS NULL THEN 'N/A' ELSE TO_CHAR(VolumeYoY, 'FM990.0') || '%' END AS "Vol YoY %",
  AvgLeadTime AS "Avg Lead Time",
  CASE
    WHEN LeadTimeYoY_Change IS NULL THEN 'N/A'
    ELSE TO_CHAR(LeadTimeYoY_Change, 'FMS999,990.0') || ' Days'
  END AS "Lead Time YoY Chg"
FROM FinalMetrics
ORDER BY Year, Quarter;

-- Clear the formatting
CLEAR COLUMNS;