/**************************************************************
	SP Name			    : USP_AddPrescription 
	Purpose		        : Add prescription and prescribed medicines
	Created By          : Rahul Thipparthi
	Created On          : 07/03/25
	Modified By         : Rahul Thipparthi
	Modified ON         : 07/03/25
	Modified            : Used variables for empty medicine list 
                          and invalid quantity validation.
****************************************************************/ 

EXEC sp_rename 'spAddPrescription', 'USP_AddPrescription';


-- User-Defined Table Type for Medicines
CREATE TYPE MedicineList AS TABLE
(
    MedicineId INT NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    Dosage NVARCHAR(50) NOT NULL
);



CREATE PROCEDURE USP_AddPrescription
    @AppointmentId INT,
    @Medicines MedicineList READONLY
AS
BEGIN
    DECLARE @PrescriptionId INT;
    DECLARE @ValidAppointmentId INT;
    DECLARE @MedicineCheck INT;
    DECLARE @MedicineCount INT;
    DECLARE @InvalidQuantity INT;

    BEGIN TRY
        -- Check if Appointment ID exists
        SELECT @ValidAppointmentId = AppointmentId FROM Appointment WHERE AppointmentId = @AppointmentId;
        
        IF @ValidAppointmentId IS NULL
        BEGIN
            PRINT 'Error: The specified Appointment ID does not exist.';
            RETURN;
        END

        -- Check if the provided medicine list is empty
        SELECT @MedicineCount = COUNT(*) FROM @Medicines;

        IF @MedicineCount = 0
        BEGIN
            PRINT 'Error: Medicine list cannot be empty.';
            RETURN;
        END

        -- Check for invalid Medicine IDs
        SELECT @MedicineCheck = M.MedicineId 
        FROM @Medicines M
        LEFT JOIN Medicine Med ON M.MedicineId = Med.MedicineId
        WHERE Med.MedicineId IS NULL;

        IF @MedicineCheck IS NOT NULL
        BEGIN
            PRINT 'Error: One or more Medicine IDs are invalid.';
            RETURN;
        END

        -- Check for invalid quantities
        SELECT @InvalidQuantity = COUNT(*) FROM @Medicines WHERE Quantity <= 0;

        IF @InvalidQuantity > 0
        BEGIN
            PRINT 'Error: Medicine quantity must be greater than zero.';
            RETURN;
        END

        -- Check if prescription already exists
        SELECT @PrescriptionId = PrescriptionId FROM Prescription WHERE AppointmentId = @AppointmentId;

        -- If not, create a new prescription
        IF @PrescriptionId IS NULL
        BEGIN
            INSERT INTO Prescription (AppointmentId) VALUES (@AppointmentId);
            SET @PrescriptionId = SCOPE_IDENTITY();
        END

        -- Insert prescribed medicines
        INSERT INTO PrescriptionDetails (PrescriptionId, MedicineId, Quantity, Dosage)
        SELECT @PrescriptionId, M.MedicineId, M.Quantity, M.Dosage FROM @Medicines M;

        PRINT 'Success: Prescription and medicines have been added successfully.';
    
    END TRY
    BEGIN CATCH
        -- Capture and display error message
        PRINT 'Error: ' + ERROR_MESSAGE();
    END CATCH
END;



/**************************************************************
Test Cases for USP_AddPrescription
**************************************************************/

-- Test Case 1: Valid Prescription Insertion
-- Expected Output: "Prescription added successfully!" 
-- The new prescription should be added to the Prescription table,
-- and the corresponding medicines should be added to PrescriptionDetails.

DECLARE @MedList MedicineList;
INSERT INTO @MedList (MedicineId, Quantity, Dosage)
VALUES 
    (1, 2, '2 tablets per day'); 

EXEC USP_AddPrescription @AppointmentId = 7, @Medicines = @MedList;

EXEC USP_GetAllMedicine;
EXEC USP_GetAllPrescriptions;
EXEC USP_GetAllPrescriptionDetails;

-- Test Case 2: Invalid Appointment ID
-- Expected Output: "Error: Invalid Appointment ID."
-- No new prescription should be created.

DECLARE @MedList2 MedicineList;
INSERT INTO @MedList2 (MedicineId, Quantity, Dosage)
VALUES 
    (1, 2, '2 tablets per day'); 

EXEC USP_AddPrescription @AppointmentId = 9999, @Medicines = @MedList2;


-- Test Case 3: Invalid Medicine ID
-- Expected Output: "Error: Invalid Medicine ID found."
-- No new records should be inserted.

DECLARE @MedList3 MedicineList;
INSERT INTO @MedList3 (MedicineId, Quantity, Dosage)
VALUES 
    (9999, 2, '2 tablets per day');  -- Invalid MedicineId

EXEC USP_AddPrescription @AppointmentId = 7, @Medicines = @MedList3;


-- Test Case 4: Prescription Already Exists for the Given Appointment
-- Expected Output: "Prescription added successfully!"
-- The prescription should not be duplicated, but new medicine records should be inserted.

DECLARE @MedList4 MedicineList;
INSERT INTO @MedList4 (MedicineId, Quantity, Dosage)
VALUES 
    (2, 1, '1 tablet per day');

EXEC USP_AddPrescription @AppointmentId = 7, @Medicines = @MedList4;

SELECT * FROM Prescription WHERE AppointmentId = 7;
SELECT * FROM PrescriptionDetails WHERE PrescriptionId IN (SELECT PrescriptionId FROM Prescription WHERE AppointmentId = 7);



-- Test Case 5: Empty Medicine List (Should Not Insert Anything)
-- Expected Output: No error, but no prescription details should be inserted.

DECLARE @MedList6 MedicineList;
EXEC USP_AddPrescription @AppointmentId = 7, @Medicines = @MedList6;

EXEC USP_GetAllMedicine;
EXEC USP_GetAllPrescriptions;
EXEC USP_GetAllPrescriptionDetails;