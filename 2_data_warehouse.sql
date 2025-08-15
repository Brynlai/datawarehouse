-- ====================================================================
-- Production-Ready Data Warehouse DDL (FIXED VERSION)
-- Database: Oracle 11g
-- Execution: This script is idempotent and can be run in its entirety.
--
-- Fixes Applied:
-- 1. DimDate: Removed redundant 'HolidayName' column.
-- 2. Star Schema: Removed 'HotelID' from DimRoom and DimFacility.
-- 3. DimFacility: Converted from SCD Type 2 to SCD Type 1.
-- ====================================================================

-- Part 0: CLEANUP SCRIPT
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


-- Part 1: SEQUENCES
-- --------------------------------------------------------------------
CREATE SEQUENCE dim_guest_seq START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE dim_hotel_seq START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE dim_room_seq START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE dim_date_seq START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE dim_facility_seq START WITH 1 INCREMENT BY 1 NOCACHE;


-- Part 2: TABLES
-- --------------------------------------------------------------------
CREATE TABLE DimGuest (
    GuestKey NUMBER(10) NOT NULL,
    GuestID NUMBER(10),
    GuestFullName VARCHAR2(101) NOT NULL,
    State VARCHAR2(100),
    Country VARCHAR2(100),
    Region VARCHAR2(100),
    CONSTRAINT pk_dim_guest PRIMARY KEY (GuestKey)
);

CREATE TABLE DimHotel (
    HotelKey NUMBER(10) NOT NULL,
    HotelID NUMBER(10),
    City VARCHAR2(100),
    Region VARCHAR2(100),
    State VARCHAR2(100),
    Country VARCHAR2(100),
    PostalCode VARCHAR2(20),
    Rating NUMBER(2,1),
    Email VARCHAR2(100),
    Phone VARCHAR2(25),
    CONSTRAINT pk_dim_hotel PRIMARY KEY (HotelKey)
);

-- CORRECTED: Removed HotelID to adhere to Star Schema.
CREATE TABLE DimRoom (
    RoomKey NUMBER(10) NOT NULL,
    RoomID NUMBER(10) NOT NULL,
    RoomType VARCHAR2(50),
    BedCount NUMBER(2),
    EffectiveDate DATE NOT NULL,
    ExpiryDate DATE,
    CurrentFlag CHAR(1) NOT NULL,
    CONSTRAINT pk_dim_room PRIMARY KEY (RoomKey),
    CONSTRAINT chk_dimroom_currentflag CHECK (CurrentFlag IN ('Y', 'N'))
);

-- CORRECTED: Removed HolidayName, consolidated into FestivalEvent.
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

-- CORRECTED: Converted to SCD Type 1 and removed HotelID.
CREATE TABLE DimFacility (
    FacilityKey NUMBER(10) NOT NULL,
    FacilityID NUMBER(10) NOT NULL,
    FacilityName VARCHAR2(100) NOT NULL,
    FacilityType VARCHAR2(100) NOT NULL,
    CONSTRAINT pk_dim_facility PRIMARY KEY (FacilityKey),
    CONSTRAINT chk_dimfacility_type CHECK (FacilityType IN ('Recreation', 'Business', 'Dining', 'Wellness'))
);

CREATE TABLE FactBookingRoom (
    GuestKey NUMBER(10) NOT NULL,
    HotelKey NUMBER(10) NOT NULL,
    RoomKey NUMBER(10) NOT NULL,
    DateKey NUMBER(10) NOT NULL,
    BookingID NUMBER(10) NOT NULL,
    BookingDetailID NUMBER(10) NOT NULL,
    DurationDays NUMBER(3) NOT NULL,
    RoomPricePerNight NUMBER(10,2) NOT NULL,
    BookingTotalAmount NUMBER(12,2) NOT NULL,
    CONSTRAINT pk_fact_booking PRIMARY KEY (GuestKey, HotelKey, RoomKey, DateKey, BookingID, BookingDetailID),
    CONSTRAINT fk_fb_guest FOREIGN KEY (GuestKey) REFERENCES DimGuest(GuestKey),
    CONSTRAINT fk_fb_hotel FOREIGN KEY (HotelKey) REFERENCES DimHotel(HotelKey),
    CONSTRAINT fk_fb_room FOREIGN KEY (RoomKey) REFERENCES DimRoom(RoomKey),
    CONSTRAINT fk_fb_date FOREIGN KEY (DateKey) REFERENCES DimDate(DateKey)
);

CREATE TABLE FactFacilityBooking (
    GuestKey NUMBER(10) NOT NULL,
    FacilityKey NUMBER(10) NOT NULL,
    HotelKey NUMBER(10) NOT NULL,
    DateKey NUMBER(10) NOT NULL,
    FacilityBookingID NUMBER(10) NOT NULL,
    BookingFee NUMBER(10,2) NOT NULL,
    DurationHours NUMBER(4,1),
    CONSTRAINT pk_fact_facility PRIMARY KEY (GuestKey, FacilityKey, HotelKey, DateKey, FacilityBookingID),
    CONSTRAINT fk_ffb_guest FOREIGN KEY (GuestKey) REFERENCES DimGuest(GuestKey),
    CONSTRAINT fk_ffb_facility FOREIGN KEY (FacilityKey) REFERENCES DimFacility(FacilityKey),
    CONSTRAINT fk_ffb_hotel FOREIGN KEY (HotelKey) REFERENCES DimHotel(HotelKey),
    CONSTRAINT fk_ffb_date FOREIGN KEY (DateKey) REFERENCES DimDate(DateKey)
);


-- Part 3: INDEXES
-- --------------------------------------------------------------------
CREATE INDEX idx_fb_guest_key ON FactBookingRoom(GuestKey);
CREATE INDEX idx_fb_hotel_key ON FactBookingRoom(HotelKey);
CREATE INDEX idx_fb_room_key ON FactBookingRoom(RoomKey);
CREATE INDEX idx_fb_date_key ON FactBookingRoom(DateKey);

CREATE INDEX idx_ffb_guest_key ON FactFacilityBooking(GuestKey);
CREATE INDEX idx_ffb_facility_key ON FactFacilityBooking(FacilityKey);
CREATE INDEX idx_ffb_hotel_key ON FactFacilityBooking(HotelKey);
CREATE INDEX idx_ffb_date_key ON FactFacilityBooking(DateKey);


-- Part 4: TRIGGERS
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