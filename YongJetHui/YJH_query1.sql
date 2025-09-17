SET DEFINE OFF
SET PAGESIZE 35
SET LINESIZE 130
SET VERIFY OFF
SET FEEDBACK OFF
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '.,'

TTITLE CENTER 'Segment Spend Composition (Room vs. Ancillary)' SKIP 1 -
       CENTER 'Analysis Period: 2020 - 2024' SKIP 1 -
       RIGHT 'Date: ' _DATE SKIP 1 -
       RIGHT 'Page: ' FORMAT 999 SQL.PNO SKIP 2

COLUMN "Strategic_Segment"         FORMAT A28      HEADING 'Strategic Guest Segment'
COLUMN "Avg_Total_Spend"           FORMAT A20      HEADING 'Avg. Total Spend|per Guest (RM)'
COLUMN "Avg_Room_Spend"            FORMAT A20      HEADING 'Avg. Room Spend|per Guest (RM)'
COLUMN "Avg_Ancillary_Spend"       FORMAT A20      HEADING 'Avg. Service Spend|per Guest (RM)'
COLUMN "Ancillary_Share"           FORMAT A20      HEADING 'Service Share|of Total Spend (%)'

WITH 
  GuestBehavioralFacts AS (
    SELECT 
        fbr.GuestKey, fbr.BookingID, d.FullDate AS TransactionDate,
        fbr.CalculatedBookingAmount AS RoomRevenue, 0 AS FacilityRevenue,
        CASE WHEN d.DayName LIKE 'Saturday%' OR d.DayName LIKE 'Sunday%' THEN 1 ELSE 0 END AS IsWeekendStay
    FROM FactBookingRoom fbr JOIN DimDate d ON fbr.DateKey = d.DateKey WHERE d.Year BETWEEN 2020 AND 2024
    UNION ALL
    SELECT 
        ffb.GuestKey, NULL AS BookingID, d.FullDate AS TransactionDate,
        0 AS RoomRevenue, ffb.FacilityTotalAmount AS FacilityRevenue, NULL AS IsWeekendStay
    FROM FactFacilityBooking ffb JOIN DimDate d ON ffb.DateKey = d.DateKey WHERE d.Year BETWEEN 2020 AND 2024
  ),
  GuestProfile AS (
    SELECT 
        GuestKey,
        SUM(RoomRevenue) AS TotalRoomSpend,
        SUM(FacilityRevenue) AS TotalAncillarySpend,
        SUM(RoomRevenue) + SUM(FacilityRevenue) AS TotalSpend,
        COUNT(DISTINCT BookingID) AS NumberOfBookings,
        MAX(TransactionDate) AS LastVisitDate,
        AVG(NVL(IsWeekendStay,0)) AS WeekendStayRatio
    FROM GuestBehavioralFacts GROUP BY GuestKey
  ),
  Thresholds AS (
    SELECT
        PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY TotalSpend) AS VIP_Spend_Threshold,
        PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY TotalSpend) AS High_Spend_Threshold,
        PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY NumberOfBookings) AS VIP_Booking_Threshold,
        PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY NumberOfBookings) AS High_Booking_Threshold
    FROM GuestProfile
  ),
  GuestSegmentation AS (
    SELECT
        p.GuestKey,
        p.TotalRoomSpend,
        p.TotalAncillarySpend,
        p.TotalSpend,
        CASE
            WHEN p.TotalSpend >= t.VIP_Spend_Threshold AND p.NumberOfBookings >= t.VIP_Booking_Threshold THEN 'VIPs'
            WHEN p.TotalSpend >= t.High_Spend_Threshold AND p.NumberOfBookings >= t.High_Booking_Threshold THEN 'Loyal Guests'
            WHEN p.TotalSpend >= t.High_Spend_Threshold AND p.WeekendStayRatio > 0.6 THEN 'Weekend Guests'
            WHEN p.TotalSpend >= t.High_Spend_Threshold AND p.WeekendStayRatio <= 0.4 THEN 'Weekday Guests'
            WHEN p.NumberOfBookings >= t.High_Booking_Threshold THEN 'Regulars'
            WHEN p.NumberOfBookings = 1 AND (SYSDATE - p.LastVisitDate) <= 365 THEN 'New Guests'
            ELSE 'Occasional Guests'
        END AS StrategicSegment
    FROM GuestProfile p
    CROSS JOIN Thresholds t
  )
SELECT
    gs.StrategicSegment AS "Strategic_Segment",
    TO_CHAR(AVG(gs.TotalSpend), '99,990.00') AS "Avg_Total_Spend",
    TO_CHAR(AVG(gs.TotalRoomSpend), '99,990.00') AS "Avg_Room_Spend",
    TO_CHAR(AVG(gs.TotalAncillarySpend), '99,990.00') AS "Avg_Ancillary_Spend",
    TO_CHAR(AVG(gs.TotalAncillarySpend) * 100 / NULLIF(AVG(gs.TotalSpend),0), '990.0') || '%' AS "Ancillary_Share"
FROM GuestSegmentation gs
GROUP BY gs.StrategicSegment
ORDER BY AVG(gs.TotalSpend) DESC;

TTITLE OFF
CLEAR COLUMNS;

-- =====================================================================================
-- ANCILLARY PREFERENCE ANALYSIS
-- =====================================================================================

TTITLE CENTER 'Ancillary Service Preference of Guest Segments' SKIP 1 -
       CENTER 'Analysis Period: 2020 - 2024' SKIP 1 -
       RIGHT 'Date: ' _DATE SKIP 1 -
       RIGHT 'Page: ' FORMAT 999 SQL.PNO SKIP 2

COLUMN "Strategic_Segment"         FORMAT A28      HEADING 'High-Value Guest Segment'
COLUMN "Facility_Type"             FORMAT A20      HEADING 'Facility Type'
COLUMN "Spend_per_Guest"           FORMAT A25      HEADING 'Avg. Spend per Guest|in Segment (RM)'
COLUMN "Service_Spend_Share"       FORMAT A25      HEADING 'Share of Segment''s|Service Spend (%)'


BREAK ON "Strategic_Segment" SKIP 1

WITH 
  GuestBehavioralFacts AS (
    SELECT 
        fbr.GuestKey, fbr.BookingID, d.FullDate AS TransactionDate,
        fbr.CalculatedBookingAmount AS RoomRevenue, 0 AS FacilityRevenue,
        CASE WHEN d.DayName LIKE 'Saturday%' OR d.DayName LIKE 'Sunday%' THEN 1 ELSE 0 END AS IsWeekendStay
    FROM FactBookingRoom fbr JOIN DimDate d ON fbr.DateKey = d.DateKey WHERE d.Year BETWEEN 2020 AND 2024
    UNION ALL
    SELECT 
        ffb.GuestKey, NULL AS BookingID, d.FullDate AS TransactionDate,
        0 AS RoomRevenue, ffb.FacilityTotalAmount AS FacilityRevenue, NULL AS IsWeekendStay
    FROM FactFacilityBooking ffb JOIN DimDate d ON ffb.DateKey = d.DateKey WHERE d.Year BETWEEN 2020 AND 2024
  ),
  GuestProfile AS (
    SELECT 
        GuestKey,
        SUM(RoomRevenue) + SUM(FacilityRevenue) AS TotalSpend,
        COUNT(DISTINCT BookingID) AS NumberOfBookings,
        MAX(TransactionDate) AS LastVisitDate,
        AVG(NVL(IsWeekendStay,0)) AS WeekendStayRatio
    FROM GuestBehavioralFacts GROUP BY GuestKey
  ),
  Thresholds AS (
    SELECT
        PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY TotalSpend) AS VIP_Spend_Threshold,
        PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY TotalSpend) AS High_Spend_Threshold,
        PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY NumberOfBookings) AS VIP_Booking_Threshold,
        PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY NumberOfBookings) AS High_Booking_Threshold
    FROM GuestProfile
  ),
  GuestSegmentation AS (
    SELECT
        p.GuestKey,
        CASE
            WHEN p.TotalSpend >= t.VIP_Spend_Threshold AND p.NumberOfBookings >= t.VIP_Booking_Threshold THEN 'VIPs'
            WHEN p.TotalSpend >= t.High_Spend_Threshold AND p.NumberOfBookings >= t.High_Booking_Threshold THEN 'Loyal Guests'
            WHEN p.TotalSpend >= t.High_Spend_Threshold AND p.WeekendStayRatio > 0.6 THEN 'Weekend Guests'
            WHEN p.TotalSpend >= t.High_Spend_Threshold AND p.WeekendStayRatio <= 0.4 THEN 'Weekday Guests'
            WHEN p.NumberOfBookings >= t.High_Booking_Threshold THEN 'Regulars'
            WHEN p.NumberOfBookings = 1 AND (SYSDATE - p.LastVisitDate) <= 365 THEN 'New Guests'
            ELSE 'Occasional Guests'
        END AS StrategicSegment
    FROM GuestProfile p
    CROSS JOIN Thresholds t
  ),
  SegmentAncillarySpend AS (
    SELECT
      gs.StrategicSegment,
      gs.GuestKey,
      df.FacilityType,
      SUM(ffb.FacilityTotalAmount) AS SpendOnFacilityType
    FROM FactFacilityBooking ffb
    JOIN DimFacility df ON ffb.FacilityKey = df.FacilityKey
    JOIN GuestSegmentation gs ON ffb.GuestKey = gs.GuestKey
    JOIN DimDate dd ON ffb.DateKey = dd.DateKey
    WHERE dd.Year BETWEEN 2020 AND 2024 AND dd.FullDate <= SYSDATE
    GROUP BY gs.StrategicSegment, gs.GuestKey, df.FacilityType
  )
SELECT
  sas.StrategicSegment AS "Strategic_Segment",
  sas.FacilityType AS "Facility_Type",
  TO_CHAR(SUM(sas.SpendOnFacilityType) / COUNT(DISTINCT sas.GuestKey), '99,990.00') AS "Spend_per_Guest",
  TO_CHAR(SUM(sas.SpendOnFacilityType) * 100 / SUM(SUM(sas.SpendOnFacilityType)) OVER (PARTITION BY sas.StrategicSegment), '990.0') || '%' AS "Service_Spend_Share"
FROM SegmentAncillarySpend sas
GROUP BY sas.StrategicSegment, sas.FacilityType
ORDER BY 
  CASE sas.StrategicSegment
    WHEN 'VIPs' THEN 1
    WHEN 'Loyal Guests' THEN 2
    WHEN 'Weekday Guests' THEN 3
    WHEN 'Weekend Guests' THEN 4
    WHEN 'Regulars' THEN 5
    WHEN 'Occasional Guests' THEN 6
    WHEN 'New Guests' THEN 7
    ELSE 99
  END,
  SUM(sas.SpendOnFacilityType) DESC;

CLEAR COLUMNS;
CLEAR BREAKS;
TTITLE OFF;
BTITLE OFF;
