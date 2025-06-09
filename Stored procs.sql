CREATE PROCEDURE USP_GetAllMedicine
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT * FROM Medicine;
END;


CREATE PROCEDURE USP_GetAllPrescriptions
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT * FROM Prescription;
END;


CREATE PROCEDURE USP_GetAllPrescriptionDetails
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT * FROM PrescriptionDetails;
END;


CREATE PROCEDURE USP_GetUserOrders
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT o.OrderId, o.PrescriptionId, o.OrderDate, o.Status
    FROM Orders o
    JOIN Prescription p ON o.PrescriptionId = p.PrescriptionId
    JOIN Appointment a ON p.AppointmentId = a.AppointmentId
    WHERE a.UserId = @UserId
    
END;


ALTER PROCEDURE USP_GetOrderIdByPrescription
    @PrescriptionId INT
AS
BEGIN
    SELECT 
        OrderId,
        PrescriptionId,
        OrderDate,
        TotalAmount,
        PaymentStatus,
        CreatedAt
    FROM Orders
    WHERE PrescriptionId = @PrescriptionId;
END;


CREATE PROCEDURE USP_GetFeedbackByUserId
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if UserId exists
    IF NOT EXISTS (SELECT 1 FROM Users WHERE UserId = @UserId)
    BEGIN
        PRINT 'Error: User ID not found.';
        RETURN;
    END

    -- Retrieve feedback for the given UserId
    SELECT * 
    FROM Feedback 
    WHERE UserId = @UserId;
END;


CREATE PROCEDURE USP_GetOrderDetailsByOrderId
    @OrderId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if OrderId exists
    IF NOT EXISTS (SELECT 1 FROM Orders WHERE @OrderId = OrderId)
    BEGIN
        PRINT 'Error: Order ID not found.';
        RETURN;
    END

    -- Retrieve order details for the given OrderId
    SELECT * 
    FROM OrderDetails 
    WHERE OrderId = @OrderId;
END;
|
EXEC USP_GetOrderDetailsByOrderId @OrderId = 3;

---------------------------------------------------
SP_HELPTEXT  USP_UserAppointments 

 ALTER PROCEDURE USP_UserAppointments  
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
        A.UserId,  -- Added UserId column
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


-------------------------------------
ALTER PROCEDURE USP_DoctorPatientAppointments  
    @DoctorId INT,  
    @UserId INT = NULL  -- Optional parameter
AS  
BEGIN  
    -- Check if Doctor exists  
    IF NOT EXISTS (SELECT 1 FROM Doctors WHERE DoctorId = @DoctorId)  
    BEGIN  
        PRINT 'Error: Doctor ID not found';  
        RETURN;  
    END  

    -- Check if User exists (only if provided)
    IF @UserId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Users WHERE UserId = @UserId)  
    BEGIN  
        PRINT 'Error: User ID not found';  
        RETURN;  
    END  

    -- Retrieve Appointments (for all patients if @UserId is NULL, else for specific patient)
    SELECT  
        A.AppointmentId,  
        A.UserId AS PatientId,  
        U.Name AS PatientName,  
        A.AppointmentDate,  
        A.AppointmentTime,  
        A.Status AS AppointmentStatus  
    FROM Appointment A  
    INNER JOIN Users U ON A.UserId = U.UserId  
    INNER JOIN DoctorAvailability DA ON A.AvailabilityId = DA.AvailabilityId  
    WHERE DA.DoctorId = @DoctorId  
    AND (@UserId IS NULL OR A.UserId = @UserId);  -- Filters by UserId if provided
END;


---------------------------------------
sp_helptext  USP_GetAllUsers

  
Alter PROCEDURE USP_GetAllUsers  
AS  
BEGIN  
    SET NOCOUNT ON;  
      
    SELECT * FROM Users;  
END;  

CREATE PROCEDURE USP_GetUserDetails  
    @UserID INT  
AS  
BEGIN  
    SET NOCOUNT ON;  
      
    -- Check if the user exists
    IF NOT EXISTS (SELECT 1 FROM Users WHERE UserID = @UserID)
    BEGIN
        PRINT 'User ID not found';
        RETURN;
    END

    -- Return user details for the given UserID
    SELECT * FROM Users WHERE UserID = @UserID;  
END;


DROP USP_GetAllUsers