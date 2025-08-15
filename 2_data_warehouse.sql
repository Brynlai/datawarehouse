-- ======================================================
-- DDL for REVISED Data Warehouse (Star Schema)
-- Database: Oracle 11g
-- Sequence: Dimension tables are created first, followed by fact tables.
-- ======================================================

-- Step 1: Create All Dimension Tables
-- ------------------------------------------------------
CREATE TABLE DimGuest (
    GuestKey NUMBER(10) NOT NULL,
    GuestID NUMBER(10), -- Business Key from source
    GuestFullName VARCHAR2(101),
    State VARCHAR2(100),
    Country VARCHAR2(100),
    Region VARCHAR2(100),
    CONSTRAINT pk_dim_guest PRIMARY KEY (GuestKey)
);

CREATE TABLE DimHotel (
    HotelKey NUMBER(10) NOT NULL,
    HotelID NUMBER(10), -- Business Key from source
    City VARCHAR2(100),
    Region VARCHAR2(100),
    State VARCHAR2(100),
    Country VARCHAR2(100),
    PostalCode VARCHAR2(20),
    Rating NUMBER(2,1),
    Email VARCHAR2(100),
    Phone VARCHAR2(20),
    CONSTRAINT pk_dim_hotel PRIMARY KEY (HotelKey)
);

CREATE TABLE DimRoom (
    RoomKey NUMBER(10) NOT NULL,
    RoomID NUMBER(10), -- Business Key from source
    RoomType VARCHAR2(50),
    BedCount NUMBER(2),
    HotelID NUMBER(10),
    EffectiveDate DATE,
    ExpiryDate DATE,
    CurrentFlag CHAR(1),
    CONSTRAINT pk_dim_room PRIMARY KEY (RoomKey)
);

CREATE TABLE DimDate (
    DateKey NUMBER(10) NOT NULL,
    FullDate DATE,
    Year NUMBER(4),
    Quarter NUMBER(1),
    Month NUMBER(2),
    MonthName VARCHAR2(20),
    DayOfMonth NUMBER(2),
    DayOfYear NUMBER(3),
    DayOfWeek NUMBER(1),
    DayName VARCHAR2(20),
    IsWeekend CHAR(1),
    IsHoliday CHAR(1),
    HolidayName VARCHAR2(50),
    WeekOfYear NUMBER(2),
    LastDayOfMonth DATE,
    FestivalEvent VARCHAR2(100),
    CONSTRAINT pk_dim_date PRIMARY KEY (DateKey)
);

CREATE TABLE DimFacility (
    FacilityKey NUMBER(10) NOT NULL,
    FacilityID NUMBER(10), -- Business key from source Service table
    FacilityName VARCHAR2(100),
    FacilityType VARCHAR2(100), -- e.g., 'Spa', 'Gym', 'Pool', 'Conference Room'
    HotelID NUMBER(10),
    EffectiveDate DATE,
    ExpiryDate DATE,
    CurrentFlag CHAR(1),
    CONSTRAINT pk_dim_facility PRIMARY KEY (FacilityKey)
);


-- Step 2: Create All Fact Tables
-- ------------------------------------------------------
CREATE TABLE FactBookingRoom (
    GuestKey NUMBER(10) NOT NULL,
    HotelKey NUMBER(10) NOT NULL,
    RoomKey NUMBER(10) NOT NULL,
    DateKey NUMBER(10) NOT NULL,
    BookingID NUMBER(10) NOT NULL,       -- Degenerate Dimension
    BookingDetailID NUMBER(10) NOT NULL, -- Degenerate Dimension
    DurationDays NUMBER(3),
    RoomPricePerNight NUMBER(10,2),
    BookingTotalAmount NUMBER(12,2),
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
    FacilityBookingID NUMBER(10) NOT NULL, -- Degenerate Dimension from source
    BookingFee NUMBER(10,2),
    DurationHours NUMBER(4,1),
    CONSTRAINT pk_fact_facility PRIMARY KEY (GuestKey, FacilityKey, HotelKey, DateKey, FacilityBookingID),
    CONSTRAINT fk_ffb_guest FOREIGN KEY (GuestKey) REFERENCES DimGuest(GuestKey),
    CONSTRAINT fk_ffb_facility FOREIGN KEY (FacilityKey) REFERENCES DimFacility(FacilityKey),
    CONSTRAINT fk_ffb_hotel FOREIGN KEY (HotelKey) REFERENCES DimHotel(HotelKey),
    CONSTRAINT fk_ffb_date FOREIGN KEY (DateKey) REFERENCES DimDate(DateKey)
);
