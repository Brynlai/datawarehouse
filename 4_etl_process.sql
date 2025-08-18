-- =================================================================================
-- ETL PROCESSES (REVISED PER PRACTICAL 6)
-- Database:     Oracle 11g
-- Description:  This script contains all ETL procedures for the initial and
--               subsequent loading of the Hotel Analytics Data Warehouse.
--
-- REVISIONS:
-- 1. ETL is now aligned with the strict integrity model from the practical.
-- 2. Removed 'Unknown Member' logic as it's incompatible with direct FKs.
-- 3. Reverted dimension lookups in Fact loads to INNER JOINs. An ETL failure
--    will occur on data mismatch, which is the expected behavior in this model.
-- =================================================================================

-- Set server output on to see execution status messages
SET SERVEROUTPUT ON;

-- =================================================================================
-- Part 1: INITIAL LOADING OF THE DATA WAREHOUSE
-- =================================================================================

-- ---------------------------------------------------------------------------------
-- Procedure: P_LOAD_DIM_DATE
-- ---------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE P_LOAD_DIM_DATE (
    p_start_date IN DATE,
    p_end_date   IN DATE
) AS
    v_current_date DATE := p_start_date;
BEGIN
    WHILE v_current_date <= p_end_date LOOP
        INSERT INTO DimDate (
            DateKey, FullDate, Year, Quarter, Month, MonthName,
            DayOfMonth, DayOfYear, DayOfWeek, DayName, IsWeekend, IsHoliday,
            WeekOfYear, LastDayOfMonth, FestivalEvent
        ) VALUES (
            TO_NUMBER(TO_CHAR(v_current_date, 'YYYYMMDD')), v_current_date,
            TO_NUMBER(TO_CHAR(v_current_date, 'YYYY')), TO_NUMBER(TO_CHAR(v_current_date, 'Q')),
            TO_NUMBER(TO_CHAR(v_current_date, 'MM')), TO_CHAR(v_current_date, 'Month'),
            TO_NUMBER(TO_CHAR(v_current_date, 'DD')), TO_NUMBER(TO_CHAR(v_current_date, 'DDD')),
            TO_NUMBER(TO_CHAR(v_current_date, 'D')), TO_CHAR(v_current_date, 'Day'),
            CASE WHEN TO_CHAR(v_current_date, 'D') IN ('1', '7') THEN 'Y' ELSE 'N' END,
            CASE WHEN TO_CHAR(v_current_date, 'MMDD') IN ('0101', '1225') THEN 'Y' ELSE 'N' END,
            TO_NUMBER(TO_CHAR(v_current_date, 'WW')), LAST_DAY(v_current_date),
            CASE
                WHEN TO_CHAR(v_current_date, 'MMDD') = '0101' THEN 'New Year''s Day'
                WHEN TO_CHAR(v_current_date, 'MMDD') = '1225' THEN 'Christmas Day'
                ELSE NULL
            END
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
-- REVISED: Removed 'Unknown Member' records.
-- ---------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE P_INITIAL_LOAD_DIMENSIONS AS
BEGIN
    -- (1) Load DimGuest
    INSERT INTO DimGuest (GuestID, GuestFullName, State, Country, Region)
    SELECT guest_id, first_name || ' ' || last_name, state, country, region
    FROM Guest;
    DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT || ' rows inserted into DimGuest.');

    -- (2) Load DimHotel
    INSERT INTO DimHotel (HotelID, City, Region, State, Country, PostalCode, Rating, Email, Phone)
    SELECT hotel_id, city, region, state, country, postal_code, rating, email, phone
    FROM Hotel;
    DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT || ' rows inserted into DimHotel.');

    -- (3) Load DimRoom (SCD Type 2)
    INSERT INTO DimRoom (RoomID, RoomType, BedCount, EffectiveDate, ExpiryDate, CurrentFlag)
    SELECT
        room_id,
        room_type,
        bed_count,
        TO_DATE('2000-01-01', 'YYYY-MM-DD'),
        TO_DATE('9999-12-31', 'YYYY-MM-DD'), -- Use far-future date
        'Y'
    FROM Room;
    DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT || ' rows inserted into DimRoom.');

    -- (4) Load DimFacility (SCD Type 1)
    INSERT INTO DimFacility (FacilityID, FacilityName, FacilityType)
    SELECT
        service_id,
        service_name,
        service_type
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
-- REVISED: Reverted to INNER JOINs to align with the strict FK model.
-- ---------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE P_INITIAL_LOAD_FACTS AS
BEGIN
    -- (1) Load FactBookingRoom
    INSERT INTO FactBookingRoom (GuestKey, HotelKey, RoomKey, DateKey, BookingID, BookingDetailID, DurationDays, RoomPricePerNight, CalculatedBookingAmount)
    SELECT
        dg.GuestKey,
        dh.HotelKey,
        dr.RoomKey,
        dd.DateKey,
        bd.booking_id,
        bd.room_id,
        bd.duration_days,
        r.price,
        (bd.duration_days * r.price) -- Calculated in ETL
    FROM BookingDetail bd
    JOIN Booking b ON bd.booking_id = b.booking_id
    JOIN Room r ON bd.room_id = r.room_id
    JOIN DimGuest dg ON b.guest_id = dg.GuestID
    JOIN DimHotel dh ON r.hotel_id = dh.HotelID
    JOIN DimRoom dr ON r.room_id = dr.RoomID AND dr.CurrentFlag = 'Y'
    JOIN DimDate dd ON TRUNC(bd.checkin_date) = dd.FullDate;
    DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT || ' rows inserted into FactBookingRoom.');

    -- (2) Load FactFacilityBooking
    INSERT INTO FactFacilityBooking (GuestKey, FacilityKey, HotelKey, DateKey, FacilityBookingID, FacilityQuantity, FacilityUnitPrice, FacilityTotalAmount)
    SELECT
        dg.GuestKey,
        df.FacilityKey,
        dh.HotelKey,
        dd.DateKey,
        gs.service_id,
        gs.quantity,
        s.service_price,
        gs.total_amount
    FROM GuestService gs
    JOIN Service s ON gs.service_id = s.service_id
    JOIN DimGuest dg ON gs.guest_id = dg.GuestID
    JOIN DimFacility df ON s.service_id = df.FacilityID
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
-- ---------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE P_RUN_INITIAL_LOAD AS
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Starting Initial Data Warehouse Load ---');
    EXECUTE IMMEDIATE 'ALTER TABLE FactBookingRoom DISABLE CONSTRAINT fk_fb_guest';
    EXECUTE IMMEDIATE 'ALTER TABLE FactBookingRoom DISABLE CONSTRAINT fk_fb_hotel';
    EXECUTE IMMEDIATE 'ALTER TABLE FactBookingRoom DISABLE CONSTRAINT fk_fb_room';
    EXECUTE IMMEDIATE 'ALTER TABLE FactBookingRoom DISABLE CONSTRAINT fk_fb_date';
    EXECUTE IMMEDIATE 'ALTER TABLE FactFacilityBooking DISABLE CONSTRAINT fk_ffb_guest';
    EXECUTE IMMEDIATE 'ALTER TABLE FactFacilityBooking DISABLE CONSTRAINT fk_ffb_facility';
    EXECUTE IMMEDIATE 'ALTER TABLE FactFacilityBooking DISABLE CONSTRAINT fk_ffb_hotel';
    EXECUTE IMMEDIATE 'ALTER TABLE FactFacilityBooking DISABLE CONSTRAINT fk_ffb_date';
    DBMS_OUTPUT.PUT_LINE('Fact table constraints disabled.');

    EXECUTE IMMEDIATE 'TRUNCATE TABLE FactBookingRoom';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE FactFacilityBooking';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE DimFacility';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE DimRoom';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE DimHotel';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE DimGuest';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE DimDate';
    DBMS_OUTPUT.PUT_LINE('All DWH tables truncated.');

    P_LOAD_DIM_DATE(TO_DATE('2010-01-01', 'YYYY-MM-DD'), TO_DATE('2025-12-31', 'YYYY-MM-DD'));
    P_INITIAL_LOAD_DIMENSIONS;
    P_INITIAL_LOAD_FACTS;

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
END P_RUN_INITIAL_LOAD;
/


-- =================================================================================
-- Part 2: SUBSEQUENT LOADING OF THE DATA WAREHOUSE
-- =================================================================================
CREATE OR REPLACE VIEW V_CLEANSED_GUEST AS
SELECT
    guest_id, first_name, last_name, UPPER(state) AS state,
    UPPER(country) AS country, NVL(region, 'N/A') AS region
FROM Guest;
/

-- ---------------------------------------------------------------------------------
-- Procedure: P_SUBSEQUENT_LOAD_DIMENSIONS
-- ---------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE P_SUBSEQUENT_LOAD_DIMENSIONS AS
BEGIN
    -- (1) Load DimGuest (SCD Type 1)
    MERGE INTO DimGuest d
    USING V_CLEANSED_GUEST s ON (d.GuestID = s.guest_id)
    WHEN MATCHED THEN
        UPDATE SET
            d.GuestFullName = s.first_name || ' ' || s.last_name,
            d.State = s.state, d.Country = s.country, d.Region = s.region
        WHERE d.GuestFullName <> (s.first_name || ' ' || s.last_name)
           OR NVL(d.State, ' ') <> NVL(s.state, ' ')
           OR NVL(d.Country, ' ') <> NVL(s.country, ' ')
           OR NVL(d.Region, ' ') <> NVL(s.region, ' ')
    WHEN NOT MATCHED THEN
        INSERT (GuestID, GuestFullName, State, Country, Region)
        VALUES (s.guest_id, s.first_name || ' ' || s.last_name, s.state, s.country, s.region);
    DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT || ' rows merged into DimGuest.');

    -- (2) Load DimHotel (SCD Type 1)
    MERGE INTO DimHotel d
    USING Hotel s ON (d.HotelID = s.hotel_id)
    WHEN MATCHED THEN
        UPDATE SET d.Rating = s.rating, d.Email = s.email, d.Phone = s.phone
        WHERE NVL(d.Rating, -1) <> NVL(s.rating, -1) OR d.Email <> s.email OR d.Phone <> s.phone
    WHEN NOT MATCHED THEN
        INSERT (HotelID, City, Region, State, Country, PostalCode, Rating, Email, Phone)
        VALUES (s.hotel_id, s.city, s.region, s.state, s.country, s.postal_code, s.rating, s.email, s.phone);
    DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT || ' rows merged into DimHotel.');

    -- (3) Load DimRoom (SCD Type 2)
    UPDATE DimRoom dr SET dr.CurrentFlag = 'N', dr.ExpiryDate = SYSDATE - 1
    WHERE dr.CurrentFlag = 'Y'
      AND EXISTS (
          SELECT 1 FROM Room r
          WHERE r.room_id = dr.RoomID AND (r.room_type <> dr.RoomType OR r.bed_count <> dr.BedCount)
      );
    DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT || ' old row(s) expired in DimRoom.');

    INSERT INTO DimRoom (RoomID, RoomType, BedCount, EffectiveDate, ExpiryDate, CurrentFlag)
    SELECT
        r.room_id, r.room_type, r.bed_count,
        SYSDATE, TO_DATE('9999-12-31', 'YYYY-MM-DD'), 'Y'
    FROM Room r WHERE NOT EXISTS (SELECT 1 FROM DimRoom dr WHERE dr.RoomID = r.room_id AND dr.CurrentFlag = 'Y');
    DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT || ' new/updated row(s) inserted into DimRoom.');

    -- (4) Load DimFacility (SCD Type 1)
    MERGE INTO DimFacility d
    USING (SELECT service_id, service_name, service_type FROM Service) s ON (d.FacilityID = s.service_id)
    WHEN MATCHED THEN
        UPDATE SET d.FacilityName = s.service_name, d.FacilityType = s.service_type
        WHERE d.FacilityName <> s.service_name OR d.FacilityType <> s.service_type
    WHEN NOT MATCHED THEN
        INSERT (FacilityID, FacilityName, FacilityType)
        VALUES (s.service_id, s.service_name, s.service_type);
    DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT || ' rows merged into DimFacility.');

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
-- REVISED: Reverted to INNER JOINs.
-- ---------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE P_SUBSEQUENT_LOAD_FACTS AS
BEGIN
    -- (1) Load new records into FactBookingRoom
    INSERT INTO FactBookingRoom (GuestKey, HotelKey, RoomKey, DateKey, BookingID, BookingDetailID, DurationDays, RoomPricePerNight, CalculatedBookingAmount)
    SELECT
        dg.GuestKey, dh.HotelKey, dr.RoomKey, dd.DateKey,
        bd.booking_id, bd.room_id, bd.duration_days, r.price, (bd.duration_days * r.price)
    FROM BookingDetail bd
    JOIN Booking b ON bd.booking_id = b.booking_id
    JOIN Room r ON bd.room_id = r.room_id
    JOIN DimGuest dg ON b.guest_id = dg.GuestID
    JOIN DimHotel dh ON r.hotel_id = dh.HotelID
    JOIN DimRoom dr ON r.room_id = dr.RoomID AND dr.CurrentFlag = 'Y'
    JOIN DimDate dd ON TRUNC(bd.checkin_date) = dd.FullDate
    WHERE NOT EXISTS (
        SELECT 1 FROM FactBookingRoom fbr
        WHERE fbr.BookingID = bd.booking_id AND fbr.BookingDetailID = bd.room_id
    );
    DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT || ' new rows inserted into FactBookingRoom.');

    -- (2) Load new records into FactFacilityBooking
    INSERT INTO FactFacilityBooking (GuestKey, FacilityKey, HotelKey, DateKey, FacilityBookingID, FacilityQuantity, FacilityUnitPrice, FacilityTotalAmount)
    SELECT
        dg.GuestKey, df.FacilityKey, dh.HotelKey, dd.DateKey,
        gs.service_id, gs.quantity, s.service_price, gs.total_amount
    FROM GuestService gs
    JOIN Service s ON gs.service_id = s.service_id
    JOIN DimGuest dg ON gs.guest_id = dg.GuestID
    JOIN DimFacility df ON s.service_id = df.FacilityID
    JOIN DimHotel dh ON s.hotel_id = dh.HotelID
    JOIN DimDate dd ON TRUNC(gs.usage_date) = dd.FullDate
    WHERE NOT EXISTS (
        SELECT 1 FROM FactFacilityBooking ffb
        WHERE ffb.FacilityBookingID = gs.service_id
          AND ffb.GuestKey = dg.GuestKey
          AND ffb.DateKey = dd.DateKey
    );
    DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT || ' new rows inserted into FactFacilityBooking.');

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Subsequent fact load completed.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error during subsequent fact load: ' || SQLERRM);
        ROLLBACK;
END P_SUBSEQUENT_LOAD_FACTS;
/

-- SET SERVEROUTPUT ON;

-- BEGIN
--   P_RUN_SUBSEQUENT_LOAD;
-- END;
-- /


--- Extra Stuff:
-- ---------------------------------------------------------------------------------
-- Master Procedure: P_RUN_SUBSEQUENT_LOAD
-- ---------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE P_RUN_SUBSEQUENT_LOAD AS
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Starting Subsequent Data Warehouse Load ---');
    P_SUBSEQUENT_LOAD_DIMENSIONS;
    P_SUBSEQUENT_LOAD_FACTS;
    DBMS_OUTPUT.PUT_LINE('--- Subsequent Data Warehouse Load Completed Successfully ---');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('FATAL ERROR during subsequent load: ' || SQLERRM);
END P_RUN_SUBSEQUENT_LOAD;
/