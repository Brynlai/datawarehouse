-- Report 3: Ancillary Performance with Global Peer Ranking

-- Setup for a clean, professional report.
-- *** CORRECTED: Reduced PAGESIZE to remove the large gap before the footer. ***
SET PAGESIZE 30
SET LINESIZE 160
SET VERIFY OFF
SET FEEDBACK OFF

-- Dynamically determine the latest year for the report title.
SET TERMOUT OFF
COLUMN latest_year FORMAT 9999 NEW_VALUE V_LATEST_YEAR NOPRINT;
SELECT MAX(dd.Year) AS latest_year
FROM FactFacilityBooking ffb
JOIN DimDate dd ON ffb.DateKey = dd.DateKey;
SET TERMOUT ON

-- Set the report titles, using the variable we just created.
TTITLE CENTER 'Hotel Analytics Inc.' SKIP 1 CENTER 'Hotel Ancillary Performance by Global Peer Group' SKIP 1 CENTER '(Analysis for the Year &V_LATEST_YEAR)' SKIP 2
BTITLE CENTER 'Page ' FORMAT 999 SQL.PNO SKIP 1 CENTER 'Report Generated on: ' _DATE

-- Define the column formats and headings for the report body.
COLUMN "Global Peer Rank"   FORMAT A20
COLUMN City                 FORMAT A25
COLUMN Country              FORMAT A35
COLUMN "Ancillary/Night"    FORMAT $99,990.00
COLUMN "Dining"             FORMAT $9,999,990
COLUMN "Business"           FORMAT $9,999,990
COLUMN "Recreation"         FORMAT $9,999,990
COLUMN "Wellness"           FORMAT $9,999,990

-- Main Query
WITH
  HotelRoomMetrics AS (
    SELECT fbr.HotelKey, SUM(fbr.DurationDays) AS TotalRoomNights
    FROM FactBookingRoom fbr
    JOIN DimDate dd ON fbr.DateKey = dd.DateKey
    WHERE dd.Year = &V_LATEST_YEAR
    GROUP BY fbr.HotelKey
  ),
  HotelFacilityBreakdown AS (
    SELECT * FROM (
      SELECT
        ffb.HotelKey, df.FacilityType, ffb.FacilityTotalAmount
      FROM FactFacilityBooking ffb
      JOIN DimDate dd ON ffb.DateKey = dd.DateKey
      JOIN DimFacility df ON ffb.FacilityKey = df.FacilityKey
      WHERE dd.Year = &V_LATEST_YEAR
    )
    PIVOT (
      SUM(FacilityTotalAmount)
      FOR FacilityType IN ('Dining' AS Dining, 'Business' AS Business, 'Recreation' AS Recreation, 'Wellness' AS Wellness)
    )
  ),
  HotelPerformance AS (
    SELECT
      hrm.HotelKey, dh.City, dh.Country, dh.Rating,
      NVL(hfb.Dining, 0) AS DiningRevenue,
      NVL(hfb.Business, 0) AS BusinessRevenue,
      NVL(hfb.Recreation, 0) AS RecreationRevenue,
      NVL(hfb.Wellness, 0) AS WellnessRevenue,
      CASE
        WHEN NVL(hrm.TotalRoomNights, 0) = 0 THEN 0
        ELSE (NVL(hfb.Dining, 0) + NVL(hfb.Business, 0) + NVL(hfb.Recreation, 0) + NVL(hfb.Wellness, 0)) / hrm.TotalRoomNights
      END AS AncillaryPerNight
    FROM HotelRoomMetrics hrm
    JOIN DimHotel dh ON hrm.HotelKey = dh.HotelKey
    LEFT JOIN HotelFacilityBreakdown hfb ON hrm.HotelKey = hfb.HotelKey
    WHERE hrm.TotalRoomNights > 0
  )
SELECT
  TO_CHAR(hp.Rating, 'FM9.0') || ' Star: ' ||
  (RANK() OVER (PARTITION BY hp.Rating ORDER BY hp.AncillaryPerNight DESC)) || ' of ' ||
  (COUNT(*) OVER (PARTITION BY hp.Rating)) AS "Global Peer Rank",
  hp.City,
  hp.Country,
  hp.AncillaryPerNight AS "Ancillary/Night",
  hp.DiningRevenue AS "Dining",
  hp.BusinessRevenue AS "Business",
  hp.RecreationRevenue AS "Recreation",
  hp.WellnessRevenue AS "Wellness"
FROM HotelPerformance hp
ORDER BY hp.Rating DESC, hp.AncillaryPerNight DESC;

-- Clean up the report settings to return SQL*Plus to its default state.
CLEAR COLUMNS
TTITLE OFF
BTITLE OFF