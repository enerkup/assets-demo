/* ================================================================
   PHASE 2 / 4 — TABLE CREATION
   Project: AssetInventory (SQL Server)
   Run after Phase 1.

   Users     = API authentication (credentials) + UserTypeId (FK).
   UserTypes = catalog of account roles (Administrator, Operator).
   Employees = business entity (people who get assets assigned).
   Order: catalogs -> Users -> Employees -> brand/model -> Assets.
   ================================================================ */

USE AssetInventory;
GO

/* ---------- Simple catalogs ---------- */
CREATE TABLE dbo.Categories (
    Id   INT IDENTITY(1,1) PRIMARY KEY,
    Name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE dbo.OwnershipTypes (
    Id   INT IDENTITY(1,1) PRIMARY KEY,
    Name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE dbo.Statuses (
    Id   INT IDENTITY(1,1) PRIMARY KEY,
    Name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE dbo.CompanyAreas (
    Id   INT IDENTITY(1,1) PRIMARY KEY,
    Name VARCHAR(100) NOT NULL UNIQUE
);

/* ---------- UserTypes: account role catalog ---------- */
CREATE TABLE dbo.UserTypes (
    Id   INT IDENTITY(1,1) PRIMARY KEY,
    Name VARCHAR(50) NOT NULL UNIQUE
);
GO

/* ---------- Users: API authentication only ----------
   UserTypeId is a FK to UserTypes (Administrator / Operator). */
CREATE TABLE dbo.Users
(
    UserId UNIQUEIDENTIFIER NOT NULL
        CONSTRAINT PK_Users PRIMARY KEY CLUSTERED
        DEFAULT NEWSEQUENTIALID(),
    UserTypeId INT NOT NULL,
    Username NVARCHAR(50) NOT NULL
        CONSTRAINT UQ_Users_Username UNIQUE,
    Email NVARCHAR(256) NOT NULL,
    NormalizedEmail NVARCHAR(256) NOT NULL
        CONSTRAINT UQ_Users_NormalizedEmail UNIQUE,
    PasswordHash NVARCHAR(256) NOT NULL,
    SecurityStamp UNIQUEIDENTIFIER NOT NULL
        DEFAULT NEWID(),
    FirstName NVARCHAR(100) NULL,
    LastName NVARCHAR(100) NULL,
    IsActive BIT NOT NULL
        DEFAULT 1,
    AccessFailedCount INT NOT NULL
        DEFAULT 0,
    LockoutEndUtc DATETIME2(0) NULL,
    CreatedAtUtc DATETIME2(3) NOT NULL
        DEFAULT SYSUTCDATETIME(),
    UpdatedAtUtc DATETIME2(3) NULL,
    LastLoginUtc DATETIME2(3) NULL,
    CONSTRAINT FK_Users_UserType
        FOREIGN KEY (UserTypeId) REFERENCES dbo.UserTypes(Id),
    CONSTRAINT CK_Users_Email
        CHECK (Email LIKE '%_@_%._%')
);
GO

/* ---------- Employees: business entity consumed by other tables ---------- */
CREATE TABLE dbo.Employees (
    EmployeeId     INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_Employees PRIMARY KEY,
    EmployeeNumber VARCHAR(20) NOT NULL
        CONSTRAINT UQ_Employees_Number UNIQUE,
    FirstName      NVARCHAR(100) NOT NULL,
    LastName       NVARCHAR(100) NOT NULL,
    Email          NVARCHAR(256) NULL,
    JobTitle       NVARCHAR(100) NULL,
    CreatedAtUtc   DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

/* ---------- Brand / Model ---------- */
CREATE TABLE dbo.Brands (
    Id   INT IDENTITY(1,1) PRIMARY KEY,
    Name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE dbo.Models (
    Id      INT IDENTITY(1,1) PRIMARY KEY,
    BrandId INT NOT NULL,
    Name    VARCHAR(80) NOT NULL,
    CONSTRAINT FK_Models_Brands FOREIGN KEY (BrandId) REFERENCES dbo.Brands(Id),
    CONSTRAINT UQ_Models_Brand_Name UNIQUE (BrandId, Name)
);
GO

/* ---------- Supplier / Supplier type ---------- */
CREATE TABLE dbo.SupplierTypes (
    Id   INT IDENTITY(1,1) PRIMARY KEY,
    Name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE dbo.Suppliers (
    Id             INT IDENTITY(1,1) PRIMARY KEY,
    Name           VARCHAR(120) NOT NULL,
    SupplierTypeId INT NOT NULL,
    CONSTRAINT FK_Suppliers_Types FOREIGN KEY (SupplierTypeId) REFERENCES dbo.SupplierTypes(Id)
);
GO

/* ---------- Main table: Assets ----------
   AssignedTo -> Employees(EmployeeId) (responsible person). */
CREATE TABLE dbo.Assets (
    Id                INT IDENTITY(1,1) PRIMARY KEY,
    AssetCode         VARCHAR(50) NOT NULL UNIQUE,
    SerialNumber      VARCHAR(50) NOT NULL UNIQUE,
    CategoryId        INT NOT NULL,
    ModelId           INT NOT NULL,
    OwnershipTypeId   INT NOT NULL,
    SupplierId        INT NULL,
    StatusId          INT NOT NULL,
    CurrentLocationId INT NOT NULL,
    AssignedTo        INT NULL,
    MaintainedBy      INT NULL,
    PurchaseDate      DATE NULL,
    RentalStartDate   DATE NULL,
    RentalEndDate     DATE NULL,
    CreatedAt         DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt         DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Assets_Category   FOREIGN KEY (CategoryId)        REFERENCES dbo.Categories(Id),
    CONSTRAINT FK_Assets_Model      FOREIGN KEY (ModelId)           REFERENCES dbo.Models(Id),
    CONSTRAINT FK_Assets_Ownership  FOREIGN KEY (OwnershipTypeId)   REFERENCES dbo.OwnershipTypes(Id),
    CONSTRAINT FK_Assets_Supplier   FOREIGN KEY (SupplierId)        REFERENCES dbo.Suppliers(Id),
    CONSTRAINT FK_Assets_Status     FOREIGN KEY (StatusId)          REFERENCES dbo.Statuses(Id),
    CONSTRAINT FK_Assets_Location   FOREIGN KEY (CurrentLocationId) REFERENCES dbo.CompanyAreas(Id),
    CONSTRAINT FK_Assets_AssignedTo FOREIGN KEY (AssignedTo)        REFERENCES dbo.Employees(EmployeeId),
    CONSTRAINT FK_Assets_MaintBy    FOREIGN KEY (MaintainedBy)      REFERENCES dbo.Suppliers(Id)
);
GO

/* ---------- Trigger: keep UpdatedAt fresh on every change ---------- */
CREATE TRIGGER dbo.TR_Assets_UpdatedAt
ON dbo.Assets
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE a SET UpdatedAt = SYSUTCDATETIME()
    FROM dbo.Assets a
    INNER JOIN inserted i ON a.Id = i.Id;
END
GO

/* ---------- Indexes for frequent lookups (optional for a demo) ---------- */
CREATE INDEX IX_Assets_StatusId   ON dbo.Assets(StatusId);
CREATE INDEX IX_Assets_CategoryId ON dbo.Assets(CategoryId);
CREATE INDEX IX_Assets_AssignedTo ON dbo.Assets(AssignedTo);
GO

PRINT 'Phase 2 OK: tables created (Users + UserTypes, Employees), trigger and indexes.';
GO
