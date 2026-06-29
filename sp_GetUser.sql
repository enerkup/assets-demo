USE [AssetInventory]
GO

/****** Object:  StoredProcedure [dbo].[usp_GetUser]    Script Date: 6/29/2026 6:47:41 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE     PROCEDURE [dbo].[usp_GetUser]
    @NormalizedEmail NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (1)
        UserId,
        Username,
        Email,
        UserTypeId,
        NormalizedEmail,
        PasswordHash,
        IsActive
    FROM dbo.Users
    WHERE NormalizedEmail = @NormalizedEmail;
END
GO

