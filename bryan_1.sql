-- Report 1: Strategic Performance Review: Year-over-Year (YoY) Revenue Growth
-- Set session and formatting for a professional report output
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '.,';
SET LINESIZE 130
SET PAGESIZE 50
SET HEADING ON

-- Clear previous formats to ensure a clean slate
CLEAR COLUMNS
CLEAR BREAKS
CLEAR COMPUTES

TTITLE CENTER 'Strategic Performance Report' SKIP 1 CENTER 'Year-over-Year Room Revenue Growth by Country (2023 vs 2022)' SKIP 2

-- Define column formats for perfect alignment and readability
-- A25 for country gives ample space.
-- 999,999,990.00 forces right-alignment for numbers.
-- A15 for the growth string allows for right-padding.
COLUMN Country FORMAT A40 HEADING 'Country'
COLUMN Revenue_Year FORMAT 9999 HEADING 'Year'
COLUMN Total_Revenue FORMAT 999,999,990.00 HEADING '2023 Revenue'
COLUMN Previous_Year_Revenue FORMAT 999,999,990.00 HEADING '2022 Revenue'
COLUMN YoY_Growth_Percentage FORMAT A15 HEADING 'YoY Growth (%)'

-- Use a CTE to first aggregate revenue by country and year
WITH CountryYearlyRevenue AS (
    SELECT
        dh.Country,
        dd.Year AS Revenue_Year,
        SUM(fbr.BookingTotalAmount) AS Annual_Revenue
    FROM
        FactBookingRoom fbr
    JOIN
        DimHotel dh ON fbr.HotelKey = dh.HotelKey
    JOIN
        DimDate dd ON fbr.DateKey = dd.DateKey
    WHERE
        dd.Year IN (2022, 2023)
    GROUP BY
        dh.Country,
        dd.Year
),
-- Use a second CTE with the LAG() window function to get the previous year's data
YoY_Comparison AS (
    SELECT
        Country,
        Revenue_Year,
        Annual_Revenue,
        LAG(Annual_Revenue, 1, 0) OVER (PARTITION BY Country ORDER BY Revenue_Year) AS Previous_Year_Revenue
    FROM
        CountryYearlyRevenue
)
-- Final SELECT to calculate the growth percentage and format the output
SELECT
    c.Country,
    c.Revenue_Year,
    c.Annual_Revenue AS Total_Revenue,
    c.Previous_Year_Revenue,
    -- Use LPAD to right-align the text-based percentage for clean viewing
    LPAD(
        CASE
            WHEN c.Previous_Year_Revenue > 0
            THEN TO_CHAR(((c.Annual_Revenue - c.Previous_Year_Revenue) / c.Previous_Year_Revenue) * 100, '990.00') || '%'
            ELSE 'N/A (New Market)'
        END, 15, ' ') AS YoY_Growth_Percentage
FROM
    YoY_Comparison c
WHERE
    c.Revenue_Year = 2023
ORDER BY
    ((c.Annual_Revenue - c.Previous_Year_Revenue) / c.Previous_Year_Revenue) DESC;

-- Turn off the title for subsequent queries
TTITLE OFF