/* ==================================================================================
   maintenance_simulation.sql — Simulação de Jobs de Backup e Manutenção
   ================================================================================== */
USE master; -- Backups devem ser comandados de fora ou com contexto global
GO

DECLARE @BackupPath NVARCHAR(260) = N'C:\SQL_Projeto\Backups\'; -- Confirme se esta pasta existe!
DECLARE @DataAtual NVARCHAR(20) = FORMAT(GETDATE(), 'yyyyMMdd_HHmmss');
DECLARE @NomeFicheiro NVARCHAR(260);

PRINT '=== INÍCIO DA SIMULAÇÃO DE MANUTENÇÃO ===';

-- 1. BACKUP FULL (Normalmente semanal/diário)
-- Guarda TUDO. É a base de qualquer recuperação.
SET @NomeFicheiro = @BackupPath + N'AluguerHab_FULL_' + @DataAtual + N'.bak';

BACKUP DATABASE AluguerHab
TO DISK = @NomeFicheiro
WITH FORMAT,
     MEDIANAME = 'AluguerHab_Backup',
     NAME = 'Full Backup of AluguerHab';

PRINT '>> Backup FULL realizado com sucesso: ' + @NomeFicheiro;

-- Vamos simular que passou algum tempo e houve dados novos...
WAITFOR DELAY '00:00:02'; 

-- 2. BACKUP DIFERENCIAL (Normalmente diário/horário)
-- Guarda apenas o que mudou desde o último FULL. É mais rápido e pequeno.
SET @DataAtual = FORMAT(GETDATE(), 'yyyyMMdd_HHmmss'); -- Atualizar hora
SET @NomeFicheiro = @BackupPath + N'AluguerHab_DIFF_' + @DataAtual + N'.bak';

BACKUP DATABASE AluguerHab
TO DISK = @NomeFicheiro
WITH DIFFERENTIAL,
     NAME = 'Differential Backup of AluguerHab';

PRINT '>> Backup DIFERENCIAL realizado com sucesso: ' + @NomeFicheiro;

-- 3. BACKUP DE LOG (Normalmente a cada 15-30 min)
-- Guarda as transações individuais. Permite recuperar "até ao minuto exato".
SET @DataAtual = FORMAT(GETDATE(), 'yyyyMMdd_HHmmss');
SET @NomeFicheiro = @BackupPath + N'AluguerHab_LOG_' + @DataAtual + N'.trn';

BACKUP LOG AluguerHab
TO DISK = @NomeFicheiro
WITH NAME = 'Transaction Log Backup of AluguerHab';

PRINT '>> Backup de LOG realizado com sucesso: ' + @NomeFicheiro;

PRINT '';
PRINT '=== MANUTENÇÃO DE ÍNDICES ===';

USE AluguerHab;
GO

-- 4. REBUILD / REORGANIZE DE ÍNDICES
-- O enunciado pede manutenção para performance.
-- Este cursor percorre todas as tabelas e "arruma" os índices fragmentados.

DECLARE @Tabela NVARCHAR(256);
DECLARE @Cmd NVARCHAR(MAX);

DECLARE CurIndice CURSOR FOR
    SELECT TABLE_SCHEMA + '.' + TABLE_NAME
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE = 'BASE TABLE';

OPEN CurIndice;
FETCH NEXT FROM CurIndice INTO @Tabela;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Numa situação real, verificaríamos a % de fragmentação antes.
    -- Aqui, forçamos um REBUILD para garantir otimização total.
    SET @Cmd = 'ALTER INDEX ALL ON ' + @Tabela + ' REBUILD;';
    
    PRINT 'Otimizando tabela: ' + @Tabela;
    EXEC(@Cmd);

    FETCH NEXT FROM CurIndice INTO @Tabela;
END

CLOSE CurIndice;
DEALLOCATE CurIndice;

PRINT '>> Manutenção de índices concluída.';
PRINT '=== FIM DA SIMULAÇÃO ===';
GO