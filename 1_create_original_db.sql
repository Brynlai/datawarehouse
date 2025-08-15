-- ====================================================================
-- Production-Ready OLTP Database DDL
-- Database: Oracle 11g
-- Execution: This script is idempotent and can be run in its entirety.
-- ====================================================================

-- Part 0: CLEANUP SCRIPT
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


-- Part 1: SEQUENCES
-- --------------------------------------------------------------------
CREATE SEQUENCE hotel_seq START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE guest_seq START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE jobs_seq START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE department_seq START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE employee_seq START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE booking_seq START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE room_seq START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE service_seq START WITH 1 INCREMENT BY 1 NOCACHE;


-- Part 2: TABLES
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
    hotel_id NUMBER(10) NOT NULL,
    CONSTRAINT pk_service PRIMARY KEY (service_id),
    CONSTRAINT fk_service_hotel FOREIGN KEY (hotel_id) REFERENCES Hotel(hotel_id)
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
    CONSTRAINT pk_guestservice PRIMARY KEY (guest_id, service_id),
    CONSTRAINT fk_gs_guest FOREIGN KEY (guest_id) REFERENCES Guest(guest_id),
    CONSTRAINT fk_gs_service FOREIGN KEY (service_id) REFERENCES Service(service_id)
);


-- Part 3: INDEXES
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


-- Part 4: TRIGGERS
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