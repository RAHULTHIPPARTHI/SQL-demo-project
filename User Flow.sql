/**************************************************************
    Script Name         : User_Flow_Simulation.sql
    Purpose             : Simulating a complete user journey in the system
    Created By          : Rahul Thipparthi
    Created On          : 07/03/25
    Modified By         : Rahul Thipparthi
    Modified On         : 07/03/25
    Modified            : Initial version
****************************************************************/

-- Step 1: Get all existing users (Optional - To check if the user already exists)
EXEC USP_GetAllUsers;

-- Step 2: Register a new user
EXEC USP_RegisterUser 
    @RoleID = 3, 
    @Name = 'Surya', 
    @Email = 'Surya@example.com', 
    @Password = 'Surya@123', 
    @GovID = 'GOV98762', 
    @Contact = '9876543212';

--EXEC USP_GetUserDetails; --Check User Registered
EXEC USP_GetUserDetails @UserID = 5;

-- Step 3: User logs in after registration

EXEC USP_UserLogin 
    @Email = 'Surya@example.com', 
    @Password = 'Surya@123';

-- Step 4: Check doctor availability before booking an appointment
EXEC USP_GetDoctorAvailability;

-- Step 5: Book an appointment (Assuming AvailabilityId = 2 is available)
EXEC USP_ManageAppointment 
    @Action = 'Book', 
    @UserId = 15, -- Assuming new UserId assigned is 4
    @AvailabilityId = 4;


-- Step 6: Verify if the appointment is successfully booked

EXEC USP_UserAppointments 
    @UserID = 15;

EXEC USP_GetDoctorAvailability; -- Check updated availability

-- Step 7: Doctor checks the appointment and adds a prescription (Assuming AppointmentId = 8)
EXEC USP_DoctorPatientAppointments  
    @DoctorId = 4,
    @UserId = 15;  

EXEC USP_GetAllMedicine;


DECLARE @MedList MedicineList;
INSERT INTO @MedList (MedicineId, Quantity, Dosage)
VALUES 
    (1, 1, '2 tablets per day'), 
    (3, 1, '1 tablet at night'); 

EXEC USP_AddPrescription 
    @AppointmentId = 15, 
    @Medicines = @MedList;

-- Step 8: Retrieve all medicines and prescriptions (To verify prescription details)
EXEC USP_GetAllMedicine;
EXEC USP_GetAllPrescriptions;
EXEC USP_GetAllPrescriptionDetails;

-- Step 9: User places an order for the prescribed medicines 

EXEC USP_GetUserPrescriptions @UserId =15 ; 


EXEC USP_PlaceOrder 
    @PrescriptionId = 10;

-- Step 10: User confirms payment for the order (Assuming OrderId = 3)

EXEC USP_GetOrderIdByPrescription @PrescriptionId = 10; --GET ORDERID 

EXEC USP_ConfirmPayment 
    @OrderId = 8;

-- Step 11: Verify if the order and payment are updated
EXEC USP_GetOrderIdByPrescription @PrescriptionId = 10; 
EXEC USP_GetOrderDetailsByOrderId @OrderId = 8;


-- Step 12: User checks doctors they have consulted
EXEC USP_ViewUserDoctors 
    @UserId = 15;

-- Step 13: User submits feedback for the doctor (Assuming DoctorId = )
EXEC USP_AddFeedback 
    @UserId = 15, 
    @DoctorId = 4, 
    @Rating = 5, 
    @Comments = 'Great consultation and guidance. Thank you!';

-- Final Step: Retrieve feedback to verify submission
EXEC USP_GetFeedbackByUserId @UserId = 15;

