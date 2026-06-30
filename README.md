# Assets Demo — AssetInventory (SQL Server)

A demo SQL Server database for managing an **IT asset inventory** (monitors, printers, cellphones) that can be owned or leased, assigned to employees, sent to maintenance, or retired. The repository contains the database setup scripts, the API business logic (stored procedures), and a verification script for the business rules.

Repository: <https://github.com/enerkup/assets-demo>

---

## Setup scripts

Run these in order to build the database from scratch.

- **`01_database_creation.sql`** — Creates the `AssetInventory` database. Recreates it clean if it already exists.
- **`02_table_creation.sql`** — Creates all tables (catalogs, `Users`, `Employees`, `Brands`/`Models`, `Suppliers`, `Assets`), the `UpdatedAt` trigger, and helper indexes.
- **`03_catalogs_seed.sql`** — Idempotent seed for the catalog tables and a few demo employees. Uses `WHERE NOT EXISTS`, so it is safe to run more than once.
- **`04_AssignAssets.sql`** — Loads the demo assets and their assignments: sample records across the four statuses (Available, Assigned, Maintenance, Retired) and both ownership types (Owned, Leased), consistent with the business rules.
- **`05_AuditTable.sql`** — Creates the `AssetHistory` audit table and the trigger that automatically logs asset **assignment** and **status** changes.

---

## Business logic — API

Stored procedures that back the API operations.

- **`sp_GetAssets`** — Returns the asset list with resolved names (category, brand, model, ownership, status, location, assigned employee, supplier, maintainer).
- **`sp_InsertAsset`** — Inserts a new asset while enforcing the business rules (R1–R6); rejects invalid combinations and auto-fills derived fields.
- **`sp_GetUser.sql`** — Retrieves an authentication user (by id, username, or email).
- **`sp_InsertUsers.sql`** — Inserts an authentication user. Validates the `UserTypeId`, and that the username and email are not already taken; returns the new `UserId`.
- **`sp_AssignAsset`** — Assigns an asset to an employee and sets its status to *Assigned*. Validates that the asset and employee exist, rejects retired assets, and **prevents double assignment**.

---

## Business rules

| # | Rule |
|---|------|
| R1 | **Leased** assets must have `RentalStartDate` and `RentalEndDate` (no `PurchaseDate`). |
| R2 | **Owned** assets must have a `PurchaseDate` (no rental dates). |
| R3 | Assets in **Maintenance** must have an `AssignedTo`. |
| R4 | **Retired** assets must not have a `MaintainedBy`. |
| R5 | **Assigned** assets must have an `AssignedTo`. |
| R6 | **Leased** assets that are not retired are maintained by their own provider (`MaintainedBy = SupplierId`). |

---

## Verification

- **`query_verification.sql`** — Checks row counts per table and validates the basic business rules above, reporting each one as `OK` or `FAIL` (a healthy database shows zero violations).


---

## Security JWT

- for [loginAPI] and [CRUD] solutions "appsettings.json" contains the JWT key to simplify initial setup.

---

## Requirements

- SQL Server 2016 SP1 or later (uses `CREATE OR ALTER`, `THROW`, filtered indexes).
- SSMS or Azure Data Studio to run the scripts.

> Note: `01_database_creation.sql` drops `AssetInventory` if it exists — do not run it against a server holding real data under that name.

---

## PostMan-Assets.json

- 1 - Create Users [01-Register-Admin] and [02-Register-Operator]
- 2 - Generate a JWT token using Postman [Login-Generate-JWT-Admin]
- 3 - In Postman [GetAssets] Authorization -> Bearer Token 


## Checks:

- Código fuente. OK
- Scripts de base de datos. OK
- Stored Procedures. OK
- README con pasos de instalación. HALF
- Variables de entorno requeridas. Not required to simplify the setup
- Usuarios de prueba. - NO
- Colección de Postman o archivo equivalente, opcional pero recomendado. OK
- Pruebas automatizadas. NO
- Explicación de decisiones técnicas. NO
- Tiempo aproximado invertido. 2 Days
- Funcionalidades pendientes, en caso de existir. - Issue with permissions in the API Roles - Error management in API when a Asset is added to User
- El uso de herramientas de inteligencia artificial está permitido, sin embargo deberás indicar:
- Qué herramienta se utilizó. Copilot
- En qué parte del desarrollo se utilizó. SP, Some error solutions
- Qué validaciones realizaste sobre el código generado o sugerido. Small changes in DI
- Qué decisiones técnicas tomaste personalmente. Donde las validaciones necesitaban ser ejecutadas, estructura de la BD, Estructura API