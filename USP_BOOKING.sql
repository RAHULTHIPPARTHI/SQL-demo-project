/**************************************************************
	SP Name			    : USP_ManageAppointment 
	Purpose		        : Allows patients to book appointments with doctors based on availability.
	Created By          : Rahul Thipparthi
	Created On          : 07/03/25
	Modified By         : Rahul Thipparthi
	Modified ON         : 07/03/25
	Modified            : Initial creation of the procedure.
****************************************************************/ 

EXEC sp_rename 'spUserAppointments', 'USP_UserAppointments';

EXEC sp_rename 'spManageAppointment', 'USP_ManageAppointment';

EXEC sp_rename 'spGetDoctorAvailability', 'USP_GetDoctorAvailability';

/* Checking Doctor Availability*/

CREATE PROCEDURE USP_GetDoctorAvailability
    @DoctorID INT = NULL -- Optional: If NULL, show all doctors' availability
AS
BEGIN
    -- Retrieve availability for all doctors or a specific doctor
    SELECT 
        DA.AvailabilityId,
        D.DoctorId,
        U.Name AS DoctorName,
        D.Speciality,
        DA.Date AS AvailableDate,
        DA.TimeSlot,
        DA.Status
    FROM DoctorAvailability DA
    JOIN Doctors D ON DA.DoctorId = D.DoctorId
    JOIN Users U ON D.UserId = U.UserId
    WHERE (@DoctorID IS NULL OR D.DoctorId = @DoctorID)
END;



EXEC USP_GetDoctorAvailability;




-------------------------------------------------------------------------------

/* SP for Manage Appointments */

CREATE PROCEDURE USP_ManageAppointment
    @Action NVARCHAR(15),  -- 'Book', 'Reschedule', 'Cancel'
    @UserId INT = NULL,  
    @AvailabilityId INT = NULL,  -- New availability ID for rescheduling
    @AppointmentId INT = NULL  
AS
BEGIN
    DECLARE @ExistingAvailabilityId INT;
    DECLARE @ExistingStatus NVARCHAR(15);
    DECLARE @SlotStatus NVARCHAR(15);
    DECLARE @DoctorId INT;
    DECLARE @NewDoctorId INT;
    DECLARE @AppointmentDate DATE;
    DECLARE @AppointmentTime VARCHAR(30);

    -- **NULL Parameter Checks**
    IF @Action IS NULL
    BEGIN
        PRINT 'Error: Action parameter cannot be NULL.';
        RETURN;
    END

    -- **Booking an Appointment**
    IF @Action = 'Book'
    BEGIN
        IF @UserId IS NULL
        BEGIN
            PRINT 'Error: UserId cannot be NULL.';
            RETURN;
        END

        IF @AvailabilityId IS NULL
        BEGIN
            PRINT 'Error: AvailabilityId cannot be NULL.';
            RETURN;
        END

        -- Fetch details for the selected availability
        SELECT @AppointmentDate = Date, @AppointmentTime = TimeSlot, @SlotStatus = Status, @DoctorId = DoctorId
        FROM DoctorAvailability 
        WHERE AvailabilityId = @AvailabilityId;

        IF @SlotStatus IS NULL
        BEGIN
            PRINT 'Selected availability not found';
            RETURN;
        END

        IF @SlotStatus <> 'Available'
        BEGIN
            PRINT 'Selected time slot is not available';
            RETURN;
        END

        -- Insert new Appointment
        INSERT INTO Appointment (UserId, AvailabilityId, AppointmentDate, AppointmentTime, Status, CreatedAt)
        VALUES (@UserId, @AvailabilityId, @AppointmentDate, @AppointmentTime, 'Scheduled', GETDATE());

        -- Mark selected slot as 'Booked'
        UPDATE DoctorAvailability
        SET Status = 'Booked'
        WHERE AvailabilityId = @AvailabilityId;

        PRINT 'Appointment booked successfully';
    END

    -- **Rescheduling an Appointment**
    ELSE IF @Action = 'Reschedule'
    BEGIN
        IF @AppointmentId IS NULL
        BEGIN
            PRINT 'Error: AppointmentId cannot be NULL.';
            RETURN;
        END

        IF @AvailabilityId IS NULL
        BEGIN
            PRINT 'Error: New AvailabilityId cannot be NULL.';
            RETURN;
        END

        -- Get the current appointment details
        SELECT @ExistingAvailabilityId = AvailabilityId, @ExistingStatus = Status
        FROM Appointment 
        WHERE AppointmentId = @AppointmentId;

        IF @ExistingAvailabilityId IS NULL
        BEGIN
            PRINT 'Appointment not found';
            RETURN;
        END

        -- Prevent rescheduling if the appointment is cancelled
        IF @ExistingStatus = 'Cancelled'
        BEGIN
            PRINT 'Cancelled appointments cannot be rescheduled';
            RETURN;
        END

        -- Get the DoctorId of the existing appointment
        SELECT @DoctorId = DoctorId FROM DoctorAvailability WHERE AvailabilityId = @ExistingAvailabilityId;

        -- Get details of the new slot
        SELECT @SlotStatus = Status, @AppointmentDate = Date, @AppointmentTime = TimeSlot, @NewDoctorId = DoctorId
        FROM DoctorAvailability 
        WHERE AvailabilityId = @AvailabilityId;

        IF @SlotStatus IS NULL
        BEGIN
            PRINT 'Selected availability not found';
            RETURN;
        END

        IF @SlotStatus <> 'Available'
        BEGIN
            PRINT 'Selected time slot is not available';
            RETURN;
        END

        -- Ensure the new slot belongs to the same doctor
        IF @DoctorId <> @NewDoctorId
        BEGIN
            PRINT 'Rescheduling can only be done for the same doctor';
            RETURN;
        END

        -- Update Appointment with new AvailabilityId, Date, and Time, and set Status = 'Rescheduled'
        UPDATE Appointment
        SET AvailabilityId = @AvailabilityId, AppointmentDate = @AppointmentDate, AppointmentTime = @AppointmentTime, Status = 'Rescheduled'
        WHERE AppointmentId = @AppointmentId;

        -- Free up the previous slot (set to Available)
        UPDATE DoctorAvailability
        SET Status = 'Available'
        WHERE AvailabilityId = @ExistingAvailabilityId;

        -- Mark the new slot as 'Booked'
        UPDATE DoctorAvailability
        SET Status = 'Booked'
        WHERE AvailabilityId = @AvailabilityId;

        PRINT 'Appointment rescheduled successfully';
    END

    -- **Cancelling an Appointment**
    ELSE IF @Action = 'Cancel'
    BEGIN
        IF @AppointmentId IS NULL
        BEGIN
            PRINT 'Error: AppointmentId cannot be NULL.';
            RETURN;
        END

        -- Check if Appointment exists
        SELECT @ExistingAvailabilityId = AvailabilityId 
        FROM Appointment 
        WHERE AppointmentId = @AppointmentId;

        IF @ExistingAvailabilityId IS NULL
        BEGIN
            PRINT 'Error: Appointment not found';
            RETURN;
        END

        -- Update Appointment status to 'Cancelled'
        UPDATE Appointment
        SET Status = 'Cancelled'
        WHERE AppointmentId = @AppointmentId;

        -- Free up the slot
        UPDATE DoctorAvailability
        SET Status = 'Available'
        WHERE AvailabilityId = @ExistingAvailabilityId;

        PRINT 'Appointment cancelled successfully';
    END

    ELSE
    BEGIN
        PRINT 'Error: Invalid action. Use Book, Reschedule, or Cancel.';
    END
END;


/*CHECK USERS Appoinmnets*/

CREATE PROCEDURE USP_UserAppointments
    @UserId INT
AS
BEGIN
    DECLARE @UserCheck INT;

    -- Check if UserId exists
    SELECT @UserCheck = UserId FROM Users WHERE @UserId = UserId;
    
    IF @UserCheck IS NULL
    BEGIN
        PRINT 'User ID not found';
        RETURN;
    END

    -- Retrieve the user's appointments with doctor and availability details
    SELECT 
        A.AppointmentId,
        A.AppointmentDate,
        A.AppointmentTime,
        A.Status AS AppointmentStatus,
        D.Name AS DoctorName,
        DA.Date AS AvailableDate,
        DA.TimeSlot AS AvailableTime,
        DA.Status AS SlotStatus
    FROM Appointment A
    INNER JOIN DoctorAvailability DA ON A.AvailabilityId = DA.AvailabilityId
    INNER JOIN Doctors Doc ON DA.DoctorId = Doc.DoctorId
    INNER JOIN Users D ON Doc.UserId = D.UserId
    WHERE A.UserId = @UserId
END;


	/**************************************************************
Test Cases for USP_ManageAppointment
**************************************************************/

-- Test Case 1: Booking an Appointment
-- Scenario: Book an appointment for UserId =  with AvailabilityId = 1
-- Expected Output: Appointment should be inserted into the Appointment table
--                  DoctorAvailability should be updated to 'Booked'
--                  'Appointment booked successfully' message should be printed

EXEC USP_GetDoctorAvailability; -- Check availability before booking

EXEC USP_ManageAppointment 
    @Action = 'cancel', 
    @UserId = 15, 
    @AvailabilityId = 5;

EXEC USP_UserAppointments  @USERID = 15 -- Verify booking
EXEC USP_GetDoctorAvailability; -- Check updated availability


/**************************************************************/

-- Test Case 2: Rescheduling an Appointment
-- Scenario: Reschedule AppointmentId = 13 to AvailabilityId = 1
-- Expected Output: Appointment should be updated with new AvailabilityId, Date, and Time
--                  Old slot should be set to 'Available', new slot should be 'Booked'
--                  'Appointment rescheduled successfully' message should be printed

EXEC USP_UserAppointments  @USERID = 3  -- Check before rescheduling
EXEC USP_GetDoctorAvailability; -- Check new slot availability

EXEC USP_ManageAppointment 
    @Action = 'Reschedule', 
    @AppointmentId = 16, 
    @AvailabilityId = 14;

EXEC USP_UserAppointments  @USERID = 16 -- Verify rescheduling
EXEC USP_GetDoctorAvailability;  -- Verify new slot is booked


/**************************************************************/

-- Test Case 3: Cancelling an Appointment
-- Scenario: Cancel AppointmentId = 12
-- Expected Output: Appointment status should be updated to 'Cancelled'
--                  Corresponding DoctorAvailability slot should be updated to 'Available'
--                  'Appointment cancelled successfully' message should be printed

EXEC USP_UserAppointments  @USERID = 3 -- Check before cancellation
EXEC USP_GetDoctorAvailability; -- Check availability

EXEC USP_ManageAppointment 
    @Action = 'Cancel', 
    @AppointmentId = 15;

EXEC USP_UserAppointments  @USERID = 15  -- Verify cancellation
EXEC USP_GetDoctorAvailability; -- Verify availability update


/**************************************************************/

-- Test Case 4: Attempting to Book a Non-Available Slot
-- Scenario: Book an appointment for UserId = 4 with AvailabilityId = 1 (Already Booked)
-- Expected Output: 'Selected time slot is not available' message should be printed
--                  No changes should be made to the Appointment table

EXEC USP_GetDoctorAvailability; -- Check availability
SELECT * FROM  Appointment
SELECT * FROM Users

EXEC USP_ManageAppointment 
    @Action = 'Book', 
    @UserId = 4, 
    @AvailabilityId = 1;


/**************************************************************/

-- Test Case 5: Rescheduling to an Already Booked Slot
-- Scenario: Reschedule AppointmentId = 13 to AvailabilityId = 1 (Already Booked)
-- Expected Output: 'Selected time slot is not available' message should be printed
--                  No changes should be made to the Appointment table

EXEC USP_GetDoctorAvailability; -- Check availability
SELECT * FROM  Appointment

EXEC USP_ManageAppointment 
    @Action = 'Reschedule', 
    @AppointmentId = 13, 
    @AvailabilityId = 1;


/**************************************************************/

-- Test Case 6: Rescheduling to a Different Doctor
-- Scenario: Reschedule AppointmentId = 13 to AvailabilityId = 3 (Different Doctor)
-- Expected Output: 'Rescheduling can only be done for the same doctor' message should be printed
--                  No changes should be made to the Appointment table

EXEC USP_GetDoctorAvailability; -- Check availability
SELECT * FROM  Appointment 

EXEC USP_ManageAppointment 
    @Action = 'Reschedule', 
    @AppointmentId = 13, 
    @AvailabilityId = 3;


/**************************************************************/

-- Test Case 7: Cancelling a Non-Existing Appointment
-- Scenario: Cancel an appointment that does not exist (AppointmentId = 999)
-- Expected Output: 'Error: Appointment not found' message should be printed
--                  No changes should be made

EXEC USP_ManageAppointment 
    @Action = 'Cancel', 
    @AppointmentId = 999;


/**************************************************************/

-- Test Case 8: Using an Invalid Action
-- Scenario: Pass an invalid action ('Update')
-- Expected Output: 'Error: Invalid action. Use Book, Reschedule, or Cancel.' message should be printed
--                  No changes should be made

EXEC USP_ManageAppointment 
    @Action = 'Update', 
    @UserId = 3, 
    @AvailabilityId = 1;
