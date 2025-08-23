<Date> August 23, 2025 17:09</Date>

```1_create_original_db.sql
-- Cleanup drop triggers tables sequences, ignore errors if not present
-- --------------------------------------------------------------------
BEGIN
   EXECUTE IMMEDIATE 'DROP TRIGGER trg_service_pk';
   EXECUTE IMMEDIATE 'DROP TRIGGER trg_room_pk';
   EXECUTE IMMEDIATE 'DROP TRIGGER trg_booking_pk';
   EXECUTE IMMEDIATE 'DROP TRIGGER trg_employee_pk';
   EXECUTE IMMEDIATE 'DROP TRIGGER trg_department_pk';
   EXECUTE IMMEDIATE 'DROP TRIGGER trg_jobs_pk';
   EXECUTE IMMEDIATE 'DROP TRIGGER trg_guest_pk';
   EXECUTE IMMEDIATE 'DROP TRIGGER trg_hotel_pk';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -4080 THEN
         RAISE;
      END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE GuestService CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE BookingDetail CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE Employee CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE Service CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE Room CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE Booking CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE Department CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE Jobs CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE Guest CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE Hotel CASCADE CONSTRAINTS';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -942 THEN
         RAISE;
      END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP SEQUENCE service_seq';
   EXECUTE IMMEDIATE 'DROP SEQUENCE room_seq';
   EXECUTE IMMEDIATE 'DROP SEQUENCE booking_seq';
   EXECUTE IMMEDIATE 'DROP SEQUENCE employee_seq';
   EXECUTE IMMEDIATE 'DROP SEQUENCE department_seq';
   EXECUTE IMMEDIATE 'DROP SEQUENCE jobs_seq';
   EXECUTE IMMEDIATE 'DROP SEQUENCE guest_seq';
   EXECUTE IMMEDIATE 'DROP SEQUENCE hotel_seq';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -2289 THEN
         RAISE;
      END IF;
END;
/


-- Sequences
-- --------------------------------------------------------------------
CREATE SEQUENCE hotel_seq START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE guest_seq START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE jobs_seq START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE department_seq START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE employee_seq START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE booking_seq START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE room_seq START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE service_seq START WITH 1 INCREMENT BY 1 NOCACHE;


-- Tables
-- --------------------------------------------------------------------
CREATE TABLE Hotel (
    hotel_id NUMBER(10) NOT NULL,
    email VARCHAR2(100) UNIQUE,
    phone VARCHAR2(25) NOT NULL,
    rating NUMBER(2,1),
    city VARCHAR2(100) NOT NULL,
    region VARCHAR2(100),
    state VARCHAR2(100) NOT NULL,
    country VARCHAR2(100) NOT NULL,
    postal_code VARCHAR2(20) NOT NULL,
    CONSTRAINT pk_hotel PRIMARY KEY (hotel_id),
    CONSTRAINT chk_hotel_rating CHECK (rating BETWEEN 1 AND 5)
);

CREATE TABLE Guest (
    guest_id NUMBER(10) NOT NULL,
    first_name VARCHAR2(50) NOT NULL,
    last_name VARCHAR2(50) NOT NULL,
    email VARCHAR2(100) UNIQUE,
    phone VARCHAR2(25) NOT NULL,
    city VARCHAR2(100) NOT NULL,
    region VARCHAR2(100),
    state VARCHAR2(100) NOT NULL,
    country VARCHAR2(100) NOT NULL,
    postal_code VARCHAR2(20),
    CONSTRAINT pk_guest PRIMARY KEY (guest_id)
);

CREATE TABLE Jobs (
    job_id NUMBER(10) NOT NULL,
    job_title VARCHAR2(100) NOT NULL UNIQUE,
    min_salary NUMBER(10,2) NOT NULL,
    max_salary NUMBER(10,2) NOT NULL,
    CONSTRAINT pk_jobs PRIMARY KEY (job_id)
);

CREATE TABLE Department (
    department_id NUMBER(10) NOT NULL,
    department_name VARCHAR2(100) NOT NULL,
    hotel_id NUMBER(10) NOT NULL,
    CONSTRAINT pk_department PRIMARY KEY (department_id),
    CONSTRAINT fk_dept_hotel FOREIGN KEY (hotel_id) REFERENCES Hotel(hotel_id)
);

CREATE TABLE Booking (
    booking_id NUMBER(10) NOT NULL,
    total_price NUMBER(10,2) NOT NULL,
    payment_method VARCHAR2(50) NOT NULL,
    payment_date DATE NOT NULL,
    guest_id NUMBER(10) NOT NULL,
    CONSTRAINT pk_booking PRIMARY KEY (booking_id),
    CONSTRAINT fk_booking_guest FOREIGN KEY (guest_id) REFERENCES Guest(guest_id),
    CONSTRAINT chk_booking_payment_method CHECK (payment_method IN ('Credit Card', 'Debit Card', 'Cash', 'Bank Transfer'))
);

CREATE TABLE Room (
    room_id NUMBER(10) NOT NULL,
    room_type VARCHAR2(50) NOT NULL,
    bed_count NUMBER(2) NOT NULL,
    price NUMBER(10,2) NOT NULL,
    hotel_id NUMBER(10) NOT NULL,
    CONSTRAINT pk_room PRIMARY KEY (room_id),
    CONSTRAINT fk_room_hotel FOREIGN KEY (hotel_id) REFERENCES Hotel(hotel_id),
    CONSTRAINT chk_room_type CHECK (room_type IN ('Single', 'Double', 'Suite', 'Deluxe', 'Family'))
);

CREATE TABLE Service (
    service_id NUMBER(10) NOT NULL,
    description VARCHAR2(255),
    service_name VARCHAR2(100) NOT NULL,
    service_price NUMBER(10,2) NOT NULL,
    service_type VARCHAR2(100) NOT NULL,
    hotel_id NUMBER(10) NOT NULL,
    CONSTRAINT pk_service PRIMARY KEY (service_id),
    CONSTRAINT fk_service_hotel FOREIGN KEY (hotel_id) REFERENCES Hotel(hotel_id),
    CONSTRAINT chk_service_type CHECK (service_type IN ('Recreation', 'Business', 'Dining', 'Wellness', 'Transport', 'Convenience'))
);

CREATE TABLE Employee (
    employee_id NUMBER(10) NOT NULL,
    first_name VARCHAR2(50) NOT NULL,
    last_name VARCHAR2(50) NOT NULL,
    email VARCHAR2(100) NOT NULL UNIQUE,
    job_id NUMBER(10) NOT NULL,
    department_id NUMBER(10) NOT NULL,
    CONSTRAINT pk_employee PRIMARY KEY (employee_id),
    CONSTRAINT fk_emp_job FOREIGN KEY (job_id) REFERENCES Jobs(job_id),
    CONSTRAINT fk_emp_dept FOREIGN KEY (department_id) REFERENCES Department(department_id)
);

CREATE TABLE BookingDetail (
    booking_id NUMBER(10) NOT NULL,
    room_id NUMBER(10) NOT NULL,
    duration_days NUMBER(3) NOT NULL,
    checkin_date DATE NOT NULL,
    checkout_date DATE NOT NULL,
    num_of_guest NUMBER(2) NOT NULL,
    CONSTRAINT pk_bookingdetail PRIMARY KEY (booking_id, room_id),
    CONSTRAINT fk_bd_booking FOREIGN KEY (booking_id) REFERENCES Booking(booking_id),
    CONSTRAINT fk_bd_room FOREIGN KEY (room_id) REFERENCES Room(room_id)
);

CREATE TABLE GuestService (
    guest_id NUMBER(10) NOT NULL,
    service_id NUMBER(10) NOT NULL,
    booking_date DATE NOT NULL,
    usage_date DATE NOT NULL,
    quantity NUMBER(3) NOT NULL,
    total_amount NUMBER(10, 2) NOT NULL,
    CONSTRAINT pk_guestservice PRIMARY KEY (guest_id, service_id, usage_date),
    CONSTRAINT fk_gs_guest FOREIGN KEY (guest_id) REFERENCES Guest(guest_id),
    CONSTRAINT fk_gs_service FOREIGN KEY (service_id) REFERENCES Service(service_id)
);


-- Indexes
-- --------------------------------------------------------------------
CREATE INDEX idx_dept_hotel_id ON Department(hotel_id);
CREATE INDEX idx_booking_guest_id ON Booking(guest_id);
CREATE INDEX idx_room_hotel_id ON Room(hotel_id);
CREATE INDEX idx_service_hotel_id ON Service(hotel_id);
CREATE INDEX idx_emp_job_id ON Employee(job_id);
CREATE INDEX idx_emp_dept_id ON Employee(department_id);
CREATE INDEX idx_bd_booking_id ON BookingDetail(booking_id);
CREATE INDEX idx_bd_room_id ON BookingDetail(room_id);
CREATE INDEX idx_gs_guest_id ON GuestService(guest_id);
CREATE INDEX idx_gs_service_id ON GuestService(service_id);


-- Triggers
-- --------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_hotel_pk BEFORE INSERT ON Hotel FOR EACH ROW BEGIN IF :NEW.hotel_id IS NULL THEN SELECT hotel_seq.NEXTVAL INTO :NEW.hotel_id FROM DUAL; END IF; END;
/
CREATE OR REPLACE TRIGGER trg_guest_pk BEFORE INSERT ON Guest FOR EACH ROW BEGIN IF :NEW.guest_id IS NULL THEN SELECT guest_seq.NEXTVAL INTO :NEW.guest_id FROM DUAL; END IF; END;
/
CREATE OR REPLACE TRIGGER trg_jobs_pk BEFORE INSERT ON Jobs FOR EACH ROW BEGIN IF :NEW.job_id IS NULL THEN SELECT jobs_seq.NEXTVAL INTO :NEW.job_id FROM DUAL; END IF; END;
/
CREATE OR REPLACE TRIGGER trg_department_pk BEFORE INSERT ON Department FOR EACH ROW BEGIN IF :NEW.department_id IS NULL THEN SELECT department_seq.NEXTVAL INTO :NEW.department_id FROM DUAL; END IF; END;
/
CREATE OR REPLACE TRIGGER trg_employee_pk BEFORE INSERT ON Employee FOR EACH ROW BEGIN IF :NEW.employee_id IS NULL THEN SELECT employee_seq.NEXTVAL INTO :NEW.employee_id FROM DUAL; END IF; END;
/
CREATE OR REPLACE TRIGGER trg_booking_pk BEFORE INSERT ON Booking FOR EACH ROW BEGIN IF :NEW.booking_id IS NULL THEN SELECT booking_seq.NEXTVAL INTO :NEW.booking_id FROM DUAL; END IF; END;
/
CREATE OR REPLACE TRIGGER trg_room_pk BEFORE INSERT ON Room FOR EACH ROW BEGIN IF :NEW.room_id IS NULL THEN SELECT room_seq.NEXTVAL INTO :NEW.room_id FROM DUAL; END IF; END;
/
CREATE OR REPLACE TRIGGER trg_service_pk BEFORE INSERT ON Service FOR EACH ROW BEGIN IF :NEW.service_id IS NULL THEN SELECT service_seq.NEXTVAL INTO :NEW.service_id FROM DUAL; END IF; END;
/
```

```2_data_warehouse.sql
-- Data warehouse DDL
-- Oracle 11g
-- Notes
-- - dims have direct FKs back to the OLTP source when useful
-- - fact tables include degenerate dims to keep row identity
-- ====================================================================

-- Cleanup drops for triggers tables sequences, ignore errors if missing
-- --------------------------------------------------------------------
BEGIN
   EXECUTE IMMEDIATE 'DROP TRIGGER trg_dim_facility_pk';
   EXECUTE IMMEDIATE 'DROP TRIGGER trg_dim_date_pk';
   EXECUTE IMMEDIATE 'DROP TRIGGER trg_dim_room_pk';
   EXECUTE IMMEDIATE 'DROP TRIGGER trg_dim_hotel_pk';
   EXECUTE IMMEDIATE 'DROP TRIGGER trg_dim_guest_pk';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -4080 THEN
         RAISE;
      END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE FactFacilityBooking CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE FactBookingRoom CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE DimFacility CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE DimDate CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE DimRoom CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE DimHotel CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE DimGuest CASCADE CONSTRAINTS';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -942 THEN
         RAISE;
      END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP SEQUENCE dim_facility_seq';
   EXECUTE IMMEDIATE 'DROP SEQUENCE dim_date_seq';
   EXECUTE IMMEDIATE 'DROP SEQUENCE dim_room_seq';
   EXECUTE IMMEDIATE 'DROP SEQUENCE dim_hotel_seq';
   EXECUTE IMMEDIATE 'DROP SEQUENCE dim_guest_seq';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -2289 THEN
         RAISE;
      END IF;
END;
/


-- Sequences
-- --------------------------------------------------------------------
CREATE SEQUENCE dim_guest_seq START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE dim_hotel_seq START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE dim_room_seq START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE dim_date_seq START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE dim_facility_seq START WITH 1 INCREMENT BY 1 NOCACHE;


-- Tables
-- --------------------------------------------------------------------
CREATE TABLE DimGuest (
    GuestKey NUMBER(10) NOT NULL,
    GuestID NUMBER(10) NOT NULL,
    GuestFullName VARCHAR2(101) NOT NULL,
    State VARCHAR2(100),
    Country VARCHAR2(100),
    Region VARCHAR2(100),
    CONSTRAINT pk_dim_guest PRIMARY KEY (GuestKey),
    CONSTRAINT fk_dim_guest_oltp FOREIGN KEY (GuestID) REFERENCES Guest(guest_id)
);

CREATE TABLE DimHotel (
    HotelKey NUMBER(10) NOT NULL,
    HotelID NUMBER(10) NOT NULL,
    City VARCHAR2(100),
    Region VARCHAR2(100),
    State VARCHAR2(100),
    Country VARCHAR2(100),
    PostalCode VARCHAR2(20),
    Rating NUMBER(2,1),
    Email VARCHAR2(100),
    Phone VARCHAR2(25),
    CONSTRAINT pk_dim_hotel PRIMARY KEY (HotelKey),
    CONSTRAINT fk_dim_hotel_oltp FOREIGN KEY (HotelID) REFERENCES Hotel(hotel_id)
);

CREATE TABLE DimRoom (
    RoomKey NUMBER(10) NOT NULL,
    RoomID NUMBER(10) NOT NULL,
    RoomType VARCHAR2(50),
    BedCount NUMBER(2),
    EffectiveDate DATE NOT NULL,
    ExpiryDate DATE,
    CurrentFlag CHAR(1) NOT NULL,
    CONSTRAINT pk_dim_room PRIMARY KEY (RoomKey),
    CONSTRAINT fk_dim_room_oltp FOREIGN KEY (RoomID) REFERENCES Room(room_id),
    CONSTRAINT chk_dimroom_currentflag CHECK (CurrentFlag IN ('Y', 'N'))
);

CREATE TABLE DimDate (
    DateKey NUMBER(10) NOT NULL,
    FullDate DATE UNIQUE NOT NULL,
    Year NUMBER(4) NOT NULL,
    Quarter NUMBER(1) NOT NULL,
    Month NUMBER(2) NOT NULL,
    MonthName VARCHAR2(20) NOT NULL,
    DayOfMonth NUMBER(2) NOT NULL,
    DayOfYear NUMBER(3) NOT NULL,
    DayOfWeek NUMBER(1) NOT NULL,
    DayName VARCHAR2(20) NOT NULL,
    IsWeekend CHAR(1) NOT NULL,
    IsHoliday CHAR(1) NOT NULL,
    WeekOfYear NUMBER(2) NOT NULL,
    LastDayOfMonth DATE NOT NULL,
    FestivalEvent VARCHAR2(100),
    CONSTRAINT pk_dim_date PRIMARY KEY (DateKey),
    CONSTRAINT chk_dimdate_isweekend CHECK (IsWeekend IN ('Y', 'N')),
    CONSTRAINT chk_dimdate_isholiday CHECK (IsHoliday IN ('Y', 'N'))
);

CREATE TABLE DimFacility (
    FacilityKey NUMBER(10) NOT NULL,
    FacilityID NUMBER(10) NOT NULL, -- This is the Service_ID from OLTP
    FacilityName VARCHAR2(100) NOT NULL,
    FacilityType VARCHAR2(100) NOT NULL,
    CONSTRAINT pk_dim_facility PRIMARY KEY (FacilityKey),
    CONSTRAINT fk_dim_facility_oltp FOREIGN KEY (FacilityID) REFERENCES Service(service_id)
);

CREATE TABLE FactBookingRoom (
    GuestKey NUMBER(10) NOT NULL,
    HotelKey NUMBER(10) NOT NULL,
    RoomKey NUMBER(10) NOT NULL,
    DateKey NUMBER(10) NOT NULL,
    -- Degenerate Dimensions from Image
    BookingID NUMBER(10) NOT NULL,
    BookingDetailID NUMBER(10) NOT NULL,
    -- Measures
    DurationDays NUMBER(3) NOT NULL,
    RoomPricePerNight NUMBER(10,2) NOT NULL,
    CalculatedBookingAmount NUMBER(12,2) NOT NULL,
   -- note: degenerate dims added to composite primary key to preserve source identity
   CONSTRAINT pk_fact_booking PRIMARY KEY (GuestKey, HotelKey, RoomKey, DateKey, BookingID, BookingDetailID),
    CONSTRAINT fk_fb_guest FOREIGN KEY (GuestKey) REFERENCES DimGuest(GuestKey),
    CONSTRAINT fk_fb_hotel FOREIGN KEY (HotelKey) REFERENCES DimHotel(HotelKey),
    CONSTRAINT fk_fb_room FOREIGN KEY (RoomKey) REFERENCES DimRoom(RoomKey),
    CONSTRAINT fk_fb_date FOREIGN KEY (DateKey) REFERENCES DimDate(DateKey),
   -- note: degenerate dims keep a FK back to booking detail in OLTP
   CONSTRAINT fk_fb_bookingdetail_oltp FOREIGN KEY (BookingID, BookingDetailID) REFERENCES BookingDetail(booking_id, room_id)
);

CREATE TABLE FactFacilityBooking (
    GuestKey NUMBER(10) NOT NULL,
    FacilityKey NUMBER(10) NOT NULL,
    HotelKey NUMBER(10) NOT NULL,
    DateKey NUMBER(10) NOT NULL,
    -- Degenerate Dimension from Image
    FacilityBookingID NUMBER(10) NOT NULL,
    -- Measures
    FacilityQuantity NUMBER(3) NOT NULL,
    FacilityUnitPrice NUMBER(10,2) NOT NULL,
    FacilityTotalAmount NUMBER(12,2) NOT NULL,
   -- note: degenerate dim included in composite primary key to keep row uniqueness
   CONSTRAINT pk_fact_facility PRIMARY KEY (GuestKey, FacilityKey, HotelKey, DateKey, FacilityBookingID),
    CONSTRAINT fk_ffb_guest FOREIGN KEY (GuestKey) REFERENCES DimGuest(GuestKey),
    CONSTRAINT fk_ffb_facility FOREIGN KEY (FacilityKey) REFERENCES DimFacility(FacilityKey),
    CONSTRAINT fk_ffb_hotel FOREIGN KEY (HotelKey) REFERENCES DimHotel(HotelKey),
    CONSTRAINT fk_ffb_date FOREIGN KEY (DateKey) REFERENCES DimDate(DateKey),
   -- note: degenerate dim references OLTP service id when available
   CONSTRAINT fk_ffb_service_oltp FOREIGN KEY (FacilityBookingID) REFERENCES Service(service_id)
);


-- Indexes
-- --------------------------------------------------------------------
CREATE INDEX idx_fb_guest_key ON FactBookingRoom(GuestKey);
CREATE INDEX idx_fb_hotel_key ON FactBookingRoom(HotelKey);
CREATE INDEX idx_fb_room_key ON FactBookingRoom(RoomKey);
CREATE INDEX idx_fb_date_key ON FactBookingRoom(DateKey);

CREATE INDEX idx_ffb_guest_key ON FactFacilityBooking(GuestKey);
CREATE INDEX idx_ffb_facility_key ON FactFacilityBooking(FacilityKey);
CREATE INDEX idx_ffb_hotel_key ON FactFacilityBooking(HotelKey);
CREATE INDEX idx_ffb_date_key ON FactFacilityBooking(DateKey);


-- Triggers
-- --------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_dim_guest_pk BEFORE INSERT ON DimGuest FOR EACH ROW BEGIN IF :NEW.GuestKey IS NULL THEN SELECT dim_guest_seq.NEXTVAL INTO :NEW.GuestKey FROM DUAL; END IF; END;
/
CREATE OR REPLACE TRIGGER trg_dim_hotel_pk BEFORE INSERT ON DimHotel FOR EACH ROW BEGIN IF :NEW.HotelKey IS NULL THEN SELECT dim_hotel_seq.NEXTVAL INTO :NEW.HotelKey FROM DUAL; END IF; END;
/
CREATE OR REPLACE TRIGGER trg_dim_room_pk BEFORE INSERT ON DimRoom FOR EACH ROW BEGIN IF :NEW.RoomKey IS NULL THEN SELECT dim_room_seq.NEXTVAL INTO :NEW.RoomKey FROM DUAL; END IF; END;
/
CREATE OR REPLACE TRIGGER trg_dim_date_pk BEFORE INSERT ON DimDate FOR EACH ROW BEGIN IF :NEW.DateKey IS NULL THEN SELECT dim_date_seq.NEXTVAL INTO :NEW.DateKey FROM DUAL; END IF; END;
/
CREATE OR REPLACE TRIGGER trg_dim_facility_pk BEFORE INSERT ON DimFacility FOR EACH ROW BEGIN IF :NEW.FacilityKey IS NULL THEN SELECT dim_facility_seq.NEXTVAL INTO :NEW.FacilityKey FROM DUAL; END IF; END;
/
```

```4.5_check_etl_delete_later.sql
-- Data warehouse verification script
-- run after initial load to sanity check counts and revenue
-- ====================================================================

SET SERVEROUTPUT ON
SET TERMOUT ON

DECLARE
  v_oltp_count NUMBER;
  v_dwh_count  NUMBER;
  v_diff       NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('====================================================================');
  DBMS_OUTPUT.PUT_LINE('=============== STARTING DATA WAREHOUSE VERIFICATION ===============');
  DBMS_OUTPUT.PUT_LINE('====================================================================');

  -- ====================================================================
  -- Part 1: Row Count Sanity Checks
  -- ====================================================================
  DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- Part 1: Row Count Sanity Checks ---');

  -- Check DimGuest
  SELECT COUNT(*) INTO v_oltp_count FROM Guest;
  SELECT COUNT(*) INTO v_dwh_count FROM DimGuest;
  DBMS_OUTPUT.PUT_LINE('DimGuest: Source OLTP=' || v_oltp_count || ', DWH=' || v_dwh_count || ' -> ' || CASE WHEN v_oltp_count = v_dwh_count THEN 'OK' ELSE 'FAIL' END);

  -- Check DimHotel
  SELECT COUNT(*) INTO v_oltp_count FROM Hotel;
  SELECT COUNT(*) INTO v_dwh_count FROM DimHotel;
  DBMS_OUTPUT.PUT_LINE('DimHotel: Source OLTP=' || v_oltp_count || ', DWH=' || v_dwh_count || ' -> ' || CASE WHEN v_oltp_count = v_dwh_count THEN 'OK' ELSE 'FAIL' END);

  -- Check DimRoom (SCD2 - current records should match)
  SELECT COUNT(*) INTO v_oltp_count FROM Room;
  SELECT COUNT(*) INTO v_dwh_count FROM DimRoom WHERE CurrentFlag = 'Y';
  DBMS_OUTPUT.PUT_LINE('DimRoom (Current): Source OLTP=' || v_oltp_count || ', DWH=' || v_dwh_count || ' -> ' || CASE WHEN v_oltp_count = v_dwh_count THEN 'OK' ELSE 'FAIL' END);

  -- Check DimFacility
  SELECT COUNT(*) INTO v_oltp_count FROM Service;
  SELECT COUNT(*) INTO v_dwh_count FROM DimFacility;
  DBMS_OUTPUT.PUT_LINE('DimFacility: Source OLTP=' || v_oltp_count || ', DWH=' || v_dwh_count || ' -> ' || CASE WHEN v_oltp_count = v_dwh_count THEN 'OK' ELSE 'FAIL' END);

  -- Check FactBookingRoom
  SELECT COUNT(*) INTO v_oltp_count FROM BookingDetail;
  SELECT COUNT(*) INTO v_dwh_count FROM FactBookingRoom;
  DBMS_OUTPUT.PUT_LINE('FactBookingRoom: Source OLTP=' || v_oltp_count || ', DWH=' || v_dwh_count || ' -> ' || CASE WHEN v_oltp_count = v_dwh_count THEN 'OK' ELSE 'FAIL' END);

  -- Check FactFacilityBooking
  SELECT COUNT(*) INTO v_oltp_count FROM GuestService;
  SELECT COUNT(*) INTO v_dwh_count FROM FactFacilityBooking;
  DBMS_OUTPUT.PUT_LINE('FactFacilityBooking: Source OLTP=' || v_oltp_count || ', DWH=' || v_dwh_count || ' -> ' || CASE WHEN v_oltp_count = v_dwh_count THEN 'OK' ELSE 'FAIL' END);

  -- ====================================================================
  -- Part 2: Key Integrity Checks
  -- ====================================================================
  DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- Part 2: Key Integrity Checks ---');

  -- Check for any NULL keys in FactBookingRoom
  SELECT COUNT(*) INTO v_dwh_count FROM FactBookingRoom
  WHERE GuestKey IS NULL OR HotelKey IS NULL OR RoomKey IS NULL OR DateKey IS NULL;
  DBMS_OUTPUT.PUT_LINE('FactBookingRoom NULL Keys: Found ' || v_dwh_count || ' -> ' || CASE WHEN v_dwh_count = 0 THEN 'OK' ELSE 'FAIL' END);

  -- Check for any NULL keys in FactFacilityBooking
  SELECT COUNT(*) INTO v_dwh_count FROM FactFacilityBooking
  WHERE GuestKey IS NULL OR HotelKey IS NULL OR FacilityKey IS NULL OR DateKey IS NULL;
  DBMS_OUTPUT.PUT_LINE('FactFacilityBooking NULL Keys: Found ' || v_dwh_count || ' -> ' || CASE WHEN v_dwh_count = 0 THEN 'OK' ELSE 'FAIL' END);

  -- ====================================================================
  -- Part 3: Data Spot Checks
  -- ====================================================================
  DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- Part 3: Data Spot Checks ---');
  DBMS_OUTPUT.PUT_LINE('Displaying 5 sample records from each DWH table...');
END;
/

-- Display sample records to visually inspect data transformation (e.g., uppercase, concatenation)
PROMPT >> DimGuest Sample
SELECT * FROM DimGuest WHERE ROWNUM <= 5;

PROMPT >> DimRoom Sample (SCD2)
SELECT RoomKey, RoomID, RoomType, EffectiveDate, ExpiryDate, CurrentFlag FROM DimRoom WHERE ROWNUM <= 5;

PROMPT >> FactBookingRoom Sample
SELECT GuestKey, HotelKey, RoomKey, DateKey, DurationDays, RoomPricePerNight, CalculatedBookingAmount FROM FactBookingRoom WHERE ROWNUM <= 5;

PROMPT >> FactFacilityBooking Sample
SELECT GuestKey, FacilityKey, HotelKey, DateKey, FacilityQuantity, FacilityUnitPrice, FacilityTotalAmount FROM FactFacilityBooking WHERE ROWNUM <= 5;


-- ====================================================================
-- Part 4: Financial Reconciliation (The Gold Standard)
-- ====================================================================
DECLARE
  v_oltp_revenue NUMBER;
  v_dwh_revenue  NUMBER;
  v_diff         NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- Part 4: Financial Reconciliation ---');

  -- ## Reconciliation 1: Total Room Booking Revenue ##
  -- Calculate directly from OLTP source
  SELECT SUM(bd.duration_days * r.price)
  INTO v_oltp_revenue
  FROM BookingDetail bd
  JOIN Room r ON bd.room_id = r.room_id;

  -- Calculate from DWH Fact table
  SELECT SUM(fbr.CalculatedBookingAmount)
  INTO v_dwh_revenue
  FROM FactBookingRoom fbr;

  v_diff := NVL(v_oltp_revenue, 0) - NVL(v_dwh_revenue, 0);
  DBMS_OUTPUT.PUT_LINE('Room Revenue Check:');
  DBMS_OUTPUT.PUT_LINE('  - OLTP Source Total: ' || TO_CHAR(v_oltp_revenue, '999,999,999,990.00'));
  DBMS_OUTPUT.PUT_LINE('  - DWH Fact Total:    ' || TO_CHAR(v_dwh_revenue, '999,999,999,990.00'));
  DBMS_OUTPUT.PUT_LINE('  - Difference:        ' || TO_CHAR(v_diff, '999,999,999,990.00') || ' -> ' || CASE WHEN v_diff = 0 THEN 'OK' ELSE 'FAIL - REVENUE MISMATCH!' END);

  -- ## Reconciliation 2: Total Facility Booking Revenue ##
  -- Calculate directly from OLTP source
  SELECT SUM(gs.total_amount)
  INTO v_oltp_revenue
  FROM GuestService gs;

  -- Calculate from DWH Fact table
  SELECT SUM(ffb.FacilityTotalAmount)
  INTO v_dwh_revenue
  FROM FactFacilityBooking ffb;

  v_diff := NVL(v_oltp_revenue, 0) - NVL(v_dwh_revenue, 0);
  DBMS_OUTPUT.PUT_LINE('Facility Revenue Check:');
  DBMS_OUTPUT.PUT_LINE('  - OLTP Source Total: ' || TO_CHAR(v_oltp_revenue, '999,999,999,990.00'));
  DBMS_OUTPUT.PUT_LINE('  - DWH Fact Total:    ' || TO_CHAR(v_dwh_revenue, '999,999,999,990.00'));
  DBMS_OUTPUT.PUT_LINE('  - Difference:        ' || TO_CHAR(v_diff, '999,999,999,990.00') || ' -> ' || CASE WHEN v_diff = 0 THEN 'OK' ELSE 'FAIL - REVENUE MISMATCH!' END);

  DBMS_OUTPUT.PUT_LINE(CHR(10) || '====================================================================');
  DBMS_OUTPUT.PUT_LINE('===================== VERIFICATION SCRIPT COMPLETE =====================');
  DBMS_OUTPUT.PUT_LINE('====================================================================');

END;
/
```

```4_etl_process.sql
-- ETL processes for data warehouse (CORRECTED)
-- Oracle 11g
-- initial and subsequent load procedures
-- =================================================================================

-- enable DBMS output to show progress
SET SERVEROUTPUT ON;

-- Part 1: initial load
-- =================================================================================
-- Procedure: P_LOAD_DIM_DATE
-- populate DimDate between two dates with enriched festival events
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
            -- IsHoliday flag updated for all new events
            CASE WHEN TO_CHAR(v_current_date, 'MMDD') IN (
                '0101', '0214', '0317', '0401', '0501', '0505', '0701', '0704', '0714', '1031',
                '1101', '1111', '1224', '1225', '1226', '1231'
            ) THEN 'Y' ELSE 'N' END,
            TO_NUMBER(TO_CHAR(v_current_date, 'WW')), LAST_DAY(v_current_date),
            -- FestivalEvent list expanded to ~20 events
            CASE
                WHEN TO_CHAR(v_current_date, 'MMDD') = '0101' THEN 'New Year''s Day'
                WHEN TO_CHAR(v_current_date, 'MMDD') = '0115' THEN 'Martin Luther King Jr. Day (US)'
                WHEN TO_CHAR(v_current_date, 'MMDD') = '0214' THEN 'Valentine''s Day'
                WHEN TO_CHAR(v_current_date, 'MMDD') = '0308' THEN 'International Women''s Day'
                WHEN TO_CHAR(v_current_date, 'MMDD') = '0317' THEN 'St. Patrick''s Day'
                WHEN TO_CHAR(v_current_date, 'MMDD') = '0401' THEN 'April Fool''s Day'
                WHEN TO_CHAR(v_current_date, 'MMDD') = '0422' THEN 'Earth Day'
                WHEN TO_CHAR(v_current_date, 'MMDD') = '0501' THEN 'May Day / Labour Day'
                WHEN TO_CHAR(v_current_date, 'MMDD') = '0505' THEN 'Cinco de Mayo'
                WHEN TO_CHAR(v_current_date, 'MMDD') = '0619' THEN 'Juneteenth (US)'
                WHEN TO_CHAR(v_current_date, 'MMDD') = '0701' THEN 'Canada Day'
                WHEN TO_CHAR(v_current_date, 'MMDD') = '0704' THEN 'Independence Day (US)'
                WHEN TO_CHAR(v_current_date, 'MMDD') = '0714' THEN 'Bastille Day (France)'
                WHEN TO_CHAR(v_current_date, 'MMDD') = '1003' THEN 'German Unity Day'
                WHEN TO_CHAR(v_current_date, 'MMDD') = '1031' THEN 'Halloween'
                WHEN TO_CHAR(v_current_date, 'MMDD') = '1101' THEN 'All Saints'' Day'
                WHEN TO_CHAR(v_current_date, 'MMDD') = '1111' THEN 'Veterans / Armistice Day'
                WHEN TO_CHAR(v_current_date, 'MMDD') = '1224' THEN 'Christmas Eve'
                WHEN TO_CHAR(v_current_date, 'MMDD') = '1225' THEN 'Christmas Day'
                WHEN TO_CHAR(v_current_date, 'MMDD') = '1226' THEN 'Boxing Day'
                WHEN TO_CHAR(v_current_date, 'MMDD') = '1231' THEN 'New Year''s Eve'
                ELSE NULL
            END
        );
        v_current_date := v_current_date + 1;
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('DimDate loaded successfully!');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error loading DimDate: ' || SQLERRM);
        ROLLBACK;
END P_LOAD_DIM_DATE;
/

-- Procedure: P_INITIAL_LOAD_DIMENSIONS
-- initial load for dimension tables
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
        TO_DATE('9999-12-31', 'YYYY-MM-DD'),
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

-- Procedure: P_INITIAL_LOAD_FACTS
-- initial load for fact tables
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
        (bd.duration_days * r.price)
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

-- Master Procedure: P_RUN_INITIAL_LOAD (CORRECTED)
-- runs the full initial load and toggles constraints for faster load
-- ---------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE P_RUN_INITIAL_LOAD AS
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Starting Initial Data Warehouse Load ---');
    -- Disable DWH-internal keys
    EXECUTE IMMEDIATE 'ALTER TABLE FactBookingRoom DISABLE CONSTRAINT fk_fb_guest';
    EXECUTE IMMEDIATE 'ALTER TABLE FactBookingRoom DISABLE CONSTRAINT fk_fb_hotel';
    EXECUTE IMMEDIATE 'ALTER TABLE FactBookingRoom DISABLE CONSTRAINT fk_fb_room';
    EXECUTE IMMEDIATE 'ALTER TABLE FactBookingRoom DISABLE CONSTRAINT fk_fb_date';
    EXECUTE IMMEDIATE 'ALTER TABLE FactFacilityBooking DISABLE CONSTRAINT fk_ffb_guest';
    EXECUTE IMMEDIATE 'ALTER TABLE FactFacilityBooking DISABLE CONSTRAINT fk_ffb_facility';
    EXECUTE IMMEDIATE 'ALTER TABLE FactFacilityBooking DISABLE CONSTRAINT fk_ffb_hotel';
    EXECUTE IMMEDIATE 'ALTER TABLE FactFacilityBooking DISABLE CONSTRAINT fk_ffb_date';
    EXECUTE IMMEDIATE 'ALTER TABLE FactBookingRoom DISABLE CONSTRAINT fk_fb_bookingdetail_oltp';
    EXECUTE IMMEDIATE 'ALTER TABLE FactFacilityBooking DISABLE CONSTRAINT fk_ffb_service_oltp';

    -- *** CORRECTED: Removed two lines that disable non-existent constraints ***
    DBMS_OUTPUT.PUT_LINE('Fact table constraints disabled.');

    EXECUTE IMMEDIATE 'TRUNCATE TABLE FactBookingRoom';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE FactFacilityBooking';
    -- Must truncate dimensions before facts due to FKs
    EXECUTE IMMEDIATE 'TRUNCATE TABLE DimFacility';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE DimRoom';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE DimHotel';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE DimGuest';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE DimDate';
    DBMS_OUTPUT.PUT_LINE('All DWH tables truncated.');

    -- End date updated to include 2025
    P_LOAD_DIM_DATE(TO_DATE('2010-01-01', 'YYYY-MM-DD'), TO_DATE('2025-12-31', 'YYYY-MM-DD'));
    P_INITIAL_LOAD_DIMENSIONS;
    P_INITIAL_LOAD_FACTS;

    -- Enable DWH-internal keys
    EXECUTE IMMEDIATE 'ALTER TABLE FactBookingRoom ENABLE VALIDATE CONSTRAINT fk_fb_guest';
    EXECUTE IMMEDIATE 'ALTER TABLE FactBookingRoom ENABLE VALIDATE CONSTRAINT fk_fb_hotel';
    EXECUTE IMMEDIATE 'ALTER TABLE FactBookingRoom ENABLE VALIDATE CONSTRAINT fk_fb_room';
    EXECUTE IMMEDIATE 'ALTER TABLE FactBookingRoom ENABLE VALIDATE CONSTRAINT fk_fb_date';
    EXECUTE IMMEDIATE 'ALTER TABLE FactFacilityBooking ENABLE VALIDATE CONSTRAINT fk_ffb_guest';
    EXECUTE IMMEDIATE 'ALTER TABLE FactFacilityBooking ENABLE VALIDATE CONSTRAINT fk_ffb_facility';
    EXECUTE IMMEDIATE 'ALTER TABLE FactFacilityBooking ENABLE VALIDATE CONSTRAINT fk_ffb_hotel';
    EXECUTE IMMEDIATE 'ALTER TABLE FactFacilityBooking ENABLE VALIDATE CONSTRAINT fk_ffb_date';
    EXECUTE IMMEDIATE 'ALTER TABLE FactBookingRoom ENABLE VALIDATE CONSTRAINT fk_fb_bookingdetail_oltp';
    EXECUTE IMMEDIATE 'ALTER TABLE FactFacilityBooking ENABLE VALIDATE CONSTRAINT fk_ffb_service_oltp';
    DBMS_OUTPUT.PUT_LINE('Fact table constraints re-enabled.');

    DBMS_OUTPUT.PUT_LINE('--- Initial Data Warehouse Load Completed Successfully ---');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('FATAL ERROR during initial load: ' || SQLERRM);
END P_RUN_INITIAL_LOAD;
/


-- Part 2: subsequent load
-- =================================================================================
CREATE OR REPLACE VIEW V_CLEANSED_GUEST AS
SELECT
    guest_id, first_name, last_name, UPPER(state) AS state,
    UPPER(country) AS country, NVL(region, 'N/A') AS region
FROM Guest;
/

-- Procedure: P_SUBSEQUENT_LOAD_DIMENSIONS
-- merge changes into dimension tables
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

-- Procedure: P_SUBSEQUENT_LOAD_FACTS
-- load new fact rows since last run
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

-- Master Procedure: P_RUN_SUBSEQUENT_LOAD
-- runs the incremental load
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

-- BEGIN
--   P_RUN_INITIAL_LOAD;
-- END;
-- /
```

```bryan_1.sql
-- Report 1: Multi-Year Revenue Performance and Growth

-- Setup the page and title for the report
SET PAGESIZE 25
SET LINESIZE 140
TTITLE CENTER 'Hotel Analytics Inc.' SKIP 1 CENTER 'Annual Revenue Performance and Growth' SKIP 2
BTITLE CENTER 'Page ' FORMAT 999 SQL.PNO SKIP 1 CENTER 'Report Generated on: ' _DATE

-- Define the column formats and headings
COLUMN "Year"                  FORMAT 9999
COLUMN "Total Room Revenue"    FORMAT $999,999,990
COLUMN "Total Facility Revenue"FORMAT $999,999,990
COLUMN "Grand Total Revenue"   FORMAT $999,999,990
COLUMN "Previous Year Revenue" FORMAT $999,999,990
COLUMN "YoY Growth %"          FORMAT A12

-- Main Query
WITH
  AnnualRoomRevenue AS (
    SELECT dd.Year, SUM(fbr.CalculatedBookingAmount) AS RoomRevenue
    FROM FactBookingRoom fbr JOIN DimDate dd ON fbr.DateKey = dd.DateKey
    GROUP BY dd.Year
  ),
  AnnualFacilityRevenue AS (
    SELECT dd.Year, SUM(ffb.FacilityTotalAmount) AS FacilityRevenue
    FROM FactFacilityBooking ffb JOIN DimDate dd ON ffb.DateKey = dd.DateKey
    GROUP BY dd.Year
  ),
  TotalAnnualRevenue AS (
    SELECT
      COALESCE(r.Year, f.Year) AS RevenueYear,
      NVL(r.RoomRevenue, 0) AS TotalRoomRevenue,
      NVL(f.FacilityRevenue, 0) AS TotalFacilityRevenue,
      (NVL(r.RoomRevenue, 0) + NVL(f.FacilityRevenue, 0)) AS TotalRevenue
    FROM AnnualRoomRevenue r FULL OUTER JOIN AnnualFacilityRevenue f ON r.Year = f.Year
  )
SELECT
  RevenueYear AS "Year",
  TotalRoomRevenue AS "Total Room Revenue",
  TotalFacilityRevenue AS "Total Facility Revenue",
  TotalRevenue AS "Grand Total Revenue",
  LAG(TotalRevenue, 1, 0) OVER(ORDER BY RevenueYear) AS "Previous Year Revenue",
  CASE
    WHEN LAG(TotalRevenue, 1, 0) OVER(ORDER BY RevenueYear) = 0 THEN 'N/A'
    ELSE TO_CHAR(((TotalRevenue - LAG(TotalRevenue, 1) OVER(ORDER BY RevenueYear)) / LAG(TotalRevenue, 1) OVER(ORDER BY RevenueYear)) * 100, 'FM990.00') || '%'
  END AS "YoY Growth %"
FROM TotalAnnualRevenue
ORDER BY RevenueYear;

-- Clean up the report settings
CLEAR COLUMNS
TTITLE OFF
BTITLE OFF
```

```bryan_2.sql
-- Report 2: Quarterly Performance Deep Dive

-- Setup the page and title for the report
SET PAGESIZE 70
SET LINESIZE 150
TTITLE CENTER 'Hotel Analytics Inc.' SKIP 1 CENTER 'Quarterly Performance Deep Dive' SKIP 2
BTITLE CENTER 'Page ' FORMAT 999 SQL.PNO SKIP 1 CENTER 'Report Generated on: ' _DATE

-- Define the column formats and headings
COLUMN "Year"           FORMAT 9999
COLUMN "Qtr"            FORMAT A4
COLUMN "Qtr Rank"       FORMAT A8
COLUMN "Room Revenue"   FORMAT $999,999,990
COLUMN "Rev YoY %"      FORMAT A11
COLUMN "Bookings"       FORMAT 9,999,999,990
COLUMN "Vol YoY %"      FORMAT A11
COLUMN "Avg Lead Time"  FORMAT 9,999.0
COLUMN "Lead Time Chg"  FORMAT A17

-- Main Query
WITH
  QuarterlyMetrics AS (
    SELECT
      dd.Year, dd.Quarter, SUM(fbr.CalculatedBookingAmount) AS TotalRevenue,
      COUNT(fbr.BookingID) AS BookingVolume, AVG(dd.FullDate - b.payment_date) AS AvgLeadTime
    FROM FactBookingRoom fbr
    JOIN DimDate dd ON fbr.DateKey = dd.DateKey
    JOIN Booking b ON fbr.BookingID = b.booking_id
    WHERE b.payment_date < dd.FullDate
    GROUP BY dd.Year, dd.Quarter
  ),
  MetricsWithYoY AS (
    SELECT
      Year, Quarter, TotalRevenue, BookingVolume, AvgLeadTime,
      LAG(TotalRevenue, 1, 0) OVER (PARTITION BY Quarter ORDER BY Year) AS PrevYearRevenue,
      LAG(BookingVolume, 1, 0) OVER (PARTITION BY Quarter ORDER BY Year) AS PrevYearVolume,
      LAG(AvgLeadTime, 1, 0) OVER (PARTITION BY Quarter ORDER BY Year) AS PrevYearLeadTime
    FROM QuarterlyMetrics
  ),
  FinalMetrics AS (
    SELECT
      Year, 'Q' || Quarter AS Quarter, TotalRevenue, BookingVolume, AvgLeadTime,
      CASE WHEN PrevYearRevenue = 0 THEN NULL ELSE (TotalRevenue - PrevYearRevenue) * 100 / PrevYearRevenue END AS RevenueYoY,
      CASE WHEN PrevYearVolume = 0 THEN NULL ELSE (BookingVolume - PrevYearVolume) * 100 / PrevYearVolume END AS VolumeYoY,
      AvgLeadTime - PrevYearLeadTime AS LeadTimeYoY_Change,
      RANK() OVER (PARTITION BY Year ORDER BY TotalRevenue DESC) AS QuarterRank
    FROM MetricsWithYoY
  )
SELECT
  Year AS "Year", Quarter AS "Qtr", '#' || QuarterRank AS "Qtr Rank",
  TotalRevenue AS "Room Revenue",
  CASE WHEN RevenueYoY IS NULL THEN 'N/A' ELSE TO_CHAR(RevenueYoY, 'FM990.0') || '%' END AS "Rev YoY %",
  BookingVolume AS "Bookings",
  CASE WHEN VolumeYoY IS NULL THEN 'N/A' ELSE TO_CHAR(VolumeYoY, 'FM990.0') || '%' END AS "Vol YoY %",
  AvgLeadTime AS "Avg Lead Time",
  CASE
    WHEN LeadTimeYoY_Change IS NULL THEN 'N/A'
    ELSE TO_CHAR(LeadTimeYoY_Change, 'FMS999,990.0') || ' Days'
  END AS "Lead Time Chg"
FROM FinalMetrics
ORDER BY Year, Quarter;

-- Clean up the report settings
CLEAR COLUMNS
TTITLE OFF
BTITLE OFF
```

```bryan_3.sql
-- Report 3: Ancillary Performance with Global Peer Ranking

-- Setup for a clean, professional report.
-- *** CORRECTED: Reduced PAGESIZE to remove the large gap before the footer. ***
SET PAGESIZE 30
SET LINESIZE 160
SET VERIFY OFF
SET FEEDBACK OFF

-- Dynamically determine the latest year for the report title.
SET TERMOUT OFF
COLUMN latest_year FORMAT 9999 NEW_VALUE V_LATEST_YEAR NOPRINT;
SELECT MAX(dd.Year) AS latest_year
FROM FactFacilityBooking ffb
JOIN DimDate dd ON ffb.DateKey = dd.DateKey;
SET TERMOUT ON

-- Set the report titles, using the variable we just created.
TTITLE CENTER 'Hotel Analytics Inc.' SKIP 1 CENTER 'Hotel Ancillary Performance by Global Peer Group' SKIP 1 CENTER '(Analysis for the Year &V_LATEST_YEAR)' SKIP 2
BTITLE CENTER 'Page ' FORMAT 999 SQL.PNO SKIP 1 CENTER 'Report Generated on: ' _DATE

-- Define the column formats and headings for the report body.
COLUMN "Global Peer Rank"   FORMAT A20
COLUMN City                 FORMAT A25
COLUMN Country              FORMAT A40
COLUMN "Ancillary/Night"    FORMAT $99,990.00
COLUMN "Dining"             FORMAT $9,999,990
COLUMN "Business"           FORMAT $9,999,990
COLUMN "Recreation"         FORMAT $9,999,990
COLUMN "Wellness"           FORMAT $9,999,990

-- Main Query
WITH
  HotelRoomMetrics AS (
    SELECT fbr.HotelKey, SUM(fbr.DurationDays) AS TotalRoomNights
    FROM FactBookingRoom fbr
    JOIN DimDate dd ON fbr.DateKey = dd.DateKey
    WHERE dd.Year = &V_LATEST_YEAR
    GROUP BY fbr.HotelKey
  ),
  HotelFacilityBreakdown AS (
    SELECT * FROM (
      SELECT
        ffb.HotelKey, df.FacilityType, ffb.FacilityTotalAmount
      FROM FactFacilityBooking ffb
      JOIN DimDate dd ON ffb.DateKey = dd.DateKey
      JOIN DimFacility df ON ffb.FacilityKey = df.FacilityKey
      WHERE dd.Year = &V_LATEST_YEAR
    )
    PIVOT (
      SUM(FacilityTotalAmount)
      FOR FacilityType IN ('Dining' AS Dining, 'Business' AS Business, 'Recreation' AS Recreation, 'Wellness' AS Wellness)
    )
  ),
  HotelPerformance AS (
    SELECT
      hrm.HotelKey, dh.City, dh.Country, dh.Rating,
      NVL(hfb.Dining, 0) AS DiningRevenue,
      NVL(hfb.Business, 0) AS BusinessRevenue,
      NVL(hfb.Recreation, 0) AS RecreationRevenue,
      NVL(hfb.Wellness, 0) AS WellnessRevenue,
      CASE
        WHEN NVL(hrm.TotalRoomNights, 0) = 0 THEN 0
        ELSE (NVL(hfb.Dining, 0) + NVL(hfb.Business, 0) + NVL(hfb.Recreation, 0) + NVL(hfb.Wellness, 0)) / hrm.TotalRoomNights
      END AS AncillaryPerNight
    FROM HotelRoomMetrics hrm
    JOIN DimHotel dh ON hrm.HotelKey = dh.HotelKey
    LEFT JOIN HotelFacilityBreakdown hfb ON hrm.HotelKey = hfb.HotelKey
    WHERE hrm.TotalRoomNights > 0
  )
SELECT
  TO_CHAR(hp.Rating, 'FM9.0') || ' Star: ' ||
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
ORDER BY hp.Rating DESC, hp.AncillaryPerNight DESC;

-- Clean up the report settings to return SQL*Plus to its default state.
CLEAR COLUMNS
TTITLE OFF
BTITLE OFF
```

```generate_data.py
import os
from faker import Faker
import random
from datetime import datetime, timedelta, date

# --- Configuration (REVISED & RECALIBRATED) ---
NUM_HOTELS = 20
NUM_GUESTS = 10000
NUM_JOBS = 15
NUM_ROOMS_PER_HOTEL = 50
NUM_SERVICES_PER_HOTEL = 10
NUM_DEPTS_PER_HOTEL = 5
NUM_EMPLOYEES_PER_HOTEL = 30

# RECALIBRATED: Increased transactional counts to achieve a realistic
# hotel occupancy rate of approximately 68% over the entire period.
NUM_BOOKINGS = 450000
NUM_BOOKING_DETAILS = 520000
NUM_GUEST_SERVICES = 450000

# REVISED: Date range extended to August 31, 2025
DWH_START_DATE = date(2010, 1, 1)
DWH_END_DATE = date(2025, 8, 31)


OUTPUT_FILE = "3_insert_data.sql"

# Initialize Faker
fake = Faker()

# --- Lists to store generated Primary Keys for Foreign Key relationships ---
hotel_ids = list(range(1, NUM_HOTELS + 1))
guest_ids = list(range(1, NUM_GUESTS + 1))
job_ids = list(range(1, NUM_JOBS + 1))
room_ids = []
service_ids = []
department_ids = []
booking_ids = list(range(1, NUM_BOOKINGS + 1))
employee_ids = list(range(1, (NUM_HOTELS * NUM_EMPLOYEES_PER_HOTEL) + 1))

# --- Sets for ensuring uniqueness ---
unique_emails = set()
service_prices = {} # To store service prices for later calculation

def get_unique_email(name):
    """Generates a unique email to avoid constraint violations."""
    base_email = f"{name.replace(' ', '.').lower()}@{fake.free_email_domain()}"
    email = base_email
    counter = 1
    while email in unique_emails:
        email = f"{name.replace(' ', '.').lower()}{counter}@{fake.free_email_domain()}"
        counter += 1
    unique_emails.add(email)
    return email
    
def escape_sql_string(value):
    """Escapes single quotes and ampersands for Oracle SQL."""
    if value is None:
        return "NULL"
    return str(value).replace("'", "''").replace('&', 'and')

def generate_hotels(f):
    f.write("-- (1) Hotels\n")
    for i in hotel_ids:
        sql = f"INSERT INTO Hotel (hotel_id, email, phone, rating, city, region, state, country, postal_code) VALUES ({i}, '{get_unique_email(f'hotel.{i}')}', '{fake.phone_number()[:25]}', {round(random.uniform(3.5, 5.0), 1)}, '{escape_sql_string(fake.city())}', NULL, '{escape_sql_string(fake.state())}', '{escape_sql_string(fake.country())}', '{fake.postcode()}');\n"
        f.write(sql)
    f.write("\n")

def generate_guests(f):
    f.write("-- (2) Guests\n")
    for i in guest_ids:
        first_name = escape_sql_string(fake.first_name())
        last_name = escape_sql_string(fake.last_name())
        email = get_unique_email(f'{first_name}.{last_name}')
        sql = f"INSERT INTO Guest (guest_id, first_name, last_name, email, phone, city, region, state, country, postal_code) VALUES ({i}, '{first_name}', '{last_name}', '{email}', '{fake.phone_number()[:25]}', '{escape_sql_string(fake.city())}', NULL, '{escape_sql_string(fake.state())}', '{escape_sql_string(fake.country())}', '{fake.postcode()}');\n"
        f.write(sql)
    f.write("\n")

def generate_jobs(f):
    f.write("-- (3) Jobs\n")
    job_titles = ['General Manager', 'Front Desk Clerk', 'Concierge', 'Housekeeper', 'Executive Chef', 'Sous Chef', 'Bartender', 'Waiter/Waitress', 'Maintenance Manager', 'Security Guard', 'Hotel Accountant', 'Marketing Manager', 'Events Coordinator', 'IT Specialist', 'HR Manager']
    for i in job_ids:
        title = job_titles[i-1]
        min_sal = random.randint(30000, 50000)
        max_sal = min_sal + random.randint(10000, 30000)
        sql = f"INSERT INTO Jobs (job_id, job_title, min_salary, max_salary) VALUES ({i}, '{title}', {min_sal}, {max_sal});\n"
        f.write(sql)
    f.write("\n")

def generate_departments(f):
    f.write("-- (4) Departments\n")
    dept_names = ['Management', 'Front Office', 'Housekeeping', 'Food and Beverage', 'Maintenance']
    dept_id_counter = 1
    for hotel_id in hotel_ids:
        for dept_name in dept_names:
            department_ids.append(dept_id_counter)
            sql = f"INSERT INTO Department (department_id, department_name, hotel_id) VALUES ({dept_id_counter}, '{dept_name}', {hotel_id});\n"
            f.write(sql)
            dept_id_counter += 1
    f.write("\n")
    
def generate_rooms(f):
    f.write("-- (5) Rooms\n")
    room_types = ['Single', 'Double', 'Suite', 'Deluxe', 'Family']
    room_id_counter = 1
    for hotel_id in hotel_ids:
        for _ in range(NUM_ROOMS_PER_HOTEL):
            room_ids.append(room_id_counter)
            room_type = random.choice(room_types)
            bed_count = 1 if room_type == 'Single' else (2 if room_type in ['Double', 'Deluxe'] else random.randint(2, 4))
            price = round(random.uniform(80.0, 500.0), 2)
            sql = f"INSERT INTO Room (room_id, room_type, bed_count, price, hotel_id) VALUES ({room_id_counter}, '{room_type}', {bed_count}, {price}, {hotel_id});\n"
            f.write(sql)
            room_id_counter += 1
    f.write("\n")

def generate_services(f):
    f.write("-- (6) Services\n")
    service_definitions = {
        'Airport Shuttle': 'Transport', 'Room Service': 'Dining', 'Laundry Service': 'Convenience',
        'Spa Treatment': 'Wellness', 'Gym Access': 'Recreation', 'Valet Parking': 'Transport',
        'Conference Room Rental': 'Business', 'Bike Rental': 'Recreation', 'City Tour Package': 'Recreation',
        'Pet Care': 'Convenience'
    }
    service_id_counter = 1
    for hotel_id in hotel_ids:
        for name, s_type in service_definitions.items():
            service_ids.append(service_id_counter)
            price = round(random.uniform(15.0, 200.0), 2)
            service_prices[service_id_counter] = price
            desc = escape_sql_string(f"Provides convenient {name} for our valued guests.")
            sql = f"INSERT INTO Service (service_id, description, service_name, service_price, service_type, hotel_id) VALUES ({service_id_counter}, '{desc}', '{name}', {price}, '{s_type}', {hotel_id});\n"
            f.write(sql)
            service_id_counter += 1
    f.write("\n")

def generate_employees(f):
    f.write("-- (7) Employees\n")
    depts_per_hotel = len(department_ids) // len(hotel_ids)
    for i in employee_ids:
        first_name = escape_sql_string(fake.first_name())
        last_name = escape_sql_string(fake.last_name())
        email = get_unique_email(f'{first_name}.{last_name}')
        job_id = random.choice(job_ids)
        hotel_index = (i - 1) // NUM_EMPLOYEES_PER_HOTEL
        start_dept_index = hotel_index * depts_per_hotel
        end_dept_index = start_dept_index + depts_per_hotel
        dept_id = random.choice(department_ids[start_dept_index:end_dept_index])
        sql = f"INSERT INTO Employee (employee_id, first_name, last_name, email, job_id, department_id) VALUES ({i}, '{first_name}', '{last_name}', '{email}', {job_id}, {dept_id});\n"
        f.write(sql)
    f.write("\n")

def generate_bookings(f):
    f.write("-- (8) Bookings\n")
    payment_methods = ['Credit Card', 'Debit Card', 'Cash', 'Bank Transfer']
    for i in booking_ids:
        guest_id = random.choice(guest_ids)
        payment_method = random.choice(payment_methods)
        payment_date = fake.date_between_dates(date_start=DWH_START_DATE, date_end=DWH_END_DATE)
        total_price = round(random.uniform(100.0, 2500.0), 2)
        sql = f"INSERT INTO Booking (booking_id, total_price, payment_method, payment_date, guest_id) VALUES ({i}, {total_price}, '{payment_method}', TO_DATE('{payment_date.strftime('%Y-%m-%d')}', 'YYYY-MM-DD'), {guest_id});\n"
        f.write(sql)
    f.write("\n")

def generate_booking_details(f):
    f.write("-- (9) BookingDetails\n")
    used_booking_room_pairs = set()
    for _ in range(NUM_BOOKING_DETAILS):
        while True:
            booking_id = random.choice(booking_ids)
            room_id = random.choice(room_ids)
            if (booking_id, room_id) not in used_booking_room_pairs:
                used_booking_room_pairs.add((booking_id, room_id))
                break
        duration_days = random.randint(1, 14)
        num_of_guest = random.randint(1, 5)
        checkin_date = fake.date_between_dates(date_start=DWH_START_DATE, date_end=DWH_END_DATE - timedelta(days=15))
        checkout_date = checkin_date + timedelta(days=duration_days)
        sql = f"INSERT INTO BookingDetail (booking_id, room_id, duration_days, checkin_date, checkout_date, num_of_guest) VALUES ({booking_id}, {room_id}, {duration_days}, TO_DATE('{checkin_date.strftime('%Y-%m-%d')}', 'YYYY-MM-DD'), TO_DATE('{checkout_date.strftime('%Y-%m-%d')}', 'YYYY-MM-DD'), {num_of_guest});\n"
        f.write(sql)
    f.write("\n")

def generate_guest_services(f):
    f.write("-- (10) GuestServices\n")
    used_guest_service_date_triplets = set()
    for _ in range(NUM_GUEST_SERVICES):
        while True:
            guest_id = random.choice(guest_ids)
            service_id = random.choice(service_ids)
            usage_date = fake.date_between_dates(date_start=DWH_START_DATE, date_end=DWH_END_DATE)
            if (guest_id, service_id, usage_date) not in used_guest_service_date_triplets:
                 used_guest_service_date_triplets.add((guest_id, service_id, usage_date))
                 break
        booking_date = usage_date - timedelta(days=random.randint(0, 60))
        if booking_date < DWH_START_DATE:
            booking_date = DWH_START_DATE

        quantity = random.randint(1, 3)
        unit_price = service_prices.get(service_id, 0)
        total_amount = round(quantity * unit_price, 2)

        sql = f"INSERT INTO GuestService (guest_id, service_id, booking_date, usage_date, quantity, total_amount) VALUES ({guest_id}, {service_id}, TO_DATE('{booking_date.strftime('%Y-%m-%d')}', 'YYYY-MM-DD'), TO_DATE('{usage_date.strftime('%Y-%m-%d')}', 'YYYY-MM-DD'), {quantity}, {total_amount});\n"
        f.write(sql)
    f.write("\n")

# --- Main execution ---
if __name__ == "__main__":
    start_time = datetime.now()
    print(f"Starting data generation at {start_time.strftime('%H:%M:%S')}...")
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write("-- ====================================================================\n")
        f.write("-- Generated OLTP Insert Data for Oracle 11g (REVISED)\n")
        f.write("-- ====================================================================\n\n")
        f.write("-- Disable PK triggers to allow explicit ID insertion\n")
        f.write("ALTER TRIGGER trg_hotel_pk DISABLE;\n")
        f.write("ALTER TRIGGER trg_guest_pk DISABLE;\n")
        f.write("ALTER TRIGGER trg_jobs_pk DISABLE;\n")
        f.write("ALTER TRIGGER trg_department_pk DISABLE;\n")
        f.write("ALTER TRIGGER trg_employee_pk DISABLE;\n")
        f.write("ALTER TRIGGER trg_booking_pk DISABLE;\n")
        f.write("ALTER TRIGGER trg_room_pk DISABLE;\n")
        f.write("ALTER TRIGGER trg_service_pk DISABLE;\n\n")
        f.write("SET DEFINE OFF;\n\n")
        generate_hotels(f)
        generate_guests(f)
        generate_jobs(f)
        generate_departments(f)
        generate_rooms(f)
        generate_services(f)
        generate_employees(f)
        generate_bookings(f)
        generate_booking_details(f)
        generate_guest_services(f)
        f.write("SET DEFINE ON;\n\n")
        f.write("-- Re-enable PK triggers after insertion\n")
        f.write("ALTER TRIGGER trg_hotel_pk ENABLE;\n")
        f.write("ALTER TRIGGER trg_guest_pk ENABLE;\n")
        f.write("ALTER TRIGGER trg_jobs_pk ENABLE;\n")
        f.write("ALTER TRIGGER trg_department_pk ENABLE;\n")
        f.write("ALTER TRIGGER trg_employee_pk ENABLE;\n")
        f.write("ALTER TRIGGER trg_booking_pk ENABLE;\n")
        f.write("ALTER TRIGGER trg_room_pk ENABLE;\n")
        f.write("ALTER TRIGGER trg_service_pk ENABLE;\n\n")
        f.write("COMMIT;\n")
    end_time = datetime.now()
    print(f"Successfully generated {OUTPUT_FILE} at {end_time.strftime('%H:%M:%S')}")
    print(f"Total time taken: {end_time - start_time}")
```

