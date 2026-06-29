USE [AssetInventory]
GO

/****** Object:  StoredProcedure [dbo].[sp_InsertAsset]    Script Date: 6/29/2026 6:51:15 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE [dbo].[sp_InsertAsset]
    @AssetCode         VARCHAR(50),
    @SerialNumber      VARCHAR(50),
    @CategoryId        INT,
    @ModelId           INT,
    @OwnershipTypeId   INT,
    @StatusId          INT,
    @CurrentLocationId INT,
    @SupplierId        INT  = NULL,
    @AssignedTo        INT  = NULL,
    @MaintainedBy      INT  = NULL,
    @PurchaseDate      DATE = NULL,
    @RentalStartDate   DATE = NULL,
    @RentalEndDate     DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    /* Resolve rule-relevant ids by NAME (avoids hard-coded numbers) */
    DECLARE @LeasedId   INT = (SELECT Id FROM dbo.OwnershipTypes WHERE Name = 'Leased');
    DECLARE @StAssigned INT = (SELECT Id FROM dbo.Statuses       WHERE Name = 'Assigned');
    DECLARE @StMaint    INT = (SELECT Id FROM dbo.Statuses       WHERE Name = 'Maintenance');
    DECLARE @StRetired  INT = (SELECT Id FROM dbo.Statuses       WHERE Name = 'Retired');

    DECLARE @IsLeased  BIT = CASE WHEN @OwnershipTypeId = @LeasedId  THEN 1 ELSE 0 END;
    DECLARE @IsRetired BIT = CASE WHEN @StatusId        = @StRetired THEN 1 ELSE 0 END;

    /* ---- Friendly duplicate guards ---- */
    IF EXISTS (SELECT 1 FROM dbo.Assets WHERE AssetCode = @AssetCode)
        THROW 50010, 'AssetCode already exists.', 1;
    IF EXISTS (SELECT 1 FROM dbo.Assets WHERE SerialNumber = @SerialNumber)
        THROW 50011, 'SerialNumber already exists.', 1;

    /* ===================== BUSINESS RULES ===================== */
    IF @IsLeased = 1
    BEGIN
        -- R1
        IF @RentalStartDate IS NULL OR @RentalEndDate IS NULL
            THROW 50001, 'R1: A leased asset requires RentalStartDate and RentalEndDate.', 1;
        IF @RentalEndDate < @RentalStartDate
            THROW 50002, 'RentalEndDate cannot be earlier than RentalStartDate.', 1;
        IF @SupplierId IS NULL
            THROW 50003, 'A leased asset requires a SupplierId (its lessor).', 1;
        SET @PurchaseDate = NULL;            -- leased assets are not purchased
    END
    ELSE
    BEGIN
        -- R2
        IF @PurchaseDate IS NULL
            THROW 50004, 'R2: An owned asset requires PurchaseDate.', 1;
        SET @RentalStartDate = NULL;         -- owned assets have no rental dates
        SET @RentalEndDate   = NULL;
    END

    -- R5
    IF @StatusId = @StAssigned AND @AssignedTo IS NULL
        THROW 50005, 'R5: An assigned asset requires AssignedTo.', 1;

    -- R3
    IF @StatusId = @StMaint AND @AssignedTo IS NULL
        THROW 50006, 'R3: An asset in maintenance requires AssignedTo.', 1;

    -- R4 / R6 (derived automatically)
    IF @IsRetired = 1
        SET @MaintainedBy = NULL;            -- R4: retired keeps no maintainer
    ELSE IF @IsLeased = 1
        SET @MaintainedBy = @SupplierId;     -- R6: leased is maintained by its supplier

    /* ===================== INSERT ===================== */
    INSERT INTO dbo.Assets
        (AssetCode, SerialNumber, CategoryId, ModelId, OwnershipTypeId, SupplierId,
         StatusId, CurrentLocationId, AssignedTo, MaintainedBy,
         PurchaseDate, RentalStartDate, RentalEndDate)
    VALUES
        (@AssetCode, @SerialNumber, @CategoryId, @ModelId, @OwnershipTypeId, @SupplierId,
         @StatusId, @CurrentLocationId, @AssignedTo, @MaintainedBy,
         @PurchaseDate, @RentalStartDate, @RentalEndDate);

    DECLARE @NewId INT = SCOPE_IDENTITY();

    /* Return the inserted row with resolved names (section C shape) */
    SELECT
        a.Id, a.AssetCode, a.SerialNumber,
        c.Name  AS Category, b.Name AS Brand, m.Name AS Model,
        o.Name  AS Ownership, s.Name AS Status, ar.Name AS Location,
        CASE WHEN e.EmployeeId IS NULL THEN NULL
             ELSE CONCAT(e.FirstName, ' ', e.LastName) END AS AssignedTo,
        sup.Name AS Supplier, mnt.Name AS MaintainedBy,
        a.PurchaseDate, a.RentalStartDate, a.RentalEndDate, a.CreatedAt, a.UpdatedAt
    FROM dbo.Assets a
    JOIN dbo.Categories     c   ON c.Id   = a.CategoryId
    JOIN dbo.Models         m   ON m.Id   = a.ModelId
    JOIN dbo.Brands         b   ON b.Id   = m.BrandId
    JOIN dbo.OwnershipTypes o   ON o.Id   = a.OwnershipTypeId
    JOIN dbo.Statuses       s   ON s.Id   = a.StatusId
    JOIN dbo.CompanyAreas   ar  ON ar.Id  = a.CurrentLocationId
    LEFT JOIN dbo.Employees e   ON e.EmployeeId = a.AssignedTo
    LEFT JOIN dbo.Suppliers sup ON sup.Id = a.SupplierId
    LEFT JOIN dbo.Suppliers mnt ON mnt.Id = a.MaintainedBy
    WHERE a.Id = @NewId;
END
GO

