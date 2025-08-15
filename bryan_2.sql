-- Report 2: Tactical Pricing Analysis: ADR by Hotel Rating
-- Set session and formatting for a professional report output
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '.,';
SET LINESIZE 160
SET PAGESIZE 100
SET HEADING ON

-- Clear previous formats to ensure a clean slate
CLEAR COLUMNS
CLEAR BREAKS
CLEAR COMPUTES

TTITLE CENTER 'Tactical Pricing Analysis' SKIP 1 CENTER 'Average Daily Rate (ADR) by Hotel Rating with Individual Hotel Performance for 2023' SKIP 2

-- Define column formats
COLUMN Rating FORMAT 9.9 HEADING 'Hotel|Rating'
COLUMN Hotel_Location FORMAT A55 HEADING 'Hotel Location (City, Country)'
COLUMN Hotel_ADR FORMAT $99,990.00 HEADING 'Individual|Hotel ADR'
COLUMN Peer_Group_ADR FORMAT $99,990.00 HEADING 'Peer Group|Avg ADR'
COLUMN Variance_vs_Peers FORMAT A12 HEADING 'Variance|vs Peers'
COLUMN Pricing_Flag FORMAT A18 HEADING 'Pricing Flag'

-- *** KEY CHANGE: Use BREAK ON to visually separate the rating groups with a blank line ***
BREAK ON Rating SKIP 1

-- CTE 1: Calculate the Average Daily Rate for each individual hotel
WITH HotelADR AS (
    SELECT
        dh.Rating,
        dh.City || ', ' || dh.Country AS Hotel_Location,
        CASE WHEN SUM(fbr.DurationDays) > 0 THEN SUM(fbr.BookingTotalAmount) / SUM(fbr.DurationDays) ELSE 0 END AS Hotel_ADR
    FROM FactBookingRoom fbr
    JOIN DimHotel dh ON fbr.HotelKey = dh.HotelKey
    JOIN DimDate dd ON fbr.DateKey = dd.DateKey
    WHERE dd.Year = 2023 AND dh.Rating IS NOT NULL
    GROUP BY dh.Rating, dh.City, dh.Country
),
-- CTE 2: Calculate the average ADR for each rating *group* and find the benchmark ADR of the next-lower rating group
RatingADRWithComparison AS (
    SELECT
        Rating,
        Rating_ADR,
        LEAD(Rating_ADR, 1, 0) OVER (ORDER BY Rating DESC) AS Next_Lower_Rating_ADR
    FROM (
        SELECT
            dh.Rating,
            CASE WHEN SUM(fbr.DurationDays) > 0 THEN SUM(fbr.BookingTotalAmount) / SUM(fbr.DurationDays) ELSE 0 END AS Rating_ADR
        FROM FactBookingRoom fbr
        JOIN DimHotel dh ON fbr.HotelKey = dh.HotelKey
        JOIN DimDate dd ON fbr.DateKey = dd.DateKey
        WHERE dd.Year = 2023 AND dh.Rating IS NOT NULL
        GROUP BY dh.Rating
    )
)
-- Final SELECT, simplified to be clearer within the new BREAK groups
SELECT
    ha.Rating,
    ha.Hotel_Location,
    ha.Hotel_ADR,
    rac.Rating_ADR AS Peer_Group_ADR,
    -- Calculate and format the variance vs peers
    TO_CHAR( ( (ha.Hotel_ADR - rac.Rating_ADR) / rac.Rating_ADR ) * 100, 'S990.0') || '%' AS Variance_vs_Peers,
    -- The Pricing Flag remains the core of the analysis
    CASE
        WHEN ha.Hotel_ADR < rac.Next_Lower_Rating_ADR AND rac.Next_Lower_Rating_ADR > 0 THEN 'CRITICAL INVERSION'
        WHEN (ha.Hotel_ADR - rac.Rating_ADR) / rac.Rating_ADR < -0.15 THEN 'Underperforming'
        ELSE 'OK'
    END AS Pricing_Flag
FROM
    HotelADR ha
JOIN
    RatingADRWithComparison rac ON ha.Rating = rac.Rating
ORDER BY
    ha.Rating DESC,
    ha.Hotel_ADR ASC;

TTITLE OFF