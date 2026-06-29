/* ================================================================
   PHASE 1 / 4 — DATABASE CREATION
   Project: AssetInventory (SQL Server)
   Run first. Recreates the database clean if it already exists.
   ================================================================ */

USE master;
GO

IF DB_ID('AssetInventory') IS NOT NULL
BEGIN
    ALTER DATABASE AssetInventory SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE AssetInventory;
END
GO

CREATE DATABASE AssetInventory;
GO

PRINT 'Phase 1 OK: database AssetInventory created.';
GO
