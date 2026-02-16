CREATE TABLE dbo.ExampleTable
(
    id               INT IDENTITY (1,1) PRIMARY KEY,
    is_deleted       BIT            NOT NULL DEFAULT 0,
    updated_at       DATETIME                DEFAULT GETUTCDATE(),
    created_at       DATETIME                DEFAULT GETUTCDATE()
)
GO
