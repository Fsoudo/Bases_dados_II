/* ==========================================================================
   maintenance.sql (Versão Local - 1 Disco)
   - Simulação de Backups (Full, Diff, Log)
   - Manutenção de Índices (Rebuild/Reorganize)
   ========================================================================== */
USE AluguerHab;
GO

DECLARE @BackupPath NVARCHAR(260) = N'C:\SQL_Projeto\Backups';
DECLARE @DataStr NVARCHAR(20) = FORMAT(GETDATE(), 'yyyyMMdd_HHmmss');
DECLARE @File NVARCHAR(500);

-- Criar pasta de backups se não existir (Requer xp_cmdshell, opcional, aqui assume-se que existe)
-- EXEC xp_cmdshell 'mkdir C:\SQL_Projeto\Backups';

PRINT '=== INÍCIO DA MANUTENÇÃO (LOCAL) ===';

-- 1. BACKUP FULL (Semanal/Diário)
SET @File = @BackupPath + '\AluguerHab_FULL_' + @DataStr + '.bak';
BACKUP DATABASE AluguerHab 
TO DISK = @File 
WITH FORMAT, COMPRESSION, NAME = 'AluguerHab-Full Database Backup', STATS = 10;
PRINT '>> Backup FULL concluído: ' + @File;

-- 2. BACKUP DIFERENCIAL (Diário/6h)
SET @DataStr = FORMAT(GETDATE(), 'yyyyMMdd_HHmmss'); -- atualizar timestamp
SET @File = @BackupPath + '\AluguerHab_DIFF_' + @DataStr + '.diff';
BACKUP DATABASE AluguerHab 
TO DISK = @File 
WITH DIFFERENTIAL, COMPRESSION, NAME = 'AluguerHab-Differential Database Backup', STATS = 10;
PRINT '>> Backup DIFF concluído: ' + @File;

-- 3. BACKUP LOG (Horário)
SET @DataStr = FORMAT(GETDATE(), 'yyyyMMdd_HHmmss');
SET @File = @BackupPath + '\AluguerHab_LOG_' + @DataStr + '.trn';
BACKUP LOG AluguerHab 
TO DISK = @File 
WITH COMPRESSION, NAME = 'AluguerHab-Log Backup', STATS = 10;
PRINT '>> Backup LOG concluído: ' + @File;

-- 4. MANUTENÇÃO DE ÍNDICES (Simples: Rebuild em todas as tabelas do schema 'core')
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
    -- Em produção real, verificaríamos a fragmentação. Aqui forçamos REBUILD.
    SET @Cmd = 'ALTER INDEX ALL ON ' + @Tabela + ' REBUILD;';
    EXEC(@Cmd);
    FETCH NEXT FROM CurIndice INTO @Tabela;
END

CLOSE CurIndice;
DEALLOCATE CurIndice;

PRINT '>> Manutenção de índices concluída.';
PRINT '=== FIM DA MANUTENÇÃO ===';
GO
