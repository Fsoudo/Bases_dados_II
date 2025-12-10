/* ==================================================================================
   security_Advanced.sql — Versão Corrigida (Separação por GO)
   ================================================================================== */
USE AluguerHab;
GO

PRINT '=== 1. IMPLEMENTAÇÃO DE PAPÉIS (ROLES) E GRANTS ===';
GO

-- 1.1 Criar Roles (Se não existirem)
IF DATABASE_PRINCIPAL_ID('RoleAdmin') IS NULL CREATE ROLE RoleAdmin;
IF DATABASE_PRINCIPAL_ID('RoleAnfitriao') IS NULL CREATE ROLE RoleAnfitriao;
IF DATABASE_PRINCIPAL_ID('RoleCliente') IS NULL CREATE ROLE RoleCliente;
GO

-- 1.2 Definir Permissões
GRANT CONTROL ON SCHEMA::core TO RoleAdmin;
GRANT SELECT ON SCHEMA::core TO RoleAnfitriao;
GRANT EXECUTE ON OBJECT::core.SP_CheckDisponibilidade TO RoleAnfitriao;

GRANT SELECT ON core.Propriedade TO RoleCliente;
GRANT SELECT ON core.Foto TO RoleCliente;
GRANT SELECT ON core.PrecoEpoca TO RoleCliente;
GRANT EXECUTE ON OBJECT::core.SP_CriarReserva TO RoleCliente;
GRANT EXECUTE ON OBJECT::core.SP_RegistarPagamento TO RoleCliente;
GO

PRINT '>> Roles configuradas.';
GO


PRINT '=== 2. AUDITORIA (AUDITING) ===';
GO

-- 2.1 Criar Tabela de Log
IF OBJECT_ID(N'core.AuditLog') IS NULL
BEGIN
    CREATE TABLE core.AuditLog (
        LogId BIGINT IDENTITY(1,1) PRIMARY KEY,
        TabelaAfetada NVARCHAR(50),
        Acao NVARCHAR(10),
        UtilizadorSQL NVARCHAR(100),
        DataHora DATETIME2 DEFAULT SYSUTCDATETIME(),
        Detalhes NVARCHAR(MAX)
    );
END
GO

-- 2.2 Criar Trigger (TEM de ser o primeiro comando do batch, por isso o GO acima)
CREATE OR ALTER TRIGGER core.TRG_Audit_Reserva
ON core.Reserva
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO core.AuditLog (TabelaAfetada, Acao, UtilizadorSQL, Detalhes)
    SELECT 
        'Reserva',
        CASE WHEN EXISTS(SELECT * FROM inserted) THEN 'UPDATE' ELSE 'DELETE' END,
        USER_NAME(),
        CONCAT('ReservaId afetado: ', d.ReservaId, '. Estado Anterior: ', d.Estado)
    FROM deleted d;
END
GO

PRINT '>> Auditoria configurada.';
GO


PRINT '=== 3. CIFRA DE DADOS (COLUMN ENCRYPTION) ===';
GO

-- 3.1 Criar Master Key (se der erro a dizer que já existe, ignoramos)
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
BEGIN
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'PasswordForte@2025!';
END
GO

-- 3.2 Criar Certificado
IF NOT EXISTS (SELECT * FROM sys.certificates WHERE name = 'CertificadoAluguer')
BEGIN
    CREATE CERTIFICATE CertificadoAluguer WITH SUBJECT = 'Protecao de Dados Sensiveis';
END
GO

-- 3.3 Criar Chave Simétrica
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = 'ChaveSimetricaIBAN')
BEGIN
    CREATE SYMMETRIC KEY ChaveSimetricaIBAN
    WITH ALGORITHM = AES_256
    ENCRYPTION BY CERTIFICATE CertificadoAluguer;
END
GO

-- 3.4 Adicionar a Coluna (Passo Isolado)
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'core.Anfitriao') AND name = 'IBAN_Cifrado')
BEGIN
    ALTER TABLE core.Anfitriao ADD IBAN_Cifrado VARBINARY(MAX);
END
GO

-- 3.5 Encriptar os dados (Agora que a coluna JÁ EXISTE de certeza)
-- Abrir a chave
OPEN SYMMETRIC KEY ChaveSimetricaIBAN DECRYPTION BY CERTIFICATE CertificadoAluguer;
GO

-- Atualizar dados
UPDATE core.Anfitriao
SET IBAN_Cifrado = EncryptByKey(Key_GUID('ChaveSimetricaIBAN'), IBAN)
WHERE IBAN_Cifrado IS NULL; -- Só encripta quem ainda não tem
GO

-- Fechar a chave
CLOSE SYMMETRIC KEY ChaveSimetricaIBAN;
GO

PRINT '>> Encriptação concluída sem erros.';
PRINT '=== FIM DO SCRIPT ===';
GO