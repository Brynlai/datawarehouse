--------------------------------------------------------------------------------
-- Report 1: Multi-Year Revenue Performance & Growth (FIXED)
-- Purpose: Tracks total revenue (Rooms + Facilities) and calculates YoY growth
--          to provide a strategic overview of long-term business health.
--------------------------------------------------------------------------------

-- Formatting commands for clean, readable output in SQL*Plus
SET LINESIZE 150
SET PAGESIZE 50
COLUMN "Total Room Revenue" FORMAT A20
COLUMN "Total Facility Revenue" FORMAT A22
COLUMN "Grand Total Revenue" FORMAT A21
COLUMN "Previous Year Revenue" FORMAT A22
COLUMN "YoY Growth %" FORMAT A12

-- Main Query
WITH
  AnnualRoomRevenue AS (
    SELECT dd.Year, SUM(fbr.CalculatedBookingAmount) AS RoomRevenue
    FROM FactBookingRoom fbr JOIN DimDate dd ON fbr.DateKey = dd.DateKey
    GROUP BY dd.Year
  ),
  AnnualFacilityRevenue AS (
    SELECT dd.Year, SUM(ffb.FacilityTotalAmount) AS FacilityRevenue
    FROM FactFacilityBooking ffb JOIN DimDate dd ON ffb.DateKey = dd.DateKey
    GROUP BY dd.Year
  ),
  TotalAnnualRevenue AS (
    SELECT
      COALESCE(r.Year, f.Year) AS RevenueYear,
      NVL(r.RoomRevenue, 0) AS TotalRoomRevenue,
      NVL(f.FacilityRevenue, 0) AS TotalFacilityRevenue,
      (NVL(r.RoomRevenue, 0) + NVL(f.FacilityRevenue, 0)) AS TotalRevenue
    FROM AnnualRoomRevenue r FULL OUTER JOIN AnnualFacilityRevenue f ON r.Year = f.Year
  )
SELECT
  RevenueYear,
  TO_CHAR(TotalRoomRevenue, 'FM$999,999,999,990') AS "Total Room Revenue",
  TO_CHAR(TotalFacilityRevenue, 'FM$999,999,999,990') AS "Total Facility Revenue",
  TO_CHAR(TotalRevenue, 'FM$999,999,999,990') AS "Grand Total Revenue",
  TO_CHAR(LAG(TotalRevenue, 1, 0) OVER(ORDER BY RevenueYear), 'FM$999,999,999,990') AS "Previous Year Revenue",
  CASE
    WHEN LAG(TotalRevenue, 1, 0) OVER(ORDER BY RevenueYear) = 0 THEN 'N/A'
    ELSE TO_CHAR(((TotalRevenue - LAG(TotalRevenue, 1) OVER(ORDER BY RevenueYear)) / LAG(TotalRevenue, 1) OVER(ORDER BY RevenueYear)) * 100, 'FM990.00') || '%'
  END AS "YoY Growth %"
FROM TotalAnnualRevenue
ORDER BY RevenueYear;

-- Clear the formatting for subsequent queries
CLEAR COLUMNS;