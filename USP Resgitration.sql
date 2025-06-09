/**************************************************************
	SP Name			    : USP_RegisterUser
	Purpose		        : User Is Registering 
	Created By          : Mani kumar
	Created On          : 07/03/25
	Modified By         : Rahul Thipparthi
	Modified ON         : 07/03/25
	MOdified            : Modified the logic of Re-scheduling  and Added Erroe Handle for empty string  input and give userid as message after new registration
 
****************************************************************/

EXEC sp_rename 'spRegisterUser', 'USP_RegisterUser';

/* USERREGISTRATION*/

CREATE PROCEDURE USP_RegisterUser
    @RoleID INT,
    @Name NVARCHAR(25),
    @Email NVARCHAR(25),
    @Password NVARCHAR(15),
    @GovID NVARCHAR(15),
    @Contact NVARCHAR(10)
AS
BEGIN
    DECLARE @RoleIDCheck INT;
    DECLARE @EmailCheck NVARCHAR(25);
    DECLARE @GovIDCheck NVARCHAR(15);
    DECLARE @ErrorMessage NVARCHAR(100);
    DECLARE @ProcedureName NVARCHAR(30) = OBJECT_NAME(@@PROCID);
	DECLARE @NewUserID INT;

    -- Step 1: Ensure Name is NOT NULL or empty
    IF @Name IS NULL OR LTRIM(RTRIM(@Name)) = ''
    BEGIN
        SET @ErrorMessage = 'Name cannot be NULL or empty';
        INSERT INTO ErrorLog (ErrorMessage, ErrorDateTime, ProcedureName)
        VALUES (@ErrorMessage, GETDATE(), @ProcedureName);
        PRINT @ErrorMessage;
        RETURN;
    END

    -- Step 2: Ensure Email is NOT NULL or empty
    IF @Email IS NULL OR LTRIM(RTRIM(@Email)) = ''
    BEGIN
        SET @ErrorMessage = 'Email cannot be NULL or empty';
        INSERT INTO ErrorLog (ErrorMessage, ErrorDateTime, ProcedureName)
        VALUES (@ErrorMessage, GETDATE(), @ProcedureName);
        PRINT @ErrorMessage;
        RETURN;
    END

    -- Step 3: Ensure Password is NOT NULL or empty
    IF @Password IS NULL OR LTRIM(RTRIM(@Password)) = ''
    BEGIN
        SET @ErrorMessage = 'Password cannot be NULL or empty';
        INSERT INTO ErrorLog (ErrorMessage, ErrorDateTime, ProcedureName)
        VALUES (@ErrorMessage, GETDATE(), @ProcedureName);
        PRINT @ErrorMessage;
        RETURN;
    END

    -- Step 4: Ensure GovID is NOT NULL or empty
    IF @GovID IS NULL OR LTRIM(RTRIM(@GovID)) = ''
    BEGIN
        SET @ErrorMessage = 'Government ID cannot be NULL or empty';
        INSERT INTO ErrorLog (ErrorMessage, ErrorDateTime, ProcedureName)
        VALUES (@ErrorMessage, GETDATE(), @ProcedureName);
        PRINT @ErrorMessage;
        RETURN;
    END

    -- Step 5: Ensure Contact is NOT NULL or empty and exactly 10 digits
    IF @Contact IS NULL OR LTRIM(RTRIM(@Contact)) = ''
    BEGIN
        SET @ErrorMessage = 'Contact number cannot be NULL or empty';
        INSERT INTO ErrorLog (ErrorMessage, ErrorDateTime, ProcedureName)
        VALUES (@ErrorMessage, GETDATE(), @ProcedureName);
        PRINT @ErrorMessage;
        RETURN;
    END

    IF LEN(@Contact) <> 10
    BEGIN
        SET @ErrorMessage = 'Contact number must be exactly 10 digits';
        INSERT INTO ErrorLog (ErrorMessage, ErrorDateTime, ProcedureName)
        VALUES (@ErrorMessage, GETDATE(), @ProcedureName);
        PRINT @ErrorMessage;
        RETURN;
    END

    -- Step 6: Check if RoleID exists
    SELECT @RoleIDCheck = RoleID FROM Roles WHERE RoleID = @RoleID;
    IF @RoleIDCheck IS NULL
    BEGIN
        SET @ErrorMessage = 'Role ID not found';
        INSERT INTO ErrorLog (ErrorMessage, ErrorDateTime, ProcedureName)
        VALUES (@ErrorMessage, GETDATE(), @ProcedureName);
        PRINT @ErrorMessage;
        RETURN;
    END

    -- Step 7: Check if Email already exists
    SELECT @EmailCheck = Email FROM Users WHERE Email = @Email;
    IF @EmailCheck IS NOT NULL
    BEGIN
        SET @ErrorMessage = 'Email already registered';
        INSERT INTO ErrorLog (ErrorMessage, ErrorDateTime, ProcedureName)
        VALUES (@ErrorMessage, GETDATE(), @ProcedureName);
        PRINT @ErrorMessage;
        RETURN;
    END

    -- Step 8: Check if Gov_ID already exists
    SELECT @GovIDCheck = GovID FROM Users WHERE GovID = @GovID;
    IF @GovIDCheck IS NOT NULL
    BEGIN
        SET @ErrorMessage = 'Government ID already registered';
        INSERT INTO ErrorLog (ErrorMessage, ErrorDateTime, ProcedureName)
        VALUES (@ErrorMessage, GETDATE(), @ProcedureName);
        PRINT @ErrorMessage;
        RETURN;
    END

    -- Step 9: Insert new user
    INSERT INTO Users (RoleID, Name, Email, Password, GovID, Contact)
    VALUES (@RoleID, @Name, @Email, @Password, @GovID, @Contact);

    PRINT 'User registered successfully';
END;




EXEC USP_RegisterUser 
    @RoleID = 3, 
    @Name = 'Rahul', 
    @Email = 'Rahul@example.com', 
    @Password = 'Rahul@123', 
    @GovID = 'GOV98761', 
    @Contact = '9876543211';


/**************************************************************
    Test Cases for USP_RegisterUser Stored Procedure
**************************************************************/

-- Test Case 01: Valid User Registration
EXEC USP_RegisterUser @RoleID = 3, @Name = '', @Email = '', 
                      @Password = '', @GovID = '', @Contact = '1234567870';

-- Expected Output: 'User registered successfully'
-- Verify Data in Users Table
SELECT * FROM Users WHERE Email = 'Rahul@example.com';

-----------------------------------------------------------

-- Test Case 02: Invalid RoleID (Non-existent)
EXEC USP_RegisterUser @RoleID = 0, @Name = 'Jane Doe', @Email = 'jane@example.com', 
                      @Password = 'pass456', @GovID = 'GOV12347', @Contact = '9876543210';

-- Expected Output: 'Role ID not found'
-- Verify Error Log
SELECT * FROM ErrorLog WHERE ErrorMessage = 'Role ID not found';

-----------------------------------------------------------

-- Test Case 03: Duplicate Email (Already Registered)
EXEC USP_RegisterUser @RoleID = 3, @Name = 'John Doe', @Email = 'Rahul@example.com', 
                      @Password = 'pass123', @GovID = 'GOV12348', @Contact = '1234567891';

-- Expected Output: 'Email already registered'
-- Verify Error Log
SELECT * FROM ErrorLog WHERE ErrorMessage = 'Email already registered';

-----------------------------------------------------------

-- Test Case 04: Duplicate GovID (Already Registered)
EXEC USP_RegisterUser @RoleID = 3, @Name = 'Jane Doe', @Email = 'Rahul@example.com', 
                      @Password = 'pass789', @GovID = 'GOV98761',, @Contact = '9876543210';

-- Expected Output: 'Government ID already registered'
-- Verify Error Log
SELECT * FROM ErrorLog WHERE ErrorMessage = 'Government ID already registered';

-----------------------------------------------------------

-- Test Case 05: Invalid Contact (Less than 10 digits)
EXEC USP_RegisterUser @RoleID = 3, @Name = 'Mike', @Email = 'mike@example.com', 
                      @Password = 'pass789', @GovID = 'GOV12350', @Contact = '12345';

-- Expected Output: 'Contact number must be exactly 10 digits'
-- Verify Error Log
SELECT * FROM ErrorLog WHERE ErrorMessage = 'Contact number must be exactly 10 digits';

-----------------------------------------------------------

-- Test Case 06: NULL GovID (Should Fail)
EXEC USP_RegisterUser @RoleID = 3, @Name = 'Sara', @Email = 'sara@example.com', 
                      @Password = 'pass321', @GovID = NULL, @Contact = '9876543210';

-- Expected Output: 'Government ID cannot be NULL'
-- Verify Error Log
SELECT * FROM ErrorLog WHERE ErrorMessage = 'Government ID cannot be NULL';

-----------------------------------------------------------

-- Test Case 07: NULL Email (Should Fail)
EXEC USP_RegisterUser @RoleID = 3, @Name = 'Alex', @Email = NULL, 
                      @Password = 'pass123', @GovID = 'GOV12351', @Contact = '9876543210';

-- Expected Output: 'Email cannot be NULL'
-- Verify Error Log
SELECT * FROM ErrorLog WHERE ErrorMessage = 'Email cannot be NULL';

-----------------------------------------------------------

-- Additional Checks
-- View all Users
SELECT * FROM Users;

-- View all Error Logs
SELECT * FROM ErrorLog;

