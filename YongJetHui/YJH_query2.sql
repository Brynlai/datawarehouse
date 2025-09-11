SET DEFINE OFF
SET PAGESIZE 35
SET LINESIZE 130
SET VERIFY OFF
SET FEEDBACK OFF
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '.,'

TTITLE CENTER 'Long-Term Holiday vs. Non-Holiday Revenue Growth Trends' SKIP 1 -
       CENTER 'Analysis Period: 2010-2025' SKIP 1 -
       RIGHT 'Date: ' _DATE SKIP 1 -
       RIGHT 'Page: ' FORMAT 999 SQL.PNO SKIP 2

COLUMN "Analysis_Year"             FORMAT 9999     HEADING 'Year'
COLUMN "Holiday_Revenue"           FORMAT A25      HEADING 'Total Holiday Revenue|(RM)'
COLUMN "Holiday_YoY_Growth"        FORMAT A20      HEADING 'Holiday Revenue|YoY Growth (%)'
COLUMN "Non_Holiday_YoY_Growth"    FORMAT A20      HEADING 'Non-Holiday Rev.|YoY Growth (%)'
COLUMN "Holiday_Growth_Premium"    FORMAT A25      HEADING 'Holiday Growth|Premium (%)'

WITH
  YearlyRevenueStreams AS (
    SELECT
      dd.Year,
      SUM(CASE WHEN dd.IsHoliday = 'Y' THEN fbr.CalculatedBookingAmount ELSE 0 END) AS HolidayRevenue,
      SUM(CASE WHEN dd.IsHoliday = 'N' THEN fbr.CalculatedBookingAmount ELSE 0 END) AS NonHolidayRevenue
    FROM FactBookingRoom fbr
    JOIN DimDate dd ON fbr.DateKey = dd.DateKey
    WHERE dd.Year BETWEEN 2010 AND 2025
    GROUP BY dd.Year
  ),
  YearOverYearGrowth AS (
    SELECT
      Year,
      HolidayRevenue,
      LAG(HolidayRevenue, 1, 0) OVER (ORDER BY Year) AS PreviousHolidayRevenue,
      NonHolidayRevenue,
      LAG(NonHolidayRevenue, 1, 0) OVER (ORDER BY Year) AS PreviousNonHolidayRevenue
    FROM YearlyRevenueStreams
  )
SELECT
  yoy.Year AS "Analysis_Year",
  TO_CHAR(yoy.HolidayRevenue, 'FM99,999,990') AS "Holiday_Revenue",
  CASE
    WHEN yoy.PreviousHolidayRevenue = 0 THEN 'N/A'
    ELSE TO_CHAR(((yoy.HolidayRevenue / yoy.PreviousHolidayRevenue) - 1) * 100, 'FMS990.0') || '%'
  END AS "Holiday_YoY_Growth",
  CASE
    WHEN yoy.PreviousNonHolidayRevenue = 0 THEN 'N/A'
    ELSE TO_CHAR(((yoy.NonHolidayRevenue / yoy.PreviousNonHolidayRevenue) - 1) * 100, 'FMS990.0') || '%'
  END AS "Non_Holiday_YoY_Growth",
  TO_CHAR(
    (((yoy.HolidayRevenue / NULLIF(yoy.PreviousHolidayRevenue, 0)) - 1) * 100) -
    (((yoy.NonHolidayRevenue / NULLIF(yoy.PreviousNonHolidayRevenue, 0)) - 1) * 100),
    'FMS990.0'
  ) || '%' AS "Holiday_Growth_Premium"
FROM YearOverYearGrowth yoy
WHERE yoy.Year > 2010 AND yoy.Year < EXTRACT(YEAR FROM SYSDATE)
ORDER BY yoy.Year DESC;

CLEAR COLUMNS; 
TTITLE OFF; 

TTITLE CENTER 'Long-Term Holiday vs. Non-Holiday Average Stay Duration' SKIP 1 -
       CENTER 'Analysis Period: 2010-2025' SKIP 1 -
       RIGHT 'Date: ' _DATE SKIP 1 -
       RIGHT 'Page: ' FORMAT 999 SQL.PNO SKIP 2

COLUMN "Analysis_Year"             FORMAT 9999     HEADING 'Year'
COLUMN "Avg_Holiday_Stay"          FORMAT A25      HEADING 'Avg. Holiday Stay|(Days)'
COLUMN "Avg_Non_Holiday_Stay"      FORMAT A25      HEADING 'Avg. Non-Holiday Stay|(Days)'
COLUMN "Stay_Length_Premium"       FORMAT A25      HEADING 'Stay Length Premium|(%)'

WITH
  YearlyStayDuration AS (
    SELECT
      dd.Year,
      AVG(CASE WHEN dd.IsHoliday = 'Y' THEN fbr.DurationDays END) AS AvgHolidayStay,
      AVG(CASE WHEN dd.IsHoliday = 'N' THEN fbr.DurationDays END) AS AvgNonHolidayStay
    FROM FactBookingRoom fbr
    JOIN DimDate dd ON fbr.DateKey = dd.DateKey
    WHERE dd.Year BETWEEN 2010 AND 2025
    GROUP BY dd.Year
  )
SELECT
  ysd.Year AS "Analysis_Year",
  TO_CHAR(ysd.AvgHolidayStay, 'FM99.9') AS "Avg_Holiday_Stay",
  TO_CHAR(ysd.AvgNonHolidayStay, 'FM99.9') AS "Avg_Non_Holiday_Stay",
  TO_CHAR(((ysd.AvgHolidayStay / ysd.AvgNonHolidayStay) - 1) * 100, 'FMS990.0') || '%' AS "Stay_Length_Premium"
FROM YearlyStayDuration ysd
WHERE ysd.Year > 2010 AND ysd.Year < EXTRACT(YEAR FROM SYSDATE)
ORDER BY ysd.Year DESC;

CLEAR COLUMNS; 
TTITLE OFF; 
BTITLE OFF;