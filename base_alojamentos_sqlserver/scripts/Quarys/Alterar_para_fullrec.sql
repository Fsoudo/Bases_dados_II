USE master;
GO

-- Muda o modelo de recuperação para COMPLETO (Permite backups de Log)
ALTER DATABASE AluguerHab SET RECOVERY FULL;
GO

PRINT 'Base de dados alterada para FULL RECOVERY MODEL.';