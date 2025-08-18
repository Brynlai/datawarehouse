-- Report 1: Multi-Year Revenue Performance and Growth

-- Setup the page and title for the report
SET PAGESIZE 25
SET LINESIZE 140
TTITLE CENTER 'Hotel Analytics Inc.' SKIP 1 CENTER 'Annual Revenue Performance and Growth' SKIP 2
BTITLE CENTER 'Report Generated on: ' _DATE

-- Define the column formats and headings
COLUMN "Revenue Year"           FORMAT 9999 HEADING 'Year'
COLUMN "Total Room Revenue"     FORMAT A22  HEADING 'Total Room Revenue'
COLUMN "Total Facility Revenue" FORMAT A24  HEADING 'Total Facility Revenue'
COLUMN "Grand Total Revenue"    FORMAT A23  HEADING 'Grand Total Revenue'
COLUMN "Previous Year Revenue"  FORMAT A23  HEADING 'Previous Year Revenue'
COLUMN "YoY Growth %"           FORMAT A14  HEADING 'YoY Growth %'

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
  RevenueYear AS "Revenue Year",
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

-- Clean up the report settings
CLEAR COLUMNS
TTITLE OFF
BTITLE OFF