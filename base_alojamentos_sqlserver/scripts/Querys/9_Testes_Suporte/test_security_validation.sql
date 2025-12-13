/* ==================================================================================
   security_test_validation.sql — Validação Final da Segurança
   ================================================================================== */
USE AluguerHab;
GO

PRINT '=== 1. TESTE DE AUDITORIA (O "Polícia" está a funcionar?) ===';
PRINT 'Vou alterar uma reserva e ver se fica registado no Log...';

-- 1.1 Vamos buscar uma reserva qualquer para alterar (ou criar uma fictícia se não houver)
DECLARE @ReservaTesteId BIGINT = (SELECT TOP 1 ReservaId FROM core.Reserva);

IF @ReservaTesteId IS NOT NULL
BEGIN
    -- Alterar o estado da reserva (simular uma ação suspeita)
    UPDATE core.Reserva 
    SET Estado = 'CANCELADA' 
    WHERE ReservaId = @ReservaTesteId;
    
    PRINT 'Alteração feita na Reserva ID: ' + CAST(@ReservaTesteId AS NVARCHAR);

    -- 1.2 Verificar se o Trigger guardou no AuditLog
    PRINT '';
    PRINT '--- CONTEÚDO DA TABELA DE LOGS (Deve aparecer aqui a alteração) ---';
    SELECT LogId, Acao, UtilizadorSQL, DataHora, Detalhes 
    FROM core.AuditLog 
    ORDER BY LogId DESC;
END
ELSE
BEGIN
    PRINT 'AVISO: Não existem reservas para testar. Crie uma reserva primeiro.';
END
GO

PRINT '';
PRINT '=== 2. TESTE DE ENCRIPTAÇÃO (Os IBANs estão protegidos?) ===';
PRINT 'Vou tentar ler a tabela de Anfitriões...';

-- 2.1 Abrir a "Cofre" (Chave Simétrica) para conseguir ler
OPEN SYMMETRIC KEY ChaveSimetricaIBAN DECRYPTION BY CERTIFICATE CertificadoAluguer;

-- 2.2 Comparar o valor encriptado com