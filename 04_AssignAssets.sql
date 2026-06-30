
/* ================================================================
   CALL usp_InsertAsset — one asset per business rule (R1..R6)
   Project: AssetInventory (SQL Server)

   Requires: Phase 2 (tables), catalog + employees seed, and
             Phase 5 (the procedure) already executed.

   NOTE: the procedure delivered in Phase 5 is dbo.usp_InsertAsset.
         If you created it as sp_InsertAsset, replace the name below.

   Catalog ids used (from the seed):
     OwnershipTypes : Owned=1, Leased=2
     Statuses       : Available=1, Assigned=2, Maintenance=3, Retired=4
     Suppliers      : CompuMundo=1, TechRent(Leasing)=2, Epson=3,
                      ServiTech=4, iStore=5
     Employees      : 1..8
   ================================================================ */

USE AssetInventory;
GO

/* ---- R1: Leased must have RentalStartDate + RentalEndDate ----
   Leased + Available; rental dates supplied (proc nulls PurchaseDate). */
EXEC dbo.sp_InsertAsset
     @AssetCode='AST-R1-LEASED-DATES', @SerialNumber='SN-R1-0001',
     @CategoryId=3, @ModelId=7, @OwnershipTypeId=2, @SupplierId=2,
     @StatusId=1, @CurrentLocationId=4,
     @RentalStartDate='2025-01-01', @RentalEndDate='2027-01-01';

/* ---- R2: Owned must have PurchaseDate ----
   Owned + Available; purchase date supplied (proc nulls rental dates). */
EXEC dbo.sp_InsertAsset
     @AssetCode='AST-R2-OWNED-PURCHASE', @SerialNumber='SN-R2-0001',
     @CategoryId=1, @ModelId=1, @OwnershipTypeId=1, @SupplierId=1,
     @StatusId=1, @CurrentLocationId=1,
     @PurchaseDate='2023-05-10';

/* ---- R3: Maintenance must have AssignedTo ----
   Owned + Maintenance; AssignedTo provided. */
EXEC dbo.sp_InsertAsset
     @AssetCode='AST-R3-MAINT-ASSIGNEE', @SerialNumber='SN-R3-0001',
     @CategoryId=1, @ModelId=5, @OwnershipTypeId=1, @SupplierId=1,
     @StatusId=3, @CurrentLocationId=1,
     @AssignedTo=1, @MaintainedBy=4, @PurchaseDate='2022-11-02';

/* ---- R4: Retired must NOT have MaintainedBy ----
   Retired; a MaintainedBy is passed on purpose -> proc forces it to NULL. */
EXEC dbo.sp_InsertAsset
     @AssetCode='AST-R4-RETIRED-NOMAINT', @SerialNumber='SN-R4-0001',
     @CategoryId=2, @ModelId=4, @OwnershipTypeId=1, @SupplierId=1,
     @StatusId=4, @CurrentLocationId=6,
     @MaintainedBy=4, @PurchaseDate='2020-05-30';

/* ---- R5: Assigned must have AssignedTo ----
   Owned + Assigned; AssignedTo provided. */
EXEC dbo.sp_InsertAsset
     @AssetCode='AST-R5-ASSIGNED', @SerialNumber='SN-R5-0001',
     @CategoryId=1, @ModelId=2, @OwnershipTypeId=1, @SupplierId=1,
     @StatusId=2, @CurrentLocationId=3,
     @AssignedTo=2, @PurchaseDate='2023-04-12';

/* ---- R6: Leased (not retired) maintained by its own provider ----
   Leased + Assigned; MaintainedBy is NOT passed -> proc sets it = SupplierId (2). */
EXEC dbo.sp_InsertAsset
     @AssetCode='AST-R6-LEASED-PROVIDER', @SerialNumber='SN-R6-0001',
     @CategoryId=3, @ModelId=6, @OwnershipTypeId=2, @SupplierId=2,
     @StatusId=2, @CurrentLocationId=4,
     @AssignedTo=3, @RentalStartDate='2024-02-18', @RentalEndDate='2026-02-18';
GO

/* ---- Result: show the 6 inserted assets with the rule effect ---- */
SELECT
    a.AssetCode,
    o.Name AS Ownership,
    s.Name AS Status,
    CASE WHEN e.EmployeeId IS NULL THEN NULL
         ELSE CONCAT(e.FirstName,' ',e.LastName) END AS AssignedTo,
    sup.Name AS Supplier,
    mnt.Name AS MaintainedBy,
    a.PurchaseDate, a.RentalStartDate, a.RentalEndDate
FROM dbo.Assets a
JOIN dbo.OwnershipTypes o   ON o.Id = a.OwnershipTypeId
JOIN dbo.Statuses       s   ON s.Id = a.StatusId
LEFT JOIN dbo.Employees e   ON e.EmployeeId = a.AssignedTo
LEFT JOIN dbo.Suppliers sup ON sup.Id = a.SupplierId
LEFT JOIN dbo.Suppliers mnt ON mnt.Id = a.MaintainedBy
WHERE a.AssetCode LIKE 'AST-R_-%'
ORDER BY a.AssetCode;
GO
