/**************************************************************
	SP Name			    : USP_USP_UpdateUser
	Purpose		        : Allows patients to update their profile and password.
	Created By          : Rahul Thipparthi
	Created On          : 07/03/25
	Modified By         : Rahul Thipparthi
	Modified ON         : 07/03/25
	Modified            : Initial creation of the procedure. 
****************************************************************/

CREATE PROCEDURE USP_UpdateUser
    @UserID INT,
    @Name NVARCHAR(20) = NULL,
    @Email NVARCHAR(30) = NULL,
    @GovID NVARCHAR(15) = NULL,
    @Contact NVARCHAR(15) = NULL,
    @OldPassword NVARCHAR(30) = NULL,
    @NewPassword NVARCHAR(30) = NULL,
    @Action NVARCHAR(15) = 'Both' -- Optional: 'UpdateProfile', 'ChangePassword', 'Both'
AS
BEGIN
    DECLARE @ExistingUserID_Email INT;
    DECLARE @ExistingUserID_GovID INT;
    DECLARE @UserExists INT;
    DECLARE @ExistingPassword NVARCHAR(30);

    -- Check if User Exists
    SELECT @UserExists = UserID FROM Users WHERE UserID = @UserID;
    IF @UserExists IS NULL
    BEGIN
        PRINT 'Error: User not found';
        RETURN;
    END

    -- Update Profile Only
    IF @Action = 'UpdateProfile' OR @Action = 'Both'
    BEGIN
        -- Ensure no field is empty
        IF @Name = '' OR @Email = '' OR @GovID = '' OR @Contact = ''
        BEGIN
            PRINT 'Error: Fields cannot be empty';
            RETURN;
        END

        -- Check for duplicate Email
        SELECT @ExistingUserID_Email = UserID FROM Users WHERE Email = @Email AND UserID <> @UserID;
        IF @ExistingUserID_Email IS NOT NULL
        BEGIN
            PRINT 'Error: Email already in use by another user';
            RETURN;
        END

        -- Check for duplicate GovID
        SELECT @ExistingUserID_GovID = UserID FROM Users WHERE GovID = @GovID AND UserID <> @UserID;
        IF @ExistingUserID_GovID IS NOT NULL
        BEGIN
            PRINT 'Error: GovID already in use by another user';
            RETURN;
        END

        -- Update Profile
        UPDATE Users
        SET Name = @Name,
            Email = @Email,
            GovID = @GovID,
            Contact = @Contact
        WHERE UserID = @UserID;

        PRINT 'User profile updated successfully';
    END

    -- Change Password Only
    IF @Action = 'ChangePassword' OR @Action = 'Both'
    BEGIN
        -- Check if passwords are provided
        IF @OldPassword IS NULL OR @NewPassword IS NULL OR @OldPassword = '' OR @NewPassword = ''
        BEGIN
            PRINT 'Error: Password fields cannot be empty';
            RETURN;
        END

        -- Fetch the existing password
        SELECT @ExistingPassword = Password FROM Users WHERE UserID = @UserID;

        -- Validate old password
        IF @ExistingPassword <> @OldPassword
        BEGIN
            PRINT 'Error: Incorrect old password';
            RETURN;
        END

        -- Update Password
        UPDATE Users
        SET Password = @NewPassword
        WHERE UserID = @UserID;

        PRINT 'Password changed successfully';
    END
END;


EXEC USP_UpdateUser 
    @UserID = 1, 
    @Name = 'Rahul Thipparthi', 
    @Email = 'rahul@example.com', 
    @GovID = 'A123456789', 
    @Contact = '9876543210',
    @Action = 'UpdateProfile';


	EXEC USP_UpdateUser 
    @UserID = 1, 
    @Name = 'Rahul Thipparthi', 
    @Email = 'rahul@example.com', 
    @GovID = 'A123456789', 
    @Contact = '9876543210',
    @OldPassword = 'oldPass123', 
    @NewPassword = 'newPass456',
    @Action = 'Both';


	EXEC USP_UpdateUser 
    @UserID = 1, 
    @OldPassword = 'oldPass123', 
    @NewPassword = 'newPass456',
    @Action = 'ChangePassword';
