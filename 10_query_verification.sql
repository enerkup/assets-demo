/* ================================================================
   PHASE 4 / 4 — VERIFICATION
   Project: AssetInventory (SQL Server)
   Run after Phase 3.
   Checks that (a) data is present and (b) the 6 rules hold.
   Note: Users is expected to be 0 (left empty on purpose).
   ================================================================ */

USE AssetInventory;
GO

/* ---------- A. Row count per table ---------- */
PRINT '--- A. Row count per table ---';
SELECT 'Categories'    AS TableName, COUNT(*) AS Rows FROM dbo.Categories
UNION ALL SELECT 'OwnershipTypes', COUNT(*) FROM dbo.OwnershipTypes
UNION ALL SELECT 'Statuses',       COUNT(*) FROM dbo.Statuses
UNION ALL SELECT 'CompanyAreas',   COUNT(*) FROM dbo.CompanyAreas
UNION ALL SELECT 'UserTypes',      COUNT(*) FROM dbo.UserTypes
UNION ALL SELECT 'Users',          COUNT(*) FROM dbo.Users
UNION ALL SELECT 'Employees',      COUNT(*) FROM dbo.Employees
UNION ALL SELECT 'Brands',         COUNT(*) FROM dbo.Brands
UNION ALL SELECT 'Models',         COUNT(*) FROM dbo.Models
UNION ALL SELECT 'SupplierTypes',  COUNT(*) FROM dbo.SupplierTypes
UNION ALL SELECT 'Suppliers',      COUNT(*) FROM dbo.Suppliers
UNION ALL SELECT 'Assets',         COUNT(*) FROM dbo.Assets;
GO

/* ---------- B. Assets per status (should be 5 each) ---------- */
PRINT '--- B. Assets per status ---';
SELECT s.Name AS Status, COUNT(*) AS Total
FROM dbo.Assets a
JOIN dbo.Statuses s ON s.Id = a.StatusId
GROUP BY s.Name
ORDER BY s.Name;
GO

/* ---------- C. Full asset listing with resolved names ----------
   AssignedTo = employee (FirstName + LastName) from dbo.Employees. */
PRINT '--- C. Asset listing ---';
SELECT
    a.AssetCode,
    c.Name  AS Category,
    b.Name  AS Brand,
    m.Name  AS Model,
    o.Name  AS Ownership,
    s.Name  AS Status,
    ar.Name AS Location,
    CASE WHEN e.EmployeeId IS NULL THEN NULL
         ELSE CONCAT(e.FirstName, ' ', e.LastName) END AS AssignedTo,
    sup.Name AS Supplier,
    mnt.Name AS MaintainedBy,
    a.PurchaseDate, a.RentalStartDate, a.RentalEndDate
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
ORDER BY a.StatusId, a.AssetCode;
GO

/* ---------- C2. Employees ---------- */
PRINT '--- C2. Employees ---';
SELECT
    e.EmployeeNumber,
    CONCAT(e.FirstName, ' ', e.LastName) AS Employee,
    e.JobTitle
FROM dbo.Employees e
ORDER BY e.EmployeeNumber;
GO

/* ---------- D. Business rule verification ----------
   Each rule counts its violations. Expected: all OK. */
PRINT '--- D. Business rules ---';
SELECT Rule_, Violations,
       CASE WHEN Violations = 0 THEN 'OK' ELSE 'FAIL' END AS Result
FROM (
    SELECT 'R1 Leased must have rental dates' AS Rule_, COUNT(*) AS Violations
    FROM dbo.Assets
    WHERE OwnershipTypeId = 2 AND (RentalStartDate IS NULL OR RentalEndDate IS NULL)

    UNION ALL
    SELECT 'R2 Owned must have purchase date', COUNT(*)
    FROM dbo.Assets
    WHERE OwnershipTypeId = 1 AND PurchaseDate IS NULL

    UNION ALL
    SELECT 'R3 Maintenance must have AssignedTo', COUNT(*)
    FROM dbo.Assets
    WHERE StatusId = 3 AND AssignedTo IS NULL

    UNION ALL
    SELECT 'R4 Retired must not have MaintainedBy', COUNT(*)
    FROM dbo.Assets
    WHERE StatusId = 4 AND MaintainedBy IS NOT NULL

    UNION ALL
    SELECT 'R5 Assigned must have AssignedTo', COUNT(*)
    FROM dbo.Assets
    WHERE StatusId = 2 AND AssignedTo IS NULL

    UNION ALL
    SELECT 'R6 Leased (not retired) maintained by its provider', COUNT(*)
    FROM dbo.Assets
    WHERE OwnershipTypeId = 2 AND StatusId <> 4
      AND (MaintainedBy IS NULL OR MaintainedBy <> SupplierId)
) t
ORDER BY Rule_;
GO
