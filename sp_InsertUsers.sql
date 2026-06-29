USE [AssetInventory]
GO

/****** Object:  StoredProcedure [dbo].[sp_InsertUser]    Script Date: 6/29/2026 6:50:39 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE       PROCEDURE [dbo].[sp_InsertUser]
    @UserTypeId      INT,                      -- FK to dbo.UserTypes
    @Username        NVARCHAR(50),
    @Email           NVARCHAR(256),
    @NormalizedEmail NVARCHAR(256),
    @PasswordHash    NVARCHAR(256),
    @FirstName       NVARCHAR(100),
    @LastName        NVARCHAR(100),
    @NewUserId       UNIQUEIDENTIFIER OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate that the given UserTypeId exists in the catalog.
    IF NOT EXISTS (SELECT 1 FROM dbo.UserTypes WHERE Id = @UserTypeId)
        THROW 50010, 'Invalid UserTypeId: it does not exist.', 1;

    -- Validate that the username is not already taken.
    IF EXISTS (SELECT 1 FROM dbo.Users WHERE Username = @Username)
        THROW 50011, 'Username is already taken.', 1;

    -- Validate that the email is not already taken (compared by NormalizedEmail).
    IF EXISTS (SELECT 1 FROM dbo.Users WHERE NormalizedEmail = @NormalizedEmail)
        THROW 50012, 'Email is already taken.', 1;

    DECLARE @Inserted TABLE (UserId UNIQUEIDENTIFIER);

    INSERT INTO dbo.Users (
        UserTypeId,
        Username,
        Email,
        NormalizedEmail,
        PasswordHash,
        FirstName,
        LastName
    )
    OUTPUT INSERTED.UserId INTO @Inserted
    VALUES (
        @UserTypeId,
        @Username,
        @Email,
        @NormalizedEmail,
        @PasswordHash,
        @FirstName,
        @LastName
    );

    SELECT @NewUserId = UserId FROM @Inserted;
END
GO

