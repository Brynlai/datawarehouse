-- Report 2: Tactical Pricing Analysis: Average Daily Rate (ADR) by Hotel Rating
-- Set session and formatting for a professional report output
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '.,';
SET LINESIZE 120
SET PAGESIZE 50
SET HEADING ON

-- Clear previous formats to ensure a clean slate
CLEAR COLUMNS
CLEAR BREAKS
CLEAR COMPUTES

TTITLE CENTER 'Tactical Pricing Analysis' SKIP 1 CENTER 'Average Daily Rate (ADR) by Hotel Rating for 2023' SKIP 2

-- Define column formats for perfect alignment
COLUMN Rating FORMAT 9.9 HEADING 'Hotel Rating'
COLUMN Total_Revenue FORMAT $99,999,990.00 HEADING 'Total Revenue'
COLUMN Total_Room_Nights FORMAT 9,999,999 HEADING 'Total Room Nights Sold'
COLUMN ADR FORMAT $99,990.00 HEADING 'Average Daily Rate (ADR)'
COLUMN Pricing_Flag FORMAT A15 HEADING 'Pricing Flag'

-- Use a CTE to aggregate the base metrics needed for ADR calculation
WITH AdrMetrics AS (
    SELECT
        dh.Rating,
        SUM(fbr.BookingTotalAmount) AS Sum_Revenue,
        SUM(fbr.DurationDays) AS Sum_Room_Nights
    FROM
        FactBookingRoom fbr
    JOIN
        DimHotel dh ON fbr.HotelKey = dh.HotelKey
    JOIN
        DimDate dd ON fbr.DateKey = dd.DateKey
    WHERE
        dd.Year = 2023
        AND dh.Rating IS NOT NULL
    GROUP BY
        dh.Rating
)
-- Final SELECT to calculate ADR and apply conditional logic
SELECT
    m.Rating,
    m.Sum_Revenue AS Total_Revenue,
    m.Sum_Room_Nights AS Total_Room_Nights,
    CASE
        WHEN m.Sum_Room_Nights > 0 THEN m.Sum_Revenue / m.Sum_Room_Nights
        ELSE 0
    END AS ADR,
    -- Add a flag to highlight potential issues. The original business rule was too aggressive.
    CASE
        WHEN (m.Sum_Revenue / m.Sum_Room_Nights) < LAG(m.Sum_Revenue / m.Sum_Room_Nights, 1, 9999) OVER (ORDER BY m.Rating DESC)
        THEN 'PRICE INVERSION'
        ELSE 'OK'
    END AS Pricing_Flag
FROM
    AdrMetrics m
ORDER BY
    m.Rating DESC;

-- Turn off the title for subsequent queries
TTITLE OFF