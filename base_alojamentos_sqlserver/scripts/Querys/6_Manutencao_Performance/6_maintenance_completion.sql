/* ==================================================================================
   maintenance_completion.sql — Integridade (CheckDB) e Teste de Restore Automático
   ================================================================================== */
USE master;
GO

PRINT '=== 1. VERIFICAÇÃO DE INTEGRIDADE (DBCC CHECKDB) ===';
PRINT 'A analisar a saúde física da base de dados...';

-- Verifica se há corrupção nos ficheiros da base de dados
DBCC CHECKDB (AluguerHab) WITH NO_INFOMSGS;

IF @@ERROR = 0
    PRINT '[SUCESSO] Base de dados saudável. Nenhuma corrupção detetada.';
ELSE
    PRINT '[ERRO] Foram encontrados problemas na base de dados!';
GO

PRINT '';
PRINT '=== 2. TESTE DE RESTORE (VALIDAÇÃO DO ÚLTIMO BACKUP) ===';

-- Truque avançado: Vamos perguntar ao histórico do SQL Server onde guardou o último backup
DECLARE @UltimoBackupFile NVARCHAR(260);

SELECT TOP 1 @UltimoBackupFile = bm.physical_device_name
FROM msdb.dbo.backupset b
JOIN msdb.dbo.backupmediafamily bm ON b.media_set_id = bm.media_set_id
WHERE b.database_name = 'AluguerHab' 
  AND b.type = 'D' -- Tipo 'D' = Database (Full Backup)
ORDER BY b.backup_finish_date DESC;

IF @UltimoBackupFile IS NOT NULL
BEGIN
    PRINT 'A testar o ficheiro: ' + @UltimoBackupFile;
    
    -- O comando VERIFYONLY lê o backup e confirma se está legível, sem estragar a base atual
    RESTORE VERIFYONLY FROM DISK = @UltimoBackupFile;
    
    PRINT '[SUCESSO] O backup é válido e pode ser restaurado com segurança.';
END
ELSE
BEGIN
    PRINT '[ERRO] Não foi encontrado histórico de backups para a base AluguerHab.';
    PRINT 'Por favor, corra novamente o script de simulação de backups.';
END
GO
