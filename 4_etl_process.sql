-- =================================================================================
-- BAIT3003 DWT Assignment - ETL PROCESSES
-- Student Name: [Your Name]
-- Student ID:   [Your ID]
-- Database:     Oracle 11g
-- Description:  This script contains all ETL procedures for the initial and
--               subsequent loading of the Hotel Analytics Data Warehouse.
-- =================================================================================

-- Set server output on to see execution status messages
SET SERVEROUTPUT ON;

-- =================================================================================
-- Part 1: INITIAL LOADING OF THE DATA WAREHOUSE
--
-- Description: These procedures are designed for a one-time, full load of the
--              data warehouse from the OLTP source. It assumes the DWH tables
--              are empty.
-- Strategy:
-- 1. Truncate all DWH tables to ensure a clean slate.
-- 2. Disable fact table foreign key constraints for performance during bulk load.
-- 3. Load all dimension tables first.
-- 4. Load the fact tables, looking up surrogate keys from the dimensions.
-- 5. Re-enable foreign key constraints.
-- =================================================================================

-- ---------------------------------------------------------------------------------
-- Procedure: P_LOAD_DIM_DATE
-- Description: Populates the Date Dimension table. This dimension is not sourced
--              from the OLTP but is generated programmatically to cover the
--              entire date range of the business data.
-- ---------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE P_LOAD_DIM_DATE (
    p_start_date IN DATE,
    p_end_date   IN DATE
) AS
    v_current_date DATE := p_start_date;
BEGIN
    WHILE v_current_date <= p_end_date LOOP
        INSERT INTO DimDate (
            DateKey,
            FullDate,
            Year,
            Quarter,
            Month,
            MonthName,
            DayOfMonth,
            DayOfYear,
            DayOfWeek,
            DayName,
            IsWeekend,
            IsHoliday,
            HolidayName,
            WeekOfYear,
            LastDayOfMonth,
            FestivalEvent
        ) VALUES (
            TO_NUMBER(TO_CHAR(v_current_date, 'YYYYMMDD')), -- Use a deterministic key
            v_current_date,
            TO_NUMBER(TO_CHAR(v_current_date, 'YYYY')),
            TO_NUMBER(TO_CHAR(v_current_date, 'Q')),
            TO_NUMBER(TO_CHAR(v_current_date, 'MM')),
            TO_CHAR(v_current_date, 'Month'),
            TO_NUMBER(TO_CHAR(v_current_date, 'DD')),
            TO_NUMBER(TO_CHAR(v_current_date, 'DDD')),
            TO_NUMBER(TO_CHAR(v_current_date, 'D')),
            TO_CHAR(v_current_date, 'Day'),
            CASE WHEN TO_CHAR(v_current_date, 'D') IN ('1', '7') THEN 'Y' ELSE 'N' END, -- Assuming Sunday(1) and Saturday(7) are weekends
            CASE
                WHEN TO_CHAR(v_current_date, 'MMDD') = '0101' THEN 'Y'
                WHEN TO_CHAR(v_current_date, 'MMDD') = '1225' THEN 'Y'
                ELSE 'N'
            END,
            CASE
                WHEN TO_CHAR(v_current_date, 'MMDD') = '0101' THEN 'New Year''s Day'
                WHEN TO_CHAR(v_current_date, 'MMDD') = '1225' THEN 'Christmas Day'
                ELSE NULL
            END,
            TO_NUMBER(TO_CHAR(v_current_date, 'WW')),
            LAST_DAY(v_current_date),
            NULL -- Can be populated with specific events later
        );
        v_current_date := v_current_date + 1;
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('DimDate loaded successfully.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error loading DimDate: ' || SQLERRM);
        ROLLBACK;
END P_LOAD_DIM_DATE;
/

-- ---------------------------------------------------------------------------------
-- Procedure: P_INITIAL_LOAD_DIMENSIONS
-- Description: Loads all dimension tables (except DimDate) from the OLTP source.
--              This includes Guest, Hotel, and the SCD Type 2 dimensions Room and Facility.
-- ---------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE P_INITIAL_LOAD_DIMENSIONS AS
BEGIN
    -- (1) Load DimGuest
    INSERT INTO DimGuest (GuestID, GuestFullName, State, Country, Region)
    SELECT
        guest_id,
        first_name || ' ' || last_name,
        state,
        country,
        region
    FROM Guest;
    DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT || ' rows inserted into DimGuest.');

    -- (2) Load DimHotel
    INSERT INTO DimHotel (HotelID, City, Region, State, Country, PostalCode, Rating, Email, Phone)
    SELECT
        hotel_id,
        city,
        region,
        state,
        country,
        postal_code,
        rating,
        email,
        phone
    FROM Hotel;
    DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT || ' rows inserted into DimHotel.');

    -- (3) Load DimRoom (SCD Type 2)
    -- For initial load, all records are current.
    INSERT INTO DimRoom (RoomID, RoomType, BedCount, HotelID, EffectiveDate, ExpiryDate, CurrentFlag)
    SELECT
        room_id,
        room_type,
        bed_count,
        hotel_id,
        TO_DATE('2000-01-01', 'YYYY-MM-DD'), -- Effective since the beginning
        NULL, -- No expiry date
        'Y'   -- Currently active
    FROM Room;
    DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT || ' rows inserted into DimRoom.');

    -- (4) Load DimFacility (SCD Type 2) - This includes a transformation step.
    INSERT INTO DimFacility (FacilityID, FacilityName, FacilityType, HotelID, EffectiveDate, ExpiryDate, CurrentFlag)
    SELECT
        service_id,
        service_name,
        CASE
            WHEN service_name IN ('Gym Access', 'Spa Treatment', 'Bike Rental') THEN 'Recreation'
            WHEN service_name IN ('Conference Room Rental') THEN 'Business'
            WHEN service_name IN ('Room Service') THEN 'Dining'
            ELSE 'Wellness' -- A default category
        END AS FacilityType, -- Transformation
        hotel_id,
        TO_DATE('2000-01-01', 'YYYY-MM-DD'),
        NULL,
        'Y'
    FROM Service;
    DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT || ' rows inserted into DimFacility.');

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('All dimensions loaded successfully.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error during dimension initial load: ' || SQLERRM);
        ROLLBACK;
END P_INITIAL_LOAD_DIMENSIONS;
/

-- ---------------------------------------------------------------------------------
-- Procedure: P_INITIAL_LOAD_FACTS
-- Description: Loads both fact tables by joining OLTP tables and looking up
--              surrogate keys from the already-populated dimension tables.
-- ---------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE P_INITIAL_LOAD_FACTS AS
BEGIN
    -- (1) Load FactBookingRoom
    INSERT INTO FactBookingRoom (GuestKey, HotelKey, RoomKey, DateKey, BookingID, BookingDetailID, DurationDays, RoomPricePerNight, BookingTotalAmount)
    SELECT
        dg.GuestKey,
        dh.HotelKey,
        dr.RoomKey,
        dd.DateKey,
        bd.booking_id,
        bd.room_id, -- Using room_id as a degenerate dimension for BookingDetailID
        bd.duration_days,
        r.price,
        b.total_price
    FROM BookingDetail bd
    JOIN Booking b ON bd.booking_id = b.booking_id
    JOIN Room r ON bd.room_id = r.room_id
    JOIN DimGuest dg ON b.guest_id = dg.GuestID
    JOIN DimHotel dh ON r.hotel_id = dh.HotelID
    JOIN DimRoom dr ON r.room_id = dr.RoomID AND dr.CurrentFlag = 'Y' -- Join with the current version
    JOIN DimDate dd ON TRUNC(bd.checkin_date) = dd.FullDate;
    DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT || ' rows inserted into FactBookingRoom.');

    -- (2) Load FactFacilityBooking
    INSERT INTO FactFacilityBooking (GuestKey, FacilityKey, HotelKey, DateKey, FacilityBookingID, BookingFee, DurationHours)
    SELECT
        dg.GuestKey,
        df.FacilityKey,
        dh.HotelKey,
        dd.DateKey,
        gs.service_id, -- Using service_id as a degenerate dimension for FacilityBookingID
        s.service_price,
        NULL -- DurationHours not available in OLTP, can be added later
    FROM GuestService gs
    JOIN Service s ON gs.service_id = s.service_id
    JOIN DimGuest dg ON gs.guest_id = dg.GuestID
    JOIN DimFacility df ON s.service_id = df.FacilityID AND df.CurrentFlag = 'Y'
    JOIN DimHotel dh ON s.hotel_id = dh.HotelID
    JOIN DimDate dd ON TRUNC(gs.usage_date) = dd.FullDate;
    DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT || ' rows inserted into FactFacilityBooking.');

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('All fact tables loaded successfully.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error during fact initial load: ' || SQLERRM);
        ROLLBACK;
END P_INITIAL_LOAD_FACTS;
/

-- ---------------------------------------------------------------------------------
-- Master Procedure: P_RUN_INITIAL_LOAD
-- Description: Executes the entire initial loading process in the correct sequence.
-- ---------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE P_RUN_INITIAL_LOAD AS
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Starting Initial Data Warehouse Load ---');

    -- Step 1: Disable FK constraints on Fact tables
    EXECUTE IMMEDIATE 'ALTER TABLE FactBookingRoom DISABLE CONSTRAINT fk_fb_guest';
    EXECUTE IMMEDIATE 'ALTER TABLE FactBookingRoom DISABLE CONSTRAINT fk_fb_hotel';
    EXECUTE IMMEDIATE 'ALTER TABLE FactBookingRoom DISABLE CONSTRAINT fk_fb_room';
    EXECUTE IMMEDIATE 'ALTER TABLE FactBookingRoom DISABLE CONSTRAINT fk_fb_date';
    EXECUTE IMMEDIATE 'ALTER TABLE FactFacilityBooking DISABLE CONSTRAINT fk_ffb_guest';
    EXECUTE IMMEDIATE 'ALTER TABLE FactFacilityBooking DISABLE CONSTRAINT fk_ffb_facility';
    EXECUTE IMMEDIATE 'ALTER TABLE FactFacilityBooking DISABLE CONSTRAINT fk_ffb_hotel';
    EXECUTE IMMEDIATE 'ALTER TABLE FactFacilityBooking DISABLE CONSTRAINT fk_ffb_date';
    DBMS_OUTPUT.PUT_LINE('Fact table constraints disabled.');

    -- Step 2: Truncate all DWH tables
    EXECUTE IMMEDIATE 'TRUNCATE TABLE FactBookingRoom';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE FactFacilityBooking';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE DimFacility';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE DimRoom';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE DimHotel';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE DimGuest';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE DimDate';
    DBMS_OUTPUT.PUT_LINE('All DWH tables truncated.');

    -- Step 3: Load Dimensions
    P_LOAD_DIM_DATE(TO_DATE('2020-01-01', 'YYYY-MM-DD'), TO_DATE('2024-12-31', 'YYYY-MM-DD'));
    P_INITIAL_LOAD_DIMENSIONS;

    -- Step 4: Load Facts
    P_INITIAL_LOAD_FACTS;

    -- Step 5: Re-enable FK constraints and validate
    EXECUTE IMMEDIATE 'ALTER TABLE FactBookingRoom ENABLE VALIDATE CONSTRAINT fk_fb_guest';
    EXECUTE IMMEDIATE 'ALTER TABLE FactBookingRoom ENABLE VALIDATE CONSTRAINT fk_fb_hotel';
    EXECUTE IMMEDIATE 'ALTER TABLE FactBookingRoom ENABLE VALIDATE CONSTRAINT fk_fb_room';
    EXECUTE IMMEDIATE 'ALTER TABLE FactBookingRoom ENABLE VALIDATE CONSTRAINT fk_fb_date';
    EXECUTE IMMEDIATE 'ALTER TABLE FactFacilityBooking ENABLE VALIDATE CONSTRAINT fk_ffb_guest';
    EXECUTE IMMEDIATE 'ALTER TABLE FactFacilityBooking ENABLE VALIDATE CONSTRAINT fk_ffb_facility';
    EXECUTE IMMEDIATE 'ALTER TABLE FactFacilityBooking ENABLE VALIDATE CONSTRAINT fk_ffb_hotel';
    EXECUTE IMMEDIATE 'ALTER TABLE FactFacilityBooking ENABLE VALIDATE CONSTRAINT fk_ffb_date';
    DBMS_OUTPUT.PUT_LINE('Fact table constraints re-enabled.');

    DBMS_OUTPUT.PUT_LINE('--- Initial Data Warehouse Load Completed Successfully ---');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('FATAL ERROR during initial load: ' || SQLERRM);
        -- Attempt to re-enable constraints even on failure
        EXECUTE IMMEDIATE 'ALTER TABLE FactBookingRoom ENABLE VALIDATE CONSTRAINT fk_fb_guest';
        EXECUTE IMMEDIATE 'ALTER TABLE FactBookingRoom ENABLE VALIDATE CONSTRAINT fk_fb_hotel';
        EXECUTE IMMEDIATE 'ALTER TABLE FactBookingRoom ENABLE VALIDATE CONSTRAINT fk_fb_room';
        EXECUTE IMMEDIATE 'ALTER TABLE FactBookingRoom ENABLE VALIDATE CONSTRAINT fk_fb_date';
        EXECUTE IMMEDIATE 'ALTER TABLE FactFacilityBooking ENABLE VALIDATE CONSTRAINT fk_ffb_guest';
        EXECUTE IMMEDIATE 'ALTER TABLE FactFacilityBooking ENABLE VALIDATE CONSTRAINT fk_ffb_facility';
        EXECUTE IMMEDIATE 'ALTER TABLE FactFacilityBooking ENABLE VALIDATE CONSTRAINT fk_ffb_hotel';
        EXECUTE IMMEDIATE 'ALTER TABLE FactFacilityBooking ENABLE VALIDATE CONSTRAINT fk_ffb_date';
END P_RUN_INITIAL_LOAD;
/


-- =================================================================================
-- Part 2: SUBSEQUENT LOADING OF THE DATA WAREHOUSE
--
-- Description: These procedures are for incremental (delta) loads. They handle
--              new records, updated records (SCD1 and SCD2), and demonstrate
--              a basic data scrubbing technique using a VIEW.
-- Strategy:
-- 1. Use MERGE statement for SCD Type 1 dimensions (DimGuest, DimHotel) to
--    insert new records and update existing ones.
-- 2. Use a two-step MERGE/INSERT process for SCD Type 2 dimensions (DimRoom)
--    to expire old records and insert new versions for any changes.
-- 3. Insert only new fact records that do not already exist in the fact tables.
-- =================================================================================

-- ---------------------------------------------------------------------------------
-- View: V_CLEANSED_GUEST
-- Description: A data scrubbing/transformation view. Here, we ensure the country
--              and state names are in uppercase and handle potential NULL regions
--              by replacing them with 'N/A'. This demonstrates data cleansing.
-- ---------------------------------------------------------------------------------
CREATE OR REPLACE VIEW V_CLEANSED_GUEST AS
SELECT
    guest_id,
    first_name,
    last_name,
    UPPER(state) AS state,
    UPPER(country) AS country,
    NVL(region, 'N/A') AS region
FROM
    Guest;
/

-- ---------------------------------------------------------------------------------
-- Procedure: P_SUBSEQUENT_LOAD_DIMENSIONS
-- Description: Handles incremental loads for all dimension tables.
-- ---------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE P_SUBSEQUENT_LOAD_DIMENSIONS AS
BEGIN
    -- (1) Load DimGuest (SCD Type 1) using MERGE and the cleansing view
    MERGE INTO DimGuest d
    USING V_CLEANSED_GUEST s ON (d.GuestID = s.guest_id)
    WHEN MATCHED THEN
        UPDATE SET
            d.GuestFullName = s.first_name || ' ' || s.last_name,
            d.State = s.state,
            d.Country = s.country,
            d.Region = s.region
        WHERE
            d.GuestFullName <> (s.first_name || ' ' || s.last_name) OR
            d.State <> s.state OR
            d.Country <> s.country OR
            d.Region <> s.region
    WHEN NOT MATCHED THEN
        INSERT (GuestID, GuestFullName, State, Country, Region)
        VALUES (s.guest_id, s.first_name || ' ' || s.last_name, s.state, s.country, s.region);
    DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT || ' rows merged into DimGuest.');

    -- (2) Load DimHotel (SCD Type 1) using MERGE
    MERGE INTO DimHotel d
    USING Hotel s ON (d.HotelID = s.hotel_id)
    WHEN MATCHED THEN
        UPDATE SET
            d.Rating = s.rating,
            d.Email = s.email,
            d.Phone = s.phone
        WHERE
            NVL(d.Rating, -1) <> NVL(s.rating, -1) OR
            d.Email <> s.email OR
            d.Phone <> s.phone
    WHEN NOT MATCHED THEN
        INSERT (HotelID, City, Region, State, Country, PostalCode, Rating, Email, Phone)
        VALUES (s.hotel_id, s.city, s.region, s.state, s.country, s.postal_code, s.rating, s.email, s.phone);
    DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT || ' rows merged into DimHotel.');

    -- (3) Load DimRoom (SCD Type 2) - Two-Step Process
    -- Step 3a: Expire old records for rooms that have changed and insert brand new rooms.
    MERGE INTO DimRoom dr
    USING Room r ON (dr.RoomID = r.room_id AND dr.CurrentFlag = 'Y')
    WHEN MATCHED THEN
        UPDATE SET
            dr.CurrentFlag = 'N',
            dr.ExpiryDate = SYSDATE - 1
        WHERE
            dr.RoomType <> r.room_type OR dr.BedCount <> r.bed_count
    WHEN NOT MATCHED THEN
        INSERT (RoomID, RoomType, BedCount, HotelID, EffectiveDate, ExpiryDate, CurrentFlag)
        VALUES (r.room_id, r.room_type, r.bed_count, r.hotel_id, SYSDATE, NULL, 'Y');
    DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT || ' rows merged for SCD2 Step 1 (DimRoom).');

    -- Step 3b: Insert the new version of the records that were just expired.
    INSERT INTO DimRoom (RoomID, RoomType, BedCount, HotelID, EffectiveDate, ExpiryDate, CurrentFlag)
    SELECT
        r.room_id,
        r.room_type,
        r.bed_count,
        r.hotel_id,
        SYSDATE, -- Effective from today
        NULL,    -- Not expired
        'Y'      -- Is the current version
    FROM Room r
    JOIN DimRoom dr ON r.room_id = dr.RoomID
    WHERE dr.ExpiryDate = SYSDATE - 1; -- Find the records we just expired in the previous step
    DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT || ' rows inserted for SCD2 Step 2 (DimRoom).');

    -- (4) Implement SCD Type 2 for DimFacility (if needed, logic is identical to DimRoom)
    -- For this assignment, we assume facilities do not change frequently.
    -- The logic would be the same as for DimRoom if attributes were expected to change.

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Subsequent dimension load completed.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error during subsequent dimension load: ' || SQLERRM);
        ROLLBACK;
END P_SUBSEQUENT_LOAD_DIMENSIONS;
/

-- ---------------------------------------------------------------------------------
-- Procedure: P_SUBSEQUENT_LOAD_FACTS
-- Description: Inserts only new fact records into the fact tables.
-- ---------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE P_SUBSEQUENT_LOAD_FACTS AS
BEGIN
    -- (1) Load new records into FactBookingRoom
    INSERT INTO FactBookingRoom (GuestKey, HotelKey, RoomKey, DateKey, BookingID, BookingDetailID, DurationDays, RoomPricePerNight, BookingTotalAmount)
    SELECT
        dg.GuestKey,
        dh.HotelKey,
        dr.RoomKey,
        dd.DateKey,
        bd.booking_id,
        bd.room_id,
        bd.duration_days,
        r.price,
        b.total_price
    FROM BookingDetail bd
    JOIN Booking b ON bd.booking_id = b.booking_id
    JOIN Room r ON bd.room_id = r.room_id
    JOIN DimGuest dg ON b.guest_id = dg.GuestID
    JOIN DimHotel dh ON r.hotel_id = dh.HotelID
    JOIN DimRoom dr ON r.room_id = dr.RoomID AND dr.CurrentFlag = 'Y'
    JOIN DimDate dd ON TRUNC(bd.checkin_date) = dd.FullDate
    -- This condition ensures we only insert new records
    WHERE NOT EXISTS (
        SELECT 1 FROM FactBookingRoom fbr
        WHERE fbr.BookingID = bd.booking_id AND fbr.BookingDetailID = bd.room_id
    );
    DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT || ' new rows inserted into FactBookingRoom.');

    -- (2) Load new records into FactFacilityBooking
    -- Using LEFT JOIN IS NULL pattern, an alternative to NOT EXISTS
    INSERT INTO FactFacilityBooking (GuestKey, FacilityKey, HotelKey, DateKey, FacilityBookingID, BookingFee, DurationHours)
    SELECT
        dg.GuestKey,
        df.FacilityKey,
        dh.HotelKey,
        dd.DateKey,
        gs.service_id,
        s.service_price,
        NULL
    FROM GuestService gs
    JOIN Service s ON gs.service_id = s.service_id
    JOIN DimGuest dg ON gs.guest_id = dg.GuestID
    JOIN DimFacility df ON s.service_id = df.FacilityID AND df.CurrentFlag = 'Y'
    JOIN DimHotel dh ON s.hotel_id = dh.HotelID
    JOIN DimDate dd ON TRUNC(gs.usage_date) = dd.FullDate
    LEFT JOIN FactFacilityBooking ffb ON
        ffb.GuestKey = dg.GuestKey AND
        ffb.FacilityKey = df.FacilityKey AND
        ffb.DateKey = dd.DateKey AND
        ffb.FacilityBookingID = gs.service_id
    WHERE ffb.GuestKey IS NULL; -- Only insert if no match is found
    DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT || ' new rows inserted into FactFacilityBooking.');

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Subsequent fact load completed.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error during subsequent fact load: ' || SQLERRM);
        ROLLBACK;
END P_SUBSEQUENT_LOAD_FACTS;
/

-- ---------------------------------------------------------------------------------
-- Master Procedure: P_RUN_SUBSEQUENT_LOAD
-- Description: Executes the entire subsequent loading process in the correct sequence.
-- ---------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE P_RUN_SUBSEQUENT_LOAD AS
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Starting Subsequent Data Warehouse Load ---');

    -- Step 1: Load/Update Dimensions
    P_SUBSEQUENT_LOAD_DIMENSIONS;

    -- Step 2: Load new Facts
    P_SUBSEQUENT_LOAD_FACTS;

    DBMS_OUTPUT.PUT_LINE('--- Subsequent Data Warehouse Load Completed Successfully ---');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('FATAL ERROR during subsequent load: ' || SQLERRM);
END P_RUN_SUBSEQUENT_LOAD;
/

-- =================================================================================
-- Execution Block
-- To run the ETL, you would execute one of the following commands:
--
-- For the first-time load:
-- BEGIN
--     P_RUN_INITIAL_LOAD;
-- END;
-- /
--
-- For all future daily/weekly loads:
-- BEGIN
--     P_RUN_SUBSEQUENT_LOAD;
-- END;
-- /
-- =================================================================================