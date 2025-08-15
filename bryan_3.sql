-- Report 3: Operational Efficiency: Hotel Upselling Performance Analysis
-- Set session and formatting for a professional report output
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '.,';
SET LINESIZE 130
SET PAGESIZE 50
SET HEADING ON

-- Clear previous formats to ensure a clean slate
CLEAR COLUMNS
CLEAR BREAKS
CLEAR COMPUTES

TTITLE CENTER 'Operational Efficiency Report' SKIP 1 CENTER 'Hotel Upselling Performance (Ancillary vs. Room Revenue) for 2023' SKIP 2

-- Define column formats for perfect alignment
COLUMN Hotel_Location FORMAT A50 HEADING 'Hotel Location'
COLUMN Room_Revenue FORMAT $999,999,990.00 HEADING 'Total Room Revenue'
COLUMN Facility_Revenue FORMAT $999,999,990.00 HEADING 'Total Facility Revenue'
COLUMN Ancillary_Revenue_Ratio FORMAT A20 HEADING 'Upsell Ratio (%)'

-- CTE for aggregating Room Revenue per hotel
WITH HotelRoomRevenue AS (
    SELECT
        fbr.HotelKey,
        SUM(fbr.BookingTotalAmount) AS Total_Room_Revenue
    FROM
        FactBookingRoom fbr
    JOIN
        DimDate dd ON fbr.DateKey = dd.DateKey
    WHERE
        dd.Year = 2023
    GROUP BY
        fbr.HotelKey
),
-- CTE for aggregating Facility Revenue per hotel
HotelFacilityRevenue AS (
    SELECT
        ffb.HotelKey,
        SUM(ffb.BookingFee) AS Total_Facility_Revenue
    FROM
        FactFacilityBooking ffb
    JOIN
        DimDate dd ON ffb.DateKey = dd.DateKey
    WHERE
        dd.Year = 2023
    GROUP BY
        ffb.HotelKey
)
-- Final SELECT to join the two revenue streams and calculate the ratio
SELECT
    dh.City || ', ' || dh.Country AS Hotel_Location,
    NVL(rrr.Total_Room_Revenue, 0) AS Room_Revenue,
    NVL(frr.Total_Facility_Revenue, 0) AS Facility_Revenue,
    LPAD(
        CASE
            WHEN NVL(rrr.Total_Room_Revenue, 0) > 0
            THEN TO_CHAR((NVL(frr.Total_Facility_Revenue, 0) / rrr.Total_Room_Revenue) * 100, '990.00') || '%'
            ELSE '0.00%'
        END, 20, ' ') AS Ancillary_Revenue_Ratio
FROM
    DimHotel dh
LEFT JOIN
    HotelRoomRevenue rrr ON dh.HotelKey = rrr.HotelKey
LEFT JOIN
    HotelFacilityRevenue frr ON dh.HotelKey = frr.HotelKey
WHERE
    rrr.Total_Room_Revenue IS NOT NULL OR frr.Total_Facility_Revenue IS NOT NULL
ORDER BY
    (NVL(frr.Total_Facility_Revenue, 0) / NVL(rrr.Total_Room_Revenue, 1)) DESC;

-- Turn off the title for subsequent queries
TTITLE OFF