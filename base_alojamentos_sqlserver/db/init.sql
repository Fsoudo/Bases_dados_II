
/* ===============================
   init.sql — criação da BD e layout em 6 discos (ajustar caminhos!)
   =============================== */
USE master;
GO

-- AJUSTA estes caminhos antes de correr:
DECLARE @DATA NVARCHAR(260) = N'E:\SQLData';       -- DATA (filegroup principal)
DECLARE @INDEX NVARCHAR(260) = N'F:\SQLIndex';     -- FILEGROUP de índices
DECLARE @LOG NVARCHAR(260)   = N'G:\SQLLog';       -- Log
DECLARE @BACKUP NVARCHAR(260)= N'I:\SQLBackups';   -- Backups (usado em jobs/RESTORE, não aqui)
-- Nota: tempdb deve estar em disco separado (H:) e configura-se a nível de instância (fora deste script).

IF DB_ID(N'AluguerHab') IS NOT NULL
BEGIN
    ALTER DATABASE AluguerHab SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE AluguerHab;
END
GO

DECLARE @sql NVARCHAR(MAX) = N'
CREATE DATABASE AluguerHab
ON PRIMARY
(
    NAME = N''AluguerHab_Primary'',
    FILENAME = ''' + @DATA + N'\AluguerHab_Primary.mdf'',
    SIZE = 200MB, FILEGROWTH = 50MB
),
FILEGROUP FG_DATA
(
    NAME = N''AluguerHab_Data1'',
    FILENAME = ''' + @DATA + N'\AluguerHab_Data1.ndf'',
    SIZE = 500MB, FILEGROWTH = 100MB
),
FILEGROUP FG_INDEX
(
    NAME = N''AluguerHab_Index1'',
    FILENAME = ''' + @INDEX + N'\AluguerHab_Index1.ndf'',
    SIZE = 300MB, FILEGROWTH = 100MB
)
LOG ON
(
    NAME = N''AluguerHab_Log'',
    FILENAME = ''' + @LOG + N'\AluguerHab_Log.ldf'',
    SIZE = 256MB, FILEGROWTH = 128MB
);';

EXEC(@sql);
GO

ALTER DATABASE AluguerHab MODIFY FILEGROUP FG_DATA DEFAULT;
GO

USE AluguerHab;
GO

ALTER DATABASE SCOPED CONFIGURATION SET QUERY_OPTIMIZER_HOTFIXES = ON;
ALTER DATABASE SCOPED CONFIGURATION SET LEGACY_CARDINALITY_ESTIMATION = OFF;
GO

CREATE SCHEMA core;
GO

ALTER DATABASE AluguerHab SET QUERY_STORE = ON;
ALTER DATABASE AluguerHab SET QUERY_STORE (OPERATION_MODE = READ_WRITE);
GO
