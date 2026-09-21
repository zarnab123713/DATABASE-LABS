-- ============================================================
-- DATABASE MANAGEMENT SYSTEM
-- OPEN-ENDED LAB - CAR RENTAL MANAGEMENT SYSTEM
-- SQL SOURCE FILE
-- Target DBMS: MySQL 8.0+
--
-- This SQL follows the submitted report in the required sequence:
-- 1. Assignment / Database Design & Implementation
-- 2. Constraints
-- 3. Efficiency Improvements
-- 4. Normalization: 1NF -> 2NF -> 3NF
-- 5. JOIN Queries: Q1 -> Q4
-- 6. VIEW
-- 7. TRIGGER
-- 8. STORED PROCEDURE
-- 9. Optimization / indexes
-- 10. Sample data
-- 11. Testing statements
--
-- IMPORTANT:
-- The report states that RentalDays is stored when a rental is
-- registered, so it is retained here to match the report.
-- ============================================================


-- ============================================================
-- TASK 1 — DATABASE DESIGN AND IMPLEMENTATION
-- ============================================================

DROP DATABASE IF EXISTS CarGoRentals;
CREATE DATABASE CarGoRentals;
USE CarGoRentals;


-- ------------------------------------------------------------
-- 1.1 CUSTOMERS TABLE
-- Purpose:
-- Customer identity and contact information.
-- Primary Key: CustomerID
-- ------------------------------------------------------------

CREATE TABLE Customers (
    CustomerID INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    CustomerName VARCHAR(100) NOT NULL,
    CustomerPhone VARCHAR(20) NOT NULL UNIQUE,
    CustomerEmail VARCHAR(120) UNIQUE,
    DriverLicenseNo VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB;


-- ------------------------------------------------------------
-- 1.2 VEHICLES TABLE
-- Purpose:
-- Vehicle identity, model, daily rate and availability.
-- Primary Key: VehicleID
-- ------------------------------------------------------------

CREATE TABLE Vehicles (
    VehicleID INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    VehicleNumber VARCHAR(20) NOT NULL UNIQUE,
    VehicleModel VARCHAR(80) NOT NULL,
    DailyRate DECIMAL(10,2) NOT NULL,
    VehicleStatus ENUM('Available','Rented','Maintenance')
        NOT NULL DEFAULT 'Available',

    CONSTRAINT chk_vehicle_rate
        CHECK (DailyRate > 0)
) ENGINE=InnoDB;


-- ------------------------------------------------------------
-- 1.3 RENTALS TABLE
-- Purpose:
-- Rental transaction, dates, rental days and rental charge.
-- Primary Key: RentalID
-- Foreign Keys: CustomerID, VehicleID
-- ------------------------------------------------------------

CREATE TABLE Rentals (
    RentalID INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    CustomerID INT UNSIGNED NOT NULL,
    VehicleID INT UNSIGNED NOT NULL,

    RentalDate DATE NOT NULL,
    ReturnDate DATE NULL,

    RentalDays INT UNSIGNED NULL,

    RentalCharge DECIMAL(10,2) NOT NULL DEFAULT 0,

    CONSTRAINT fk_rental_customer
        FOREIGN KEY (CustomerID)
        REFERENCES Customers(CustomerID),

    CONSTRAINT fk_rental_vehicle
        FOREIGN KEY (VehicleID)
        REFERENCES Vehicles(VehicleID),

    CONSTRAINT chk_rental_dates
        CHECK (
            ReturnDate IS NULL
            OR ReturnDate >= RentalDate
        ),

    CONSTRAINT chk_rental_days
        CHECK (
            RentalDays IS NULL
            OR RentalDays > 0
        ),

    CONSTRAINT chk_rental_charge
        CHECK (RentalCharge >= 0)
) ENGINE=InnoDB;


-- ------------------------------------------------------------
-- 1.4 PAYMENTS TABLE
-- Purpose:
-- Payment amount, date, method and status.
-- Primary Key: PaymentID
-- Foreign Key: RentalID
-- ------------------------------------------------------------

CREATE TABLE Payments (
    PaymentID INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    RentalID INT UNSIGNED NOT NULL UNIQUE,

    PaymentAmount DECIMAL(10,2) NOT NULL,

    PaymentDate DATE NOT NULL DEFAULT (CURRENT_DATE),

    PaymentMethod ENUM(
        'Cash',
        'Card',
        'Bank Transfer',
        'Online'
    ) NOT NULL,

    PaymentStatus ENUM(
        'Paid',
        'Pending',
        'Partial'
    ) NOT NULL DEFAULT 'Paid',

    CONSTRAINT fk_payment_rental
        FOREIGN KEY (RentalID)
        REFERENCES Rentals(RentalID),

    CONSTRAINT chk_payment_amount
        CHECK (PaymentAmount >= 0)
) ENGINE=InnoDB;


-- ============================================================
-- TASK 1.2 — CONSTRAINTS
-- ============================================================
--
-- PRIMARY KEY:
-- Uniquely identifies every row.
--
-- FOREIGN KEY:
-- Prevents orphan rental/payment records.
--
-- NOT NULL:
-- Ensures required fields are supplied.
--
-- UNIQUE:
-- Prevents duplicate phone numbers, emails, licenses
-- and vehicle numbers.
--
-- CHECK:
-- Prevents invalid rates, negative payments/charges
-- and invalid rental dates.
--
-- DEFAULT:
-- Supplies sensible default values such as Available
-- vehicle status and payment date/status.
--
-- ENUM:
-- Restricts status and payment-method values to defined
-- business options.
-- ============================================================


-- ============================================================
-- TASK 1.3 — EFFICIENCY IMPROVEMENTS IN THE DESIGN
-- ============================================================
--
-- INT UNSIGNED keys reduce unnecessary key-space overhead
-- for positive identifiers.
--
-- Foreign-key columns are indexed because they are frequently
-- used in JOIN operations.
--
-- Composite index on (VehicleID, ReturnDate) supports the
-- current-rental lookup.
--
-- Composite index on (CustomerID, RentalDate) supports
-- customer rental-history queries.
--
-- RentalDays is stored when the rental is registered, avoiding
-- repeated DATEDIFF calculations in reports.
--
-- The stored procedure uses a transaction and SELECT ... FOR UPDATE
-- so the selected vehicle is locked while its rental is created.
--
-- The design avoids redundant customer and vehicle attributes
-- inside Rentals, reducing update anomalies and storage duplication.
-- ============================================================


-- ============================================================
-- TASK 2 — NORMALIZATION
-- ============================================================
--
-- Original unnormalized rental structure from the report:
--
-- RentalID
-- CustomerName
-- CustomerPhone
-- VehicleNumber
-- VehicleModel
-- DailyRate
-- RentalDate
-- ReturnDate
-- PaymentAmount
--
-- ============================================================
-- 2.1 FIRST NORMAL FORM (1NF)
-- ============================================================
--
-- 1NF requires:
-- 1. Atomic values.
-- 2. No repeating groups.
-- 3. A unique identifier for each record.
--
-- The supplied sample contains single atomic values.
-- RentalID identifies one rental transaction.
--
-- Customer and vehicle information may still repeat across
-- multiple rental records at this stage.
--
-- ============================================================
-- 2.2 SECOND NORMAL FORM (2NF)
-- ============================================================
--
-- RentalID identifies a rental.
--
-- Customer details are facts about Customers.
-- Vehicle details are facts about Vehicles.
--
-- Therefore, customer and vehicle details are separated into
-- Customers and Vehicles.
--
-- Rentals keeps CustomerID and VehicleID as foreign keys.
--
-- This reduces repeated information and update anomalies.
--
-- ============================================================
-- 2.3 THIRD NORMAL FORM (3NF)
-- ============================================================
--
-- 3NF removes dependencies where a non-key attribute depends
-- on another non-key attribute.
--
-- CustomerName, CustomerPhone and DriverLicenseNo depend on
-- CustomerID.
--
-- VehicleModel and DailyRate depend on VehicleID.
--
-- Rental dates and RentalCharge depend on RentalID.
--
-- Payment information is separated into Payments.
--
-- Final normalized relations:
-- Customers
-- Vehicles
-- Rentals
-- Payments
--
-- This reduces insertion, update and deletion anomalies.
-- ============================================================


-- ============================================================
-- NORMALIZATION STRUCTURE SUMMARY
-- ============================================================
--
-- 1NF:
-- Atomic rental rows
-- Problem: Customer/vehicle data repeats
-- Improvement: Atomic values and unique rental records
--
-- 2NF:
-- Customers + Vehicles + Rentals
-- Problem: Repeated entity data
-- Improvement: Move entity facts to their own tables
--
-- 3NF:
-- Customers + Vehicles + Rentals + Payments
-- Problem: Non-key dependency/redundancy
-- Improvement: Separate payment facts and preserve
-- key-based dependencies
-- ============================================================


-- ============================================================
-- SAMPLE DATA
-- ============================================================

-- ------------------------------------------------------------
-- CUSTOMERS
-- ------------------------------------------------------------

INSERT INTO Customers
    (CustomerName, CustomerPhone, CustomerEmail, DriverLicenseNo)
VALUES
    ('Ali Khan',    '0300-1234567', 'ali@example.com',    'DL-10001'),
    ('Sara Ahmed',  '0311-7654321', 'sara@example.com',  'DL-10002'),
    ('Usman Raza',  '0322-4567890', 'usman@example.com',  'DL-10003'),
    ('Ayesha Malik','0333-2223344', 'ayesha@example.com', 'DL-10004'),
    ('Hamza Noor',  '0344-5556677', 'hamza@example.com',  'DL-10005');


-- ------------------------------------------------------------
-- VEHICLES
-- ------------------------------------------------------------

INSERT INTO Vehicles
    (VehicleNumber, VehicleModel, DailyRate, VehicleStatus)
VALUES
    ('ABC-123', 'Toyota Corolla', 5000.00, 'Available'),
    ('LEA-456', 'Honda Civic',    6500.00, 'Available'),
    ('ISL-789', 'Suzuki Alto',    3500.00, 'Available'),
    ('KHI-321', 'Toyota Yaris',   5500.00, 'Available'),
    ('LHR-654', 'Honda City',     6000.00, 'Available');


-- ============================================================
-- TASK 5 / TASK 6 — TRIGGER
-- ============================================================
--
-- The report requires a TRIGGER even though the manual's task
-- numbering skips from VIEW to Stored Procedure.
--
-- Trigger 1:
-- Reject rental when vehicle is not Available.
--
-- Trigger 2:
-- Change vehicle back to Available when ReturnDate is recorded.
-- ============================================================

DELIMITER $$


-- ------------------------------------------------------------
-- TRIGGER 1: BEFORE INSERT
-- Prevent unavailable vehicle rental
-- ------------------------------------------------------------

CREATE TRIGGER trg_rentals_before_insert
BEFORE INSERT ON Rentals
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(20);

    SELECT VehicleStatus
      INTO v_status
      FROM Vehicles
     WHERE VehicleID = NEW.VehicleID
     FOR UPDATE;

    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Vehicle does not exist';
    END IF;

    IF v_status <> 'Available' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
                'Vehicle is already rented or unavailable';
    END IF;
END$$


-- ------------------------------------------------------------
-- TRIGGER 2: AFTER UPDATE
-- Restore vehicle availability after completed rental
-- ------------------------------------------------------------

CREATE TRIGGER trg_rentals_after_update
AFTER UPDATE ON Rentals
FOR EACH ROW
BEGIN
    IF NEW.ReturnDate IS NOT NULL
       AND OLD.ReturnDate IS NULL THEN

        UPDATE Vehicles
           SET VehicleStatus = 'Available'
         WHERE VehicleID = NEW.VehicleID;

    END IF;
END$$

DELIMITER ;


-- ============================================================
-- TASK 6 — STORED PROCEDURE
-- ============================================================
--
-- RegisterRental accepts:
-- customer ID
-- vehicle ID
-- rental date
-- return date
--
-- It:
-- 1. Validates dates.
-- 2. Verifies the customer.
-- 3. Locks the vehicle row.
-- 4. Checks vehicle availability.
-- 5. Calculates rental days.
-- 6. Calculates rental charge.
-- 7. Inserts rental.
-- 8. Updates vehicle status.
-- 9. Commits transaction.
-- ============================================================

DELIMITER $$

CREATE PROCEDURE RegisterRental (
    IN p_customer_id INT UNSIGNED,
    IN p_vehicle_id INT UNSIGNED,
    IN p_rental_date DATE,
    IN p_return_date DATE
)
BEGIN
    DECLARE v_daily_rate DECIMAL(10,2);
    DECLARE v_status VARCHAR(20);
    DECLARE v_days INT UNSIGNED;

    START TRANSACTION;


    -- Validate dates
    IF p_rental_date IS NULL OR p_return_date IS NULL THEN
        ROLLBACK;

        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
                'Rental and return dates are required';
    END IF;


    IF p_return_date < p_rental_date THEN
        ROLLBACK;

        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
                'Return date cannot be before rental date';
    END IF;


    -- Verify and lock vehicle
    SELECT DailyRate, VehicleStatus
      INTO v_daily_rate, v_status
      FROM Vehicles
     WHERE VehicleID = p_vehicle_id
     FOR UPDATE;


    IF v_daily_rate IS NULL THEN
        ROLLBACK;

        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
                'Vehicle does not exist';
    END IF;


    -- Check availability
    IF v_status <> 'Available' THEN
        ROLLBACK;

        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
                'Vehicle is not available';
    END IF;


    -- Verify customer
    IF NOT EXISTS (
        SELECT 1
          FROM Customers
         WHERE CustomerID = p_customer_id
    ) THEN

        ROLLBACK;

        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
                'Customer does not exist';
    END IF;


    -- Calculate rental days
    SET v_days =
        GREATEST(
            DATEDIFF(p_return_date, p_rental_date),
            1
        );


    -- Insert rental
    INSERT INTO Rentals
        (
            CustomerID,
            VehicleID,
            RentalDate,
            ReturnDate,
            RentalDays,
            RentalCharge
        )
    VALUES
        (
            p_customer_id,
            p_vehicle_id,
            p_rental_date,
            p_return_date,
            v_days,
            v_days * v_daily_rate
        );


    -- Update vehicle status
    UPDATE Vehicles
       SET VehicleStatus = 'Rented'
     WHERE VehicleID = p_vehicle_id;


    COMMIT;
END$$

DELIMITER ;


-- ============================================================
-- SAMPLE RENTALS
-- ============================================================

CALL RegisterRental(
    1,
    1,
    '2026-09-01',
    '2026-09-04'
);

CALL RegisterRental(
    2,
    2,
    '2026-09-05',
    '2026-09-07'
);


-- ============================================================
-- SAMPLE PAYMENTS
-- ============================================================

INSERT INTO Payments
    (
        RentalID,
        PaymentAmount,
        PaymentDate,
        PaymentMethod,
        PaymentStatus
    )
VALUES
    (1, 15000.00, '2026-09-04', 'Cash', 'Paid'),
    (2, 13000.00, '2026-09-07', 'Card', 'Paid');


-- ============================================================
-- TASK 4 — VIEW
-- ============================================================
--
-- RentalReport is a consolidated view containing:
-- Customer information
-- Vehicle information
-- Rental information
-- Payment information
--
-- It allows management to query one reusable object instead
-- of rewriting the same multi-table JOIN.
-- ============================================================

CREATE VIEW RentalReport AS
SELECT
    r.RentalID,

    c.CustomerName,
    c.CustomerPhone,

    v.VehicleNumber,
    v.VehicleModel,
    v.DailyRate,

    r.RentalDate,
    r.ReturnDate,
    r.RentalDays,
    r.RentalCharge,

    p.PaymentAmount,
    p.PaymentDate,
    p.PaymentMethod,
    p.PaymentStatus

FROM Rentals AS r

INNER JOIN Customers AS c
    ON c.CustomerID = r.CustomerID

INNER JOIN Vehicles AS v
    ON v.VehicleID = r.VehicleID

LEFT JOIN Payments AS p
    ON p.RentalID = r.RentalID;


-- ============================================================
-- TASK 3 — JOIN QUERIES
-- ============================================================


-- ------------------------------------------------------------
-- Q1 — EVERY RENTAL
-- Display:
-- Customer name
-- Vehicle number
-- Vehicle model
-- Rental date
-- Return date
-- ------------------------------------------------------------

SELECT
    c.CustomerName,
    v.VehicleNumber,
    v.VehicleModel,
    r.RentalDate,
    r.ReturnDate
FROM Rentals AS r
INNER JOIN Customers AS c
    ON c.CustomerID = r.CustomerID
INNER JOIN Vehicles AS v
    ON v.VehicleID = r.VehicleID
ORDER BY
    r.RentalDate,
    r.RentalID;


-- ------------------------------------------------------------
-- Q2 — ALL CUSTOMERS
-- Customers with no rentals must also appear.
-- ------------------------------------------------------------

SELECT
    c.CustomerName,
    v.VehicleNumber,
    v.VehicleModel,
    r.RentalDate,
    r.ReturnDate
FROM Customers AS c
LEFT JOIN Rentals AS r
    ON r.CustomerID = c.CustomerID
LEFT JOIN Vehicles AS v
    ON v.VehicleID = r.VehicleID
ORDER BY
    c.CustomerName,
    r.RentalDate;


-- ------------------------------------------------------------
-- Q3 — ALL VEHICLES
-- Vehicles that are currently not rented must also appear.
-- ------------------------------------------------------------

SELECT
    v.VehicleNumber,
    v.VehicleModel,
    v.VehicleStatus,
    c.CustomerName,
    r.RentalDate,
    r.ReturnDate
FROM Vehicles AS v
LEFT JOIN Rentals AS r
    ON r.VehicleID = v.VehicleID
   AND r.ReturnDate IS NULL
LEFT JOIN Customers AS c
    ON c.CustomerID = r.CustomerID
ORDER BY
    v.VehicleNumber;


-- ------------------------------------------------------------
-- Q4 — RENTAL COUNT
-- Include customers who have made zero rentals.
-- ------------------------------------------------------------

SELECT
    c.CustomerName,
    COUNT(r.RentalID) AS TotalRentals
FROM Customers AS c
LEFT JOIN Rentals AS r
    ON r.CustomerID = c.CustomerID
GROUP BY
    c.CustomerID,
    c.CustomerName
ORDER BY
    c.CustomerName;


-- ============================================================
-- TASK 7 — OPTIMIZATION ANALYSIS
-- ============================================================
--
-- Potential inefficiency:
-- As Rentals grows, JOINs and current-rental searches can
-- become slower without indexes.
--
-- Improvement:
-- Add indexes on:
-- 1. CustomerID
-- 2. VehicleID
-- 3. (VehicleID, ReturnDate)
-- 4. (CustomerID, RentalDate)
--
-- These indexes support frequent JOINs and filtering operations.
-- ============================================================


-- ------------------------------------------------------------
-- Optimization Index 1
-- Customer rental-history queries
-- ------------------------------------------------------------

CREATE INDEX idx_rentals_customer
ON Rentals(CustomerID);


-- ------------------------------------------------------------
-- Optimization Index 2
-- Vehicle rental JOIN queries
-- ------------------------------------------------------------

CREATE INDEX idx_rentals_vehicle
ON Rentals(VehicleID);


-- ------------------------------------------------------------
-- Optimization Index 3
-- Current-rental lookup
-- ------------------------------------------------------------

CREATE INDEX idx_rentals_active
ON Rentals(VehicleID, ReturnDate);


-- ------------------------------------------------------------
-- Optimization Index 4
-- Customer rental-history ordered by date
-- ------------------------------------------------------------

CREATE INDEX idx_rentals_customer_date
ON Rentals(CustomerID, RentalDate);


-- ============================================================
-- TASK 9 — TESTING AND SCREENSHOT CHECKLIST
-- ============================================================
--
-- The following statements should be executed and screenshots
-- should be captured in the same order.
--
-- Screenshot 1: Q1 output
-- Screenshot 2: Q2 output
-- Screenshot 3: Q3 output
-- Screenshot 4: Q4 output
-- Screenshot 5: VIEW output
-- Screenshot 6: TRIGGER test
-- Screenshot 7: STORED PROCEDURE test
-- ============================================================


-- ------------------------------------------------------------
-- SCREENSHOT 1 — Q1
-- ------------------------------------------------------------

SELECT
    c.CustomerName,
    v.VehicleNumber,
    v.VehicleModel,
    r.RentalDate,
    r.ReturnDate
FROM Rentals AS r
INNER JOIN Customers AS c
    ON c.CustomerID = r.CustomerID
INNER JOIN Vehicles AS v
    ON v.VehicleID = r.VehicleID
ORDER BY
    r.RentalDate,
    r.RentalID;


-- ------------------------------------------------------------
-- SCREENSHOT 2 — Q2
-- ------------------------------------------------------------

SELECT
    c.CustomerName,
    v.VehicleNumber,
    v.VehicleModel,
    r.RentalDate,
    r.ReturnDate
FROM Customers AS c
LEFT JOIN Rentals AS r
    ON r.CustomerID = c.CustomerID
LEFT JOIN Vehicles AS v
    ON v.VehicleID = r.VehicleID
ORDER BY
    c.CustomerName,
    r.RentalDate;


-- ------------------------------------------------------------
-- SCREENSHOT 3 — Q3
-- ------------------------------------------------------------

SELECT
    v.VehicleNumber,
    v.VehicleModel,
    v.VehicleStatus,
    c.CustomerName,
    r.RentalDate,
    r.ReturnDate
FROM Vehicles AS v
LEFT JOIN Rentals AS r
    ON r.VehicleID = v.VehicleID
   AND r.ReturnDate IS NULL
LEFT JOIN Customers AS c
    ON c.CustomerID = r.CustomerID
ORDER BY
    v.VehicleNumber;


-- ------------------------------------------------------------
-- SCREENSHOT 4 — Q4
-- ------------------------------------------------------------

SELECT
    c.CustomerName,
    COUNT(r.RentalID) AS TotalRentals
FROM Customers AS c
LEFT JOIN Rentals AS r
    ON r.CustomerID = c.CustomerID
GROUP BY
    c.CustomerID,
    c.CustomerName
ORDER BY
    c.CustomerName;


-- ------------------------------------------------------------
-- SCREENSHOT 5 — VIEW OUTPUT
-- ------------------------------------------------------------

SELECT *
FROM RentalReport;


-- ------------------------------------------------------------
-- SCREENSHOT 6 — TRIGGER TEST
--
-- Rental #1 currently has a ReturnDate.
-- First make it an active rental for testing.
-- Then update ReturnDate to demonstrate the AFTER UPDATE
-- trigger changing the vehicle back to Available.
-- ------------------------------------------------------------

UPDATE Rentals
SET ReturnDate = NULL
WHERE RentalID = 1;

UPDATE Vehicles
SET VehicleStatus = 'Rented'
WHERE VehicleID = (
    SELECT VehicleID
    FROM Rentals
    WHERE RentalID = 1
);

SELECT
    VehicleNumber,
    VehicleStatus
FROM Vehicles
WHERE VehicleNumber = 'ABC-123';


-- Complete rental #1.
-- The AFTER UPDATE trigger should make ABC-123 Available.

UPDATE Rentals
SET
    ReturnDate = '2026-09-04',
    RentalDays = GREATEST(
        DATEDIFF('2026-09-04', RentalDate),
        1
    )
WHERE RentalID = 1;


SELECT
    VehicleNumber,
    VehicleStatus
FROM Vehicles
WHERE VehicleNumber = 'ABC-123';


-- ------------------------------------------------------------
-- SCREENSHOT 6B — BEFORE INSERT TRIGGER TEST
--
-- Attempting to rent a vehicle that is not Available should
-- produce an error:
-- "Vehicle is already rented or unavailable"
--
-- Uncomment the following statement only if you want to
-- demonstrate the rejection behavior.
-- ------------------------------------------------------------

-- UPDATE Vehicles
-- SET VehicleStatus = 'Maintenance'
-- WHERE VehicleID = 3;

-- CALL RegisterRental(
--     3,
--     3,
--     '2026-09-10',
--     '2026-09-12'
-- );

-- UPDATE Vehicles
-- SET VehicleStatus = 'Available'
-- WHERE VehicleID = 3;


-- ------------------------------------------------------------
-- SCREENSHOT 7 — STORED PROCEDURE TEST
-- ------------------------------------------------------------
--
-- Vehicle 3 is available after the sample data.
-- This call registers a new rental and calculates its charge.
-- ------------------------------------------------------------

CALL RegisterRental(
    3,
    3,
    '2026-09-10',
    '2026-09-12'
);


-- Show resulting rental state.

SELECT
    r.RentalID,
    c.CustomerName,
    v.VehicleNumber,
    v.VehicleModel,
    r.RentalDate,
    r.ReturnDate,
    r.RentalDays,
    r.RentalCharge
FROM Rentals AS r
INNER JOIN Customers AS c
    ON c.CustomerID = r.CustomerID
INNER JOIN Vehicles AS v
    ON v.VehicleID = r.VehicleID
WHERE r.CustomerID = 3
ORDER BY r.RentalID DESC
LIMIT 1;


-- Show resulting vehicle state.

SELECT
    VehicleNumber,
    VehicleModel,
    VehicleStatus
FROM Vehicles
WHERE VehicleID = 3;


-- ============================================================
-- FINAL DATABASE VERIFICATION
-- ============================================================

-- Customers
SELECT * FROM Customers;

-- Vehicles
SELECT * FROM Vehicles;

-- Rentals
SELECT * FROM Rentals;

-- Payments
SELECT * FROM Payments;

-- Consolidated report
SELECT * FROM RentalReport;


-- ============================================================
-- END OF SQL SOURCE FILE
-- ============================================================
