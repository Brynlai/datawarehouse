-- ======================================================
-- DDL for REVISED Original OLTP Database Schema
-- Database: Oracle 11g
-- Sequence: Tables are ordered to resolve foreign key dependencies for smooth execution.
-- ======================================================

-- Independent Tables (No Foreign Keys)
-- ------------------------------------------------------
CREATE TABLE Hotel (
    hotel_id NUMBER(10) NOT NULL,
    email VARCHAR2(100),
    phone VARCHAR2(20),
    rating NUMBER(2,1),
    city VARCHAR2(100),
    region VARCHAR2(100),
    state VARCHAR2(100),
    country VARCHAR2(100),
    postal_code VARCHAR2(20),
    CONSTRAINT pk_hotel PRIMARY KEY (hotel_id)
);

CREATE TABLE Guest (
    guest_id NUMBER(10) NOT NULL,
    first_name VARCHAR2(50),
    last_name VARCHAR2(50),
    email VARCHAR2(100),
    phone VARCHAR2(20),
    city VARCHAR2(100),
    region VARCHAR2(100),
    state VARCHAR2(100),
    country VARCHAR2(100),
    postal_code VARCHAR2(20),
    CONSTRAINT pk_guest PRIMARY KEY (guest_id)
);

CREATE TABLE Jobs (
    job_id NUMBER(10) NOT NULL,
    job_title VARCHAR2(100),
    min_salary NUMBER(10,2),
    max_salary NUMBER(10,2),
    CONSTRAINT pk_jobs PRIMARY KEY (job_id)
);


-- First-Level Dependent Tables
-- ------------------------------------------------------
CREATE TABLE Department (
    department_id NUMBER(10) NOT NULL,
    department_name VARCHAR2(100),
    hotel_id NUMBER(10),
    CONSTRAINT pk_department PRIMARY KEY (department_id),
    CONSTRAINT fk_dept_hotel FOREIGN KEY (hotel_id) REFERENCES Hotel(hotel_id)
);

CREATE TABLE Booking (
    booking_id NUMBER(10) NOT NULL,
    total_price NUMBER(10,2),
    payment_method VARCHAR2(50),
    payment_date DATE,
    guest_id NUMBER(10),
    CONSTRAINT pk_booking PRIMARY KEY (booking_id),
    CONSTRAINT fk_booking_guest FOREIGN KEY (guest_id) REFERENCES Guest(guest_id)
);

CREATE TABLE Room (
    room_id NUMBER(10) NOT NULL,
    room_type VARCHAR2(50),
    bed_count NUMBER(2),
    price NUMBER(10,2),
    hotel_id NUMBER(10),
    CONSTRAINT pk_room PRIMARY KEY (room_id),
    CONSTRAINT fk_room_hotel FOREIGN KEY (hotel_id) REFERENCES Hotel(hotel_id)
);

CREATE TABLE Service (
    service_id NUMBER(10) NOT NULL,
    description VARCHAR2(255),
    service_name VARCHAR2(100),
    service_price NUMBER(10,2),
    hotel_id NUMBER(10),
    CONSTRAINT pk_service PRIMARY KEY (service_id),
    CONSTRAINT fk_service_hotel FOREIGN KEY (hotel_id) REFERENCES Hotel(hotel_id)
);


-- Second-Level Dependent Tables (Junction Tables, etc.)
-- ------------------------------------------------------
CREATE TABLE Employee (
    employee_id NUMBER(10) NOT NULL,
    first_name VARCHAR2(50),
    last_name VARCHAR2(50),
    email VARCHAR2(100),
    job_id NUMBER(10),
    department_id NUMBER(10),
    CONSTRAINT pk_employee PRIMARY KEY (employee_id),
    CONSTRAINT fk_emp_job FOREIGN KEY (job_id) REFERENCES Jobs(job_id),
    CONSTRAINT fk_emp_dept FOREIGN KEY (department_id) REFERENCES Department(department_id)
);

CREATE TABLE BookingDetail (
    booking_id NUMBER(10) NOT NULL,
    room_id NUMBER(10) NOT NULL,
    duration_days NUMBER(3),
    checkin_date DATE,
    checkout_date DATE,
    num_of_guest NUMBER(2),
    CONSTRAINT pk_bookingdetail PRIMARY KEY (booking_id, room_id),
    CONSTRAINT fk_bd_booking FOREIGN KEY (booking_id) REFERENCES Booking(booking_id),
    CONSTRAINT fk_bd_room FOREIGN KEY (room_id) REFERENCES Room(room_id)
);

CREATE TABLE GuestService (
    guest_id NUMBER(10) NOT NULL,
    service_id NUMBER(10) NOT NULL,
    booking_date DATE,
    usage_date DATE,
    CONSTRAINT pk_guestservice PRIMARY KEY (guest_id, service_id),
    CONSTRAINT fk_gs_guest FOREIGN KEY (guest_id) REFERENCES Guest(guest_id),
    CONSTRAINT fk_gs_service FOREIGN KEY (service_id) REFERENCES Service(service_id)
);
