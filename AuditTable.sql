/* ================================================================
   ASSET HISTORY — audit log for Assets changes
   Project: AssetInventory (SQL Server)
   Run after Phase 2 (needs Assets, Employees, Statuses, Users).

   Captures two kinds of historical changes:
     - 'Assignment'   : AssignedTo changed (assign / reassign / release)
     - 'StatusChange' : StatusId changed
   The trigger logs every change automatically (set-based safe),
   including the initial values when an asset is created.
   ================================================================ */

USE AssetInventory;
GO

/* ---------- History table ---------- */
IF OBJECT_ID('dbo.AssetHistory', 'U') IS NOT NULL DROP TABLE dbo.AssetHistory;
GO

CREATE TABLE dbo.AssetHistory (
    HistoryId       BIGINT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_AssetHistory PRIMARY KEY,
    AssetId         INT NOT NULL,
    ChangeType      VARCHAR(30) NOT NULL,        -- 'Assignment' | 'StatusChange'
    OldEmployeeId   INT NULL,
    NewEmployeeId   INT NULL,
    OldStatusId     INT NULL,
    NewStatusId     INT NULL,
    ChangedByUserId UNIQUEIDENTIFIER NULL,       -- optional: who made the change (auth user)
    ChangedAtUtc    DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
    Notes           NVARCHAR(400) NULL,
    CONSTRAINT FK_AssetHistory_Asset     FOREIGN KEY (AssetId)        REFERENCES dbo.Assets(Id),
    CONSTRAINT FK_AssetHistory_OldEmp    FOREIGN KEY (OldEmployeeId)  REFERENCES dbo.Employees(EmployeeId),
    CONSTRAINT FK_AssetHistory_NewEmp    FOREIGN KEY (NewEmployeeId)  REFERENCES dbo.Employees(EmployeeId),
    CONSTRAINT FK_AssetHistory_OldStatus FOREIGN KEY (OldStatusId)    REFERENCES dbo.Statuses(Id),
    CONSTRAINT FK_AssetHistory_NewStatus FOREIGN KEY (NewStatusId)    REFERENCES dbo.Statuses(Id),
    CONSTRAINT FK_AssetHistory_User      FOREIGN KEY (ChangedByUserId) REFERENCES dbo.Users(UserId)
);
GO

CREATE INDEX IX_AssetHistory_AssetId ON dbo.AssetHistory(AssetId, ChangedAtUtc);
GO

/* ---------- Trigger: auto-log assignment and status changes ---------- */
CREATE OR ALTER TRIGGER dbo.TR_Assets_History
ON dbo.Assets
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Assignment changes (assign, reassign, or release -> NULL).
    -- On INSERT, deleted has no row, so an asset created already assigned
    -- is logged as a change from NULL to the new employee.
    INSERT INTO dbo.AssetHistory (AssetId, ChangeType, OldEmployeeId, NewEmployeeId)
    SELECT i.Id, 'Assignment', d.AssignedTo, i.AssignedTo
    FROM inserted i
    LEFT JOIN deleted d ON d.Id = i.Id
    WHERE ISNULL(d.AssignedTo, -1) <> ISNULL(i.AssignedTo, -1);

    -- Status changes (including the initial status set on INSERT).
    INSERT INTO dbo.AssetHistory (AssetId, ChangeType, OldStatusId, NewStatusId)
    SELECT i.Id, 'StatusChange', d.StatusId, i.StatusId
    FROM inserted i
    LEFT JOIN deleted d ON d.Id = i.Id
    WHERE ISNULL(d.StatusId, -1) <> ISNULL(i.StatusId, -1);
END
GO

PRINT 'AssetHistory table and TR_Assets_History trigger created.';
GO
