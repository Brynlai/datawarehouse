
DEFINE LATEST_YEAR = 2025

SET PAGESIZE 30
SET LINESIZE 180
SET VERIFY OFF
SET FEEDBACK OFF

TTITLE CENTER 'Hotel Analytics Inc.' SKIP 1 CENTER 'Hotel Upselling Effectiveness by Peer Group' SKIP 1 -
CENTER '(Analysis for the Year &LATEST_YEAR)' SKIP 1 -
LEFT 'Page ' FORMAT 999 SQL.PNO COL 112 'Report Generated on: ' _DATE SKIP 2

COLUMN "Peer Rank"            FORMAT A20
COLUMN City                   FORMAT A25
COLUMN Country                FORMAT A40
COLUMN "Upselling Ratio"      FORMAT A18 HEADING 'Upselling Ratio'
COLUMN "Avg Room Rate"        FORMAT $99,990.00
COLUMN "Extra Spending/Night" FORMAT $99,990.00

WITH
  HotelRoomMetrics AS (
    SELECT
      fbr.HotelKey,
      SUM(fbr.DurationDays) AS TotalRoomNights,
      SUM(fbr.CalculatedBookingAmount) / SUM(fbr.DurationDays) AS AvgRoomRate
    FROM FactBookingRoom fbr
    JOIN DimDate dd ON fbr.DateKey = dd.DateKey
    WHERE dd.Year = &LATEST_YEAR AND fbr.DurationDays > 0
    GROUP BY fbr.HotelKey
  ),
  HotelFacilityMetrics AS (
    SELECT ffb.HotelKey, SUM(ffb.FacilityTotalAmount) AS TotalFacilityRevenue
    FROM FactFacilityBooking ffb
    JOIN DimDate dd ON ffb.DateKey = dd.DateKey
    WHERE dd.Year = &LATEST_YEAR
    GROUP BY ffb.HotelKey
  ),
  HotelPerformance AS (
    SELECT
      hrm.HotelKey, dh.City, dh.Country, dh.Rating, hrm.AvgRoomRate,
      CASE
        WHEN NVL(hrm.TotalRoomNights, 0) = 0 THEN 0
        ELSE NVL(hfm.TotalFacilityRevenue, 0) / hrm.TotalRoomNights
      END AS ExtraSpendingPerNight
    FROM HotelRoomMetrics hrm
    JOIN DimHotel dh ON hrm.HotelKey = dh.HotelKey
    LEFT JOIN HotelFacilityMetrics hfm ON hrm.HotelKey = hfm.HotelKey
    WHERE hrm.TotalRoomNights > 0
  )
SELECT
  TO_CHAR(hp.Rating, 'FM9.0') || ' Star: ' ||
  RANK() OVER (PARTITION BY hp.Rating ORDER BY (hp.ExtraSpendingPerNight / hp.AvgRoomRate) DESC) || ' of ' ||
  COUNT(*) OVER (PARTITION BY hp.Rating) AS "Peer Rank",
  hp.City,
  hp.Country,
  LPAD(TO_CHAR((hp.ExtraSpendingPerNight / hp.AvgRoomRate) * 100, 'FM990.0') || '%', 18) AS "Upselling Ratio",
  hp.AvgRoomRate AS "Avg Room Rate",
  hp.ExtraSpendingPerNight AS "Extra Spending/Night"
FROM HotelPerformance hp
WHERE hp.AvgRoomRate > 0
ORDER BY hp.Rating DESC, (hp.ExtraSpendingPerNight / hp.AvgRoomRate) DESC;

CLEAR COLUMNS
TTITLE OFF
UNDEFINE LATEST_YEAR


