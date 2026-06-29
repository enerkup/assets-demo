USE [AssetInventory]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* ================================================================
   usp_AssignAsset — assigns an asset to an employee.
   Sets AssignedTo and moves the asset to status 'Assigned' (2).
   UpdatedAt is refreshed automatically by TR_Assets_UpdatedAt.

   Validations:
     - the asset must exist
     - the employee must exist
     - a Retired asset cannot be assigned
     - an asset already in 'Assigned' state cannot be re-assigned
       (no double assignment); release it first
   ================================================================ */
CREATE OR ALTER PROCEDURE dbo.sp_AssignAsset
    @AssetId    INT,
    @EmployeeId INT
AS
BEGIN 
    SET NOCOUNT ON;

    DECLARE @StatusId   INT,
            @AssignedTo INT;

    -- Asset exists? (StatusId stays NULL if no row was found)
    SELECT @StatusId   = StatusId,
           @AssignedTo = AssignedTo
    FROM dbo.Assets
    WHERE Id = @AssetId;

    IF @StatusId IS NULL
        THROW 50020, 'Asset not found.', 1;

    -- Employee exists?
    IF NOT EXISTS (SELECT 1 FROM dbo.Employees WHERE EmployeeId = @EmployeeId)
        THROW 50021, 'Employee not found.', 1;

    -- A retired asset is out of service and cannot be assigned.
    IF @StatusId = 4  -- Retired
        THROW 50022, 'Cannot assign a retired asset.', 1;

    -- No double assignment: the asset is already assigned.
    IF @StatusId = 2  -- Assigned
    BEGIN
        DECLARE @msg NVARCHAR(200) =
            CONCAT('Asset is already assigned (employee id ', @AssignedTo,
                   '). Release it before assigning it again.');
        THROW 50023, @msg, 1;
    END

    UPDATE dbo.Assets
       SET AssignedTo = @EmployeeId,
           StatusId   = 2            -- Assigned
     WHERE Id = @AssetId;

    -- Confirmation row
    SELECT
        a.Id,
        a.AssetCode,
        s.Name AS Status,
        CONCAT(e.FirstName, ' ', e.LastName) AS AssignedTo
    FROM dbo.Assets a
    JOIN dbo.Statuses  s ON s.Id = a.StatusId
    JOIN dbo.Employees e ON e.EmployeeId = a.AssignedTo
    WHERE a.Id = @AssetId;
END
GO
