--------------------------------------------------------------------------------
-- Report 3 (FINAL, CORRECTED): Ancillary Performance with Global Peer Ranking
-- Purpose: Identifies top-performing hotels by ranking them against their
--          global peers (by rating) and breaks down ancillary revenue by type
--          to reveal the drivers of success.
--------------------------------------------------------------------------------

-- Formatting commands for the enhanced report
SET LINESIZE 170
SET PAGESIZE 100
COLUMN "Hotel ID" FORMAT 9999
COLUMN "Global Peer Rank" FORMAT A16
COLUMN City FORMAT A20
COLUMN Country FORMAT A25
COLUMN "Ancillary/Night" FORMAT $99,990.00
COLUMN "Dining" FORMAT $9,999,990
COLUMN "Business" FORMAT $9,999,990
COLUMN "Recreation" FORMAT $9,999,990
COLUMN "Wellness" FORMAT $9,999,990

-- Main Query
WITH
  HotelRoomMetrics AS (
    SELECT HotelKey, SUM(DurationDays) AS TotalRoomNights
    FROM FactBookingRoom
    GROUP BY HotelKey
  ),
  HotelFacilityBreakdown AS (
    -- Step 1: Aggregate facility revenue by hotel AND by facility type
    SELECT
      ffb.HotelKey,
      df.FacilityType,
      SUM(ffb.FacilityTotalAmount) AS TypeRevenue
    FROM FactFacilityBooking ffb
    JOIN DimFacility df ON ffb.FacilityKey = df.FacilityKey
    GROUP BY ffb.HotelKey, df.FacilityType
  ),
  HotelPerformance AS (
    -- Step 2: Pivot the breakdown data and calculate the final KPI
    SELECT
      hrm.HotelKey,
      dh.HotelID,
      dh.City,
      dh.Country,
      dh.Rating,
      SUM(CASE WHEN hfb.FacilityType = 'Dining' THEN hfb.TypeRevenue ELSE 0 END) AS DiningRevenue,
      SUM(CASE WHEN hfb.FacilityType = 'Business' THEN hfb.TypeRevenue ELSE 0 END) AS BusinessRevenue,
      SUM(CASE WHEN hfb.FacilityType = 'Recreation' THEN hfb.TypeRevenue ELSE 0 END) AS RecreationRevenue,
      SUM(CASE WHEN hfb.FacilityType = 'Wellness' THEN hfb.TypeRevenue ELSE 0 END) AS WellnessRevenue,
      CASE
        WHEN NVL(hrm.TotalRoomNights, 0) = 0 THEN 0
        ELSE SUM(hfb.TypeRevenue) / hrm.TotalRoomNights
      END AS AncillaryPerNight
    FROM HotelRoomMetrics hrm
    LEFT JOIN HotelFacilityBreakdown hfb ON hrm.HotelKey = hfb.HotelKey
    JOIN DimHotel dh ON hrm.HotelKey = dh.HotelKey
    WHERE hrm.TotalRoomNights > 0
    GROUP BY
      hrm.HotelKey, dh.HotelID, dh.City, dh.Country, dh.Rating, hrm.TotalRoomNights
  )
-- Final Presentation Layer with GLOBAL Peer Group Ranking
SELECT
  hp.HotelID AS "Hotel ID",
  -- *** THIS LOGIC IS NOW CORRECTED TO PARTITION BY RATING ONLY ***
  hp.Rating || ' Star: ' ||
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
ORDER BY hp.Rating DESC, "Ancillary/Night" DESC;

CLEAR COLUMNS;