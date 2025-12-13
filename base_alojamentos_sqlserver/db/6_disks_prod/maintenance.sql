/* ==========================================================================
   maintenance.sql (Versão Produção - 6 Discos)
   - Backups para disco dedicado (I:\)
   - Manutenção de Índices
   ========================================================================== */
USE AluguerHab;
GO

DECLARE @BackupPath NVARCHAR(260) = N'I:\SQLBackups'; -- Disco Dedicado de Backup
DECLARE @DataStr NVARCHAR(20) = FORMAT(GETDATE(), 'yyyyMMdd_HHmmss');
DECLARE @File NVARCHAR(500);

PRINT '=== INÍCIO DA MANUTENÇÃO (PRODUÇÃO) ===';

-- 1. BACKUP FULL (Diário - 00:00)
SET @File = @BackupPath + '\AluguerHab_FULL_' + @DataStr + '.bak';
BACKUP DATABASE AluguerHab 
TO DISK = @File 
WITH FORMAT, COMPRESSION, NAME = 'AluguerHab-Full Database Backup', STATS = 10;
PRINT '>> Backup FULL concluído: ' + @File;

-- 2. BACKUP DIFERENCIAL (A cada 4h)
SET @DataStr = FORMAT(GETDATE(), 'yyyyMMdd_HHmmss'); 
SET @File = @BackupPath + '\AluguerHab_DIFF_' + @DataStr + '.diff';
BACKUP DATABASE AluguerHab 
TO DISK = @File 
WITH DIFFERENTIAL, COMPRESSION, NAME = 'AluguerHab-Differential Database Backup', STATS = 10;
PRINT '>> Backup DIFF concluído: ' + @File;

-- 3. BACKUP LOG (A cada 15min)
SET @DataStr = FORMAT(GETDATE(), 'yyyyMMdd_HHmmss');
SET @File = @BackupPath + '\AluguerHab_LOG_' + @DataStr + '.trn';
BACKUP LOG AluguerHab 
TO DISK = @File 
WITH COMPRESSION, NAME = 'AluguerHab-Log Backup', STATS = 10;
PRINT '>> Backup LOG concluído: ' + @File;

-- 4. MANUTENÇÃO DE ÍNDICES
PRINT '>> A iniciar manutenção de índices...';

DECLARE @Tabela NVARCHAR(128);
DECLARE @Cmd NVARCHAR(MAX);

DECLARE CurIndice CURSOR FOR
    SELECT TABLE_SCHEMA + '.' + TABLE_NAME
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_SCHEMA = 'core';

OPEN CurIndice;
FETCH NEXT FROM CurIndice INTO @Tabela;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'Otimizando tabela: ' + @Tabela;
    -- Rebuild online se possível (Enterprise Edition), senão offline
    SET @Cmd = 'ALTER INDEX ALL ON ' + @Tabela + ' REBUILD WITH (ONLINE = OFF);';
    EXEC(@Cmd);
    FETCH NEXT FROM CurIndice INTO @Tabela;
END

CLOSE CurIndice;
DEALLOCATE CurIndice;

PRINT '>> Manutenção de índices concluída.';
PRINT '=== FIM DA MANUTENÇÃO ===';
GO
