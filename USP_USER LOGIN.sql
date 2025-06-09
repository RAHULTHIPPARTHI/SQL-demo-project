/**************************************************************
	SP Name			    : USP_UserLogin
	Purpose		        : Authenticates users by verifying email and password
	Created By          : Rahul Thipparthi
	Created On          : 07/03/25
	Modified By         : Rahul Thipparthi
	Modified ON         : 12/03/25
	Modified            : Added a feature for error handle that email and password cannot be empty.
****************************************************************/


EXEC sp_rename 'spUserLogin', 'USP_UserLogin';



CREATE PROCEDURE USP_UserLogin
    @Email NVARCHAR(30),
    @Password NVARCHAR(30)
AS
BEGIN
    DECLARE @StoredPassword NVARCHAR(100);
    DECLARE @UserID INT;
    DECLARE @ErrorMessage NVARCHAR(50);
    DECLARE @ProcedureName NVARCHAR(30) = OBJECT_NAME(@@PROCID);

    -- Check if Email or Password is empty
    IF @Email = '' OR @Password = ''
    BEGIN
        SET @ErrorMessage = 'Email and Password cannot be empty';
        INSERT INTO ErrorLog (ErrorMessage, ErrorDateTime, ProcedureName) 
        VALUES (@ErrorMessage, GETDATE(), @ProcedureName);
        PRINT @ErrorMessage;
        RETURN;
    END

    -- Check if Email exists
    SELECT @UserID = UserID, @StoredPassword = Password FROM Users WHERE @Email = Email;
    
    IF @UserID IS NULL
    BEGIN
        SET @ErrorMessage = 'Email not registered';
        INSERT INTO ErrorLog (ErrorMessage, ErrorDateTime, ProcedureName) 
        VALUES (@ErrorMessage, GETDATE(), @ProcedureName);
        PRINT @ErrorMessage;
        RETURN;
    END

    -- Validate Password
    IF @StoredPassword IS NULL OR @StoredPassword <> @Password
    BEGIN
        SET @ErrorMessage = 'Incorrect Password';
        INSERT INTO ErrorLog (ErrorMessage, ErrorDateTime, ProcedureName) 
        VALUES (@ErrorMessage, GETDATE(), @ProcedureName);
        PRINT @ErrorMessage;
        RETURN;
    END

    PRINT 'Login Successful';
END;



/**************************************************************
Test Cases for USP_UserLogin

**************************************************************/

-- Test Case 1: Valid Login Credentials
EXEC USP_UserLogin @Email = 'Rahul@example.com', @Password = 'Rahul@123';
-- Expected Output: 'Login Successful'

-- Test Case 2: Email Not Registered
EXEC USP_UserLogin @Email = 'unknown@example.com', @Password = 'Rahul@123';
-- Expected Output: 'Email not registered'

-- Test Case 3: Incorrect Password
EXEC USP_UserLogin @Email = 'Rahul@example.com', @Password = 'WrongPass123';
-- Expected Output: 'Incorrect Password'

-- Test Case 4: NULL Email Input
EXEC USP_UserLogin @Email = NULL, @Password = 'Rahul@123';
-- Expected Output: 'Email not registered'

-- Test Case 5: NULL Password Input
EXEC USP_UserLogin @Email = 'Rahul@example.com', @Password = NULL;
-- Expected Output: 'Incorrect Password'

-- Test Case 6: Empty String Email Input
EXEC USP_UserLogin @Email = '    ', @Password = '    ';
-- Expected Output: 'Email not registered'

-- Test Case 7: Empty String Password Input
EXEC USP_UserLogin @Email = 'john@example.com', @Password = '';
-- Expected Output: 'Incorrect Password'


-- Additional Checks
-- View all Users
SELECT * FROM Users;