-- Report 3: Ancillary Performance with Global Peer Ranking

-- Setup for a clean, professional report.
SET PAGESIZE 30
SET LINESIZE 180
SET VERIFY OFF
SET FEEDBACK OFF

-- Dynamically determine the latest year for the report title.
-- SET TERMOUT OFF hides this setup query from the final output.
SET TERMOUT OFF
COLUMN latest_year FORMAT 9999 NEW_VALUE V_LATEST_YEAR NOPRINT;
SELECT MAX(dd.Year) AS latest_year
FROM FactFacilityBooking ffb
JOIN DimDate dd ON ffb.DateKey = dd.DateKey;
SET TERMOUT ON

-- Set the report titles, using the variable we just created.
TTITLE CENTER 'Hotel Analytics Inc.' SKIP 1 CENTER 'Hotel Ancillary Performance by Global Peer Group' SKIP 1 CENTER '(Analysis for the Year &V_LATEST_YEAR)' SKIP 2
BTITLE CENTER 'Report Generated on: ' _DATE

-- Define the column formats and headings for the report body.
COLUMN "Hotel ID"           FORMAT 9999 HEADING 'ID'
COLUMN "Global Peer Rank"   FORMAT A20  HEADING 'Global Peer Rank'
COLUMN City                 FORMAT A25  HEADING 'City'
COLUMN Country              FORMAT A35  HEADING 'Country'
COLUMN "Ancillary/Night"    FORMAT A17  HEADING 'Ancillary/Night'
COLUMN "Dining"             FORMAT A12  HEADING 'Dining'
COLUMN "Business"           FORMAT A12  HEADING 'Business'
COLUMN "Recreation"         FORMAT A12  HEADING 'Recreation'
COLUMN "Wellness"           FORMAT A12  HEADING 'Wellness'

-- Main Query
WITH
  HotelRoomMetrics AS (
    -- Filter for only the latest year using the variable
    SELECT fbr.HotelKey, SUM(fbr.DurationDays) AS TotalRoomNights
    FROM FactBookingRoom fbr
    JOIN DimDate dd ON fbr.DateKey = dd.DateKey
    WHERE dd.Year = &V_LATEST_YEAR
    GROUP BY fbr.HotelKey
  ),
  HotelFacilityBreakdown AS (
    -- Filter for only the latest year using the variable
    SELECT
      ffb.HotelKey,
      df.FacilityType,
      SUM(ffb.FacilityTotalAmount) AS TypeRevenue
    FROM FactFacilityBooking ffb
    JOIN DimDate dd ON ffb.DateKey = dd.DateKey
    JOIN DimFacility df ON ffb.FacilityKey = df.FacilityKey
    WHERE dd.Year = &V_LATEST_YEAR
    GROUP BY ffb.HotelKey, df.FacilityType
  ),
  HotelPerformance AS (
    SELECT
      hrm.HotelKey, dh.HotelID, dh.City, dh.Country, dh.Rating,
      SUM(CASE WHEN hfb.FacilityType = 'Dining' THEN hfb.TypeRevenue ELSE 0 END) AS DiningRevenue,
      SUM(CASE WHEN hfb.FacilityType = 'Business' THEN hfb.TypeRevenue ELSE 0 END) AS BusinessRevenue,
      SUM(CASE WHEN hfb.FacilityType = 'Recreation' THEN hfb.TypeRevenue ELSE 0 END) AS RecreationRevenue,
      SUM(CASE WHEN hfb.FacilityType = 'Wellness' THEN hfb.TypeRevenue ELSE 0 END) AS WellnessRevenue,
      CASE WHEN NVL(hrm.TotalRoomNights, 0) = 0 THEN 0 ELSE SUM(hfb.TypeRevenue) / hrm.TotalRoomNights END AS AncillaryPerNight
    FROM HotelRoomMetrics hrm
    LEFT JOIN HotelFacilityBreakdown hfb ON hrm.HotelKey = hfb.HotelKey
    JOIN DimHotel dh ON hrm.HotelKey = dh.HotelKey
    WHERE hrm.TotalRoomNights > 0
    GROUP BY hrm.HotelKey, dh.HotelID, dh.City, dh.Country, dh.Rating, hrm.TotalRoomNights
  )
SELECT
  hp.HotelID AS "Hotel ID",
  -- *** CORRECTED LINE: Use 'FM9.0' to force a trailing zero on whole numbers ***
  TO_CHAR(hp.Rating, 'FM9.0') || ' Star: ' ||
  (RANK() OVER (PARTITION BY hp.Rating ORDER BY hp.AncillaryPerNight DESC)) || ' of ' ||
  (COUNT(*) OVER (PARTITION BY hp.Rating)) AS "Global Peer Rank",
  hp.City, hp.Country,
  TO_CHAR(hp.AncillaryPerNight, 'FM$99,990.00') AS "Ancillary/Night",
  TO_CHAR(hp.DiningRevenue, 'FM$9,999,990') AS "Dining",
  TO_CHAR(hp.BusinessRevenue, 'FM$9,999,990') AS "Business",
  TO_CHAR(hp.RecreationRevenue, 'FM$9,999,990') AS "Recreation",
  TO_CHAR(hp.WellnessRevenue, 'FM$9,999,990') AS "Wellness"
FROM HotelPerformance hp
ORDER BY hp.Rating DESC, hp.AncillaryPerNight DESC;

-- Clean up the report settings to return SQL*Plus to its default state.
CLEAR COLUMNS
TTITLE OFF
BTITLE OFF