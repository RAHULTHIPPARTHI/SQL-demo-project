/**************************************************************
	SP Name			    : USP_AddFeedback
	Purpose		        : 
	Created By          : Rahul Thipparthi
	Created On          : 07/03/25
	Modified By         : Rahul Thipparthi
	Modified ON         : 07/03/25
	Modified            : Initial version
****************************************************************/
EXEC sp_rename 'uspAddFeedback', 'USP_AddFeedback';

CREATE PROCEDURE USP_AddFeedback
    @UserId INT,
    @DoctorId INT,
    @Rating INT,
    @Comments NVARCHAR(100)
AS
BEGIN
    DECLARE @ExistingUserId INT, @ExistingDoctorId INT;

    -- Check if UserId exists
    SELECT @ExistingUserId = UserId FROM Users WHERE UserId = @UserId;
    IF @ExistingUserId IS NULL
    BEGIN
        PRINT 'Error: User ID not found.';
        RETURN;
    END

    -- Check if DoctorId exists
    SELECT @ExistingDoctorId = DoctorId FROM Doctors WHERE DoctorId = @DoctorId;
    IF @ExistingDoctorId IS NULL
    BEGIN
        PRINT 'Error: Doctor ID not found.';
        RETURN;
    END

    -- Insert feedback
    INSERT INTO Feedback (UserId, DoctorId, Rating, Comments, CreatedAt)
    VALUES (@UserId, @DoctorId, @Rating, @Comments, GETDATE());

    PRINT 'Feedback submitted successfully.';
END;

---------------------------------------------------------------------------------
EXEC sp_rename 'uspViewUserDoctors', 'USP_ViewUserDoctors';

CREATE PROCEDURE USP_ViewUserDoctors
    @UserId INT
AS
BEGIN
    DECLARE @ExistingUserId INT;

    -- Check if UserId exists
    SELECT @ExistingUserId = UserId FROM Users WHERE UserId = @UserId;
    IF @ExistingUserId IS NULL
    BEGIN
        PRINT 'Error: User ID not found.';
        RETURN;
    END

    -- Retrieve doctors associated with the user's appointments
    SELECT DISTINCT d.DoctorId, u.Name AS DoctorName, d.Speciality, d.Location, a.AppointmentDate, a.AppointmentTime, a.Status
    FROM Appointment a
    JOIN DoctorAvailability da ON a.AvailabilityId = da.AvailabilityId
    JOIN Doctors d ON da.DoctorId = d.DoctorId
    JOIN Users u ON d.UserId = u.UserId
    WHERE a.UserId = @UserId
    ORDER BY a.AppointmentDate DESC, a.AppointmentTime;
END;



EXEC USP_ViewUserDoctors @UserId = 15;


EXEC USP_AddFeedback @UserId = 15, @DoctorId = 2, @Rating = 5 , @Comments = 'Excellent service!';
