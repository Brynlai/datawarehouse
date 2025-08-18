-- ====================================================================
-- Data Warehouse Load Verification Script
-- Description: Run this script after P_RUN_INITIAL_LOAD to verify
--              the integrity and accuracy of the data warehouse.
-- ====================================================================

SET SERVEROUTPUT ON;
SET TERMOUT ON;

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