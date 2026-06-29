/* ================================================================
   CATALOG SEED — AssetInventory (SQL Server)
   Fills the lookup/catalog tables consumed by Assets, plus some
   demo Employees. Does NOT touch Users or Assets.

   Idempotent: every insert is guarded with WHERE NOT EXISTS, so it
   can be run multiple times without creating duplicates.
   Models and Suppliers resolve their FKs by name (not by fixed id).
   ================================================================ */

USE AssetInventory;
GO

/* ---------- Categories ---------- */
INSERT INTO dbo.Categories (Name)
SELECT v.Name
FROM (VALUES ('Monitors'),('Printers'),('Cellphone')) AS v(Name)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Categories c WHERE c.Name = v.Name);

/* ---------- OwnershipTypes ---------- */
INSERT INTO dbo.OwnershipTypes (Name)
SELECT v.Name
FROM (VALUES ('Owned'),('Leased')) AS v(Name)
WHERE NOT EXISTS (SELECT 1 FROM dbo.OwnershipTypes o WHERE o.Name = v.Name);

/* ---------- Statuses ---------- */
INSERT INTO dbo.Statuses (Name)
SELECT v.Name
FROM (VALUES ('Available'),('Assigned'),('Maintenance'),('Retired')) AS v(Name)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Statuses s WHERE s.Name = v.Name);

/* ---------- CompanyAreas ---------- */
INSERT INTO dbo.CompanyAreas (Name)
SELECT v.Name
FROM (VALUES ('IT'),('Human Resources'),('Finance'),
             ('Sales'),('Executive'),('Support')) AS v(Name)
WHERE NOT EXISTS (SELECT 1 FROM dbo.CompanyAreas a WHERE a.Name = v.Name);

/* ---------- UserTypes ---------- */
INSERT INTO dbo.UserTypes (Name)
SELECT v.Name
FROM (VALUES ('Administrator'),('Operator')) AS v(Name)
WHERE NOT EXISTS (SELECT 1 FROM dbo.UserTypes u WHERE u.Name = v.Name);

/* ---------- SupplierTypes ---------- */
INSERT INTO dbo.SupplierTypes (Name)
SELECT v.Name
FROM (VALUES ('Manufacturer'),('Distributor'),
             ('Leasing Company'),('Technical Service')) AS v(Name)
WHERE NOT EXISTS (SELECT 1 FROM dbo.SupplierTypes st WHERE st.Name = v.Name);

/* ---------- Brands ---------- */
INSERT INTO dbo.Brands (Name)
SELECT v.Name
FROM (VALUES ('Dell'),('HP'),('Samsung'),
             ('Apple'),('Lenovo'),('Epson')) AS v(Name)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Brands b WHERE b.Name = v.Name);
GO

/* ---------- Models (FK Brand resolved by name) ---------- */
INSERT INTO dbo.Models (BrandId, Name)
SELECT b.Id, v.ModelName
FROM (VALUES
        ('Dell',   'Dell P2419H'),
        ('Dell',   'Dell U2722D'),
        ('HP',     'HP LaserJet Pro M404'),
        ('HP',     'HP OfficeJet 9015'),
        ('Samsung','Samsung Odyssey G5'),
        ('Samsung','Samsung Galaxy S23'),
        ('Apple',  'iPhone 14'),
        ('Apple',  'iPhone 15'),
        ('Lenovo', 'Lenovo ThinkVision T24'),
        ('Epson',  'Epson EcoTank L3250')
     ) AS v(BrandName, ModelName)
JOIN dbo.Brands b ON b.Name = v.BrandName
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.Models m
    WHERE m.BrandId = b.Id AND m.Name = v.ModelName
);
GO

/* ---------- Suppliers (FK SupplierType resolved by name) ---------- */
INSERT INTO dbo.Suppliers (Name, SupplierTypeId)
SELECT v.Name, st.Id
FROM (VALUES
        ('CompuMundo Inc',        'Distributor'),
        ('TechRent Leasing',      'Leasing Company'),
        ('Epson Solutions',       'Manufacturer'),
        ('ServiTech Maintenance', 'Technical Service'),
        ('iStore Distribution',   'Distributor')
     ) AS v(Name, TypeName)
JOIN dbo.SupplierTypes st ON st.Name = v.TypeName
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.Suppliers s WHERE s.Name = v.Name
);
GO

/* ---------- Employees (demo people; keyed on EmployeeNumber) ---------- */
INSERT INTO dbo.Employees (EmployeeNumber, FirstName, LastName, Email, JobTitle)
SELECT v.EmployeeNumber, v.FirstName, v.LastName, v.Email, v.JobTitle
FROM (VALUES
        ('EMP-001','Ana','Lopez',       'ana.lopez@company.com',       'Systems Administrator'),
        ('EMP-002','Carlos','Ramirez',  'carlos.ramirez@company.com',  'Sales Executive'),
        ('EMP-003','Maria','Fernandez', 'maria.fernandez@company.com', 'Finance Analyst'),
        ('EMP-004','Jorge','Martinez',  'jorge.martinez@company.com',  'General Director'),
        ('EMP-005','Laura','Gomez',     'laura.gomez@company.com',     'Sales Executive'),
        ('EMP-006','Pedro','Sanchez',   'pedro.sanchez@company.com',   'Accountant'),
        ('EMP-007','Sofia','Torres',    'sofia.torres@company.com',    'HR Specialist'),
        ('EMP-008','Diego','Morales',   'diego.morales@company.com',   'Support Technician')
     ) AS v(EmployeeNumber, FirstName, LastName, Email, JobTitle)
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.Employees e WHERE e.EmployeeNumber = v.EmployeeNumber
);
GO

/* ---------- Quick check: row count per catalog ---------- */
SELECT 'Categories'    AS Catalog, COUNT(*) AS Rows FROM dbo.Categories
UNION ALL SELECT 'OwnershipTypes', COUNT(*) FROM dbo.OwnershipTypes
UNION ALL SELECT 'Statuses',       COUNT(*) FROM dbo.Statuses
UNION ALL SELECT 'CompanyAreas',   COUNT(*) FROM dbo.CompanyAreas
UNION ALL SELECT 'UserTypes',      COUNT(*) FROM dbo.UserTypes
UNION ALL SELECT 'SupplierTypes',  COUNT(*) FROM dbo.SupplierTypes
UNION ALL SELECT 'Brands',         COUNT(*) FROM dbo.Brands
UNION ALL SELECT 'Models',         COUNT(*) FROM dbo.Models
UNION ALL SELECT 'Suppliers',      COUNT(*) FROM dbo.Suppliers
UNION ALL SELECT 'Employees',      COUNT(*) FROM dbo.Employees;
GO

PRINT 'Catalog + employees seed complete.';
GO
