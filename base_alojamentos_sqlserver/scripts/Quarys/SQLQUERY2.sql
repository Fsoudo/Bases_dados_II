/* ===============================
   init.sql — criação da BD com simulação de discos em pastas locais
   =============================== */
USE master;
GO

-- 1. DEFINIÇÃO DE CAMINHOS (Simulação dos discos)
-- Nota: Certifique-se que as pastas abaixo EXISTEM no disco C: antes de correr!
DECLARE @DATA NVARCHAR(260)   = N'C:\SQL_Projeto\Data';      -- Simula Disco de Dados
DECLARE @INDEX NVARCHAR(260)  = N'C:\SQL_Projeto\Index';     -- Simula Disco de Índices
DECLARE @LOG NVARCHAR(260)    = N'C:\SQL_Projeto\Log';       -- Simula Disco de Log
DECLARE @BACKUP NVARCHAR(260) = N'C:\SQL_Projeto\Backups';   -- Simula Disco de Backups

-- Verifica se a BD já existe e apaga-a para recomeçar do zero
IF DB_ID(N'AluguerHab') IS NOT NULL
BEGIN
    ALTER DATABASE AluguerHab SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE AluguerHab;
END
GO

-- 2. CRIAÇÃO DA BASE DE DADOS E FILEGROUPS
-- Como estamos dentro de um bloco dinâmico, precisamos de redeclarar as variáveis ou concatenar direto.
-- Para simplificar, vou reinserir os caminhos aqui na string dinâmica.

DECLARE @PATH_DATA NVARCHAR(260)  = N'C:\SQL_Projeto\Data';
DECLARE @PATH_INDEX NVARCHAR(260) = N'C:\SQL_Projeto\Index';
DECLARE @PATH_LOG NVARCHAR(260)   = N'C:\SQL_Projeto\Log';

DECLARE @sql NVARCHAR(MAX) = N'
CREATE DATABASE AluguerHab
ON PRIMARY
(
    NAME = N''AluguerHab_Primary'',
    FILENAME = ''' + @PATH_DATA + N'\AluguerHab_Primary.mdf'',
    SIZE = 200MB, FILEGROWTH = 50MB
),
FILEGROUP FG_DATA
(
    NAME = N''AluguerHab_Data1'',
    FILENAME = ''' + @PATH_DATA + N'\AluguerHab_Data1.ndf'',
    SIZE = 500MB, FILEGROWTH = 100MB
),
FILEGROUP FG_INDEX
(
    NAME = N''AluguerHab_Index1'',
    FILENAME = ''' + @PATH_INDEX + N'\AluguerHab_Index1.ndf'',
    SIZE = 300MB, FILEGROWTH = 100MB
)
LOG ON
(
    NAME = N''AluguerHab_Log'',
    FILENAME = ''' + @PATH_LOG + N'\AluguerHab_Log.ldf'',
    SIZE = 256MB, FILEGROWTH = 128MB
);';

EXEC(@sql);
GO

-- 3. DEFINIR O FILEGROUP PADRÃO
ALTER DATABASE AluguerHab MODIFY FILEGROUP FG_DATA DEFAULT;
GO

USE AluguerHab;
GO

-- 4. CONFIGURAÇÕES DE PERFORMANCE E COMPATIBILIDADE
ALTER DATABASE SCOPED CONFIGURATION SET QUERY_OPTIMIZER_HOTFIXES = ON;
ALTER DATABASE SCOPED CONFIGURATION SET LEGACY_CARDINALITY_ESTIMATION = OFF;
GO

-- 5. CRIAÇÃO DO SCHEMA OBRIGATÓRIO (para corrigir o erro que teve antes)
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'core')
BEGIN
    EXEC('CREATE SCHEMA core');
END
GO

-- 6. ATIVAR QUERY STORE (Para análise de performance)
ALTER DATABASE AluguerHab SET QUERY_STORE = ON;
ALTER DATABASE AluguerHab SET QUERY_STORE (OPERATION_MODE = READ_WRITE);
GO

PRINT 'Base de dados AluguerHab criada com sucesso em C:\SQL_Projeto!';