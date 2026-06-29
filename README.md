# Assets Demo — AssetInventory (SQL Server)

A demo SQL Server database for managing an **IT asset inventory**: monitors, printers and cellphones that are either *owned* or *leased*, assigned to employees, sent to maintenance, or retired. It includes the schema, seed data, business-rule enforcement, stored procedures and an audit log.

Repository: <https://github.com/enerkup/assets-demo>

---

## Requirements

- SQL Server 2016 SP1 or later (uses `CREATE OR ALTER`, `THROW`, `SYSUTCDATETIME`, filtered indexes).
- A client such as SQL Server Management Studio (SSMS) or Azure Data Studio.

No special configuration is needed; each script targets the right database with a `USE` statement.

---

## Project structure

| File | Purpose |
|------|---------|
| `01_database_creation.sql` | Creates (or recreates clean) the `AssetInventory` database. |
| `02_table_creation.sql` | Creates all tables, the `UpdatedAt` trigger and helper indexes. |
| `03_value_insertion.sql` | Seeds catalogs + UserTypes + 6 employees + 20 demo assets. **Users is left empty on purpose.** |
| `04_query_verification.sql` | Row counts, asset listing and business-rule checks. |
| `05_stored_procedures.sql` | `usp_InsertAsset` — inserts an asset enforcing all rules. |
| `06_asset_history.sql` | `AssetHistory` audit table + trigger that logs assignment and status changes. |
| `catalogs_seed.sql` | Idempotent seed of catalogs **and** a few employees (safe to re-run). |
| `call_usp_InsertAsset_rules.sql` | One `usp_InsertAsset` call per business rule (R1–R6). |
| `usp_InsertUser.sql` | `sp_InsertUser` — inserts an auth user with validations. |
| `usp_AssignAsset.sql` | `usp_AssignAsset` — assigns an asset to an employee (no double assignment). |

---

## Quick start

Run the scripts in this order:

1. `01_database_creation.sql`
2. `02_table_creation.sql`
3. `06_asset_history.sql` *(create the audit trigger before seeding if you want the seed inserts logged)*
4. `03_value_insertion.sql` *(or `catalogs_seed.sql` for catalogs + employees only)*
5. `05_stored_procedures.sql`
6. `usp_InsertUser.sql`
7. `usp_AssignAsset.sql`
8. `04_query_verification.sql` *(optional — confirms data and rules)*
9. `call_usp_InsertAsset_rules.sql` *(optional — exercises each rule)*

> If you create `AssetHistory` (step 3) **after** seeding, the 20 seed assets won't appear in the history because they were inserted before the trigger existed. For a full audit trail, create the trigger first.

---

## Data model

**Lookup / catalog tables**

- `Categories` — Monitors, Printers, Cellphone
- `OwnershipTypes` — Owned, Leased
- `Statuses` — Available, Assigned, Maintenance, Retired
- `CompanyAreas` — IT, Human Resources, Finance, Sales, Executive, Support
- `UserTypes` — Administrator, Operator
- `SupplierTypes` — Manufacturer, Distributor, Leasing Company, Technical Service
- `Brands` and `Models` (each model belongs to a brand)
- `Suppliers` (each supplier has a supplier type)

**Identity and people**

- `Users` — **API authentication only** (`UNIQUEIDENTIFIER` PK, normalized email, password hash, lockout fields). Has a `UserTypeId` FK to `UserTypes`.
- `Employees` — business entity; the people an asset can be assigned to.

`Users` (credentials) and `Employees` (people) are intentionally **decoupled**: an administrator is a `Users` account with the Administrator role and is not necessarily an employee.

**Core and audit**

- `Assets` — the main table. References category, model, ownership type, supplier, status, location, the assigned employee (`AssignedTo → Employees`) and the maintainer (`MaintainedBy → Suppliers`).
- `AssetHistory` — audit log of assignment and status changes (populated automatically by a trigger).

---

## Business rules

The asset rules enforced by the demo data, the verification queries and `usp_InsertAsset`:

| # | Rule |
|---|------|
| R1 | **Leased** assets must have `RentalStartDate` and `RentalEndDate` (and no `PurchaseDate`). |
| R2 | **Owned** assets must have a `PurchaseDate` (and no rental dates). |
| R3 | Assets in **Maintenance** must have an `AssignedTo`. |
| R4 | **Retired** assets must not have a `MaintainedBy`. |
| R5 | **Assigned** assets must have an `AssignedTo`. |
| R6 | **Leased** assets that are not retired are maintained by their own provider (`MaintainedBy = SupplierId`). |

`04_query_verification.sql` reports each rule as `OK` or `FAIL` (a passing run shows 0 violations everywhere).

---

## Stored procedures

**`usp_InsertAsset`** — inserts an asset and applies R1–R6. It auto-clears dates that don't apply, requires an assignee for Assigned/Maintenance, nulls the maintainer for Retired, and sets the leased maintainer to its supplier.

**`usp_AssignAsset (@AssetId, @EmployeeId)`** — assigns an asset to an employee and moves it to `Assigned`. Validates that the asset and employee exist, refuses retired assets, and **prevents double assignment** (an already-assigned asset must be released first).

```sql
EXEC dbo.usp_AssignAsset @AssetId = 1, @EmployeeId = 2;
```

**`sp_InsertUser`** — inserts an authentication user. Validates that `@UserTypeId` exists in `UserTypes`, that the username is not taken, and that the email (by `NormalizedEmail`) is not taken; returns the new `UserId`.

```sql
DECLARE @id UNIQUEIDENTIFIER;
EXEC dbo.sp_InsertUser
     @UserTypeId=1, @Username='admin01',
     @Email='admin01@company.com', @NormalizedEmail='ADMIN01@COMPANY.COM',
     @PasswordHash='DEMO_HASH', @FirstName='Admin', @LastName='One',
     @NewUserId=@id OUTPUT;
```

---

## Audit / history

`AssetHistory` records one row per change, discriminated by `ChangeType`:

- `Assignment` — when `AssignedTo` changes (assign, reassign or release).
- `StatusChange` — when `StatusId` changes.

The `TR_Assets_History` trigger fills it automatically on every `INSERT`/`UPDATE`, regardless of whether the change came from a stored procedure, the application or a manual `UPDATE`. It is set-based, so bulk updates are logged correctly. The optional `ChangedByUserId` column can be populated from `SESSION_CONTEXT` if the application sets the current user on the connection.

---

## Notes

- Passwords in the seed are placeholders (`DEMO_HASH_PLACEHOLDER`), not real hashes.
- The seed scripts use fixed numeric ids so demo data lines up; in a real system you would let identities and `NEWSEQUENTIALID()` generate keys.
- `01_database_creation.sql` **drops** `AssetInventory` if it exists — do not run it against a server holding real data under that name.
- The `sp_` prefix on `sp_InsertUser` is kept for compatibility, but the `usp_` prefix is recommended for user procedures.