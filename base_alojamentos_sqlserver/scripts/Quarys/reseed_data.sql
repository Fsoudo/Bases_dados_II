/* ==================================================================================
   reseed_data.sql — Limpeza Total e Reinserção de Dados de Teste
   ================================================================================== */
USE AluguerHab;
GO

PRINT '=== 1. A LIMPAR DADOS ANTIGOS... ===';

-- Desligar verificação de chaves estrangeiras temporariamente para limpar rápido
EXEC sp_msforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT all';
GO

-- Limpar tabelas (Ordem não importa aqui porque desligámos as constraints)
DELETE FROM core.AuditLog; -- Tabela nova de auditoria
DELETE FROM core.Pagamento;
DELETE FROM core.Avaliacao;
DELETE FROM core.Reserva;
DELETE FROM core.CalendarioDisponibilidade;
DELETE FROM core.PrecoEpoca;
DELETE FROM core.PropriedadeComodidade;
DELETE FROM core.Foto;
DELETE FROM core.Propriedade;
DELETE FROM core.Anfitriao;
DELETE FROM core.Cliente;
DELETE FROM core.UtilizadorPapel;
DELETE FROM core.Utilizador;
DELETE FROM core.Localizacao;
DELETE FROM core.Epoca;
DELETE FROM core.Comodidade;
DELETE FROM core.Papel;

-- Voltar a ligar as constraints
EXEC sp_msforeachtable 'ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all';
GO

-- Reiniciar os contadores de ID (Identity) para começar do 1
DBCC CHECKIDENT ('core.Utilizador', RESEED, 0);
DBCC CHECKIDENT ('core.Propriedade', RESEED, 0);
DBCC CHECKIDENT ('core.Reserva', RESEED, 0);
-- (Outras tabelas conforme necessário)

PRINT '>> Base de dados limpa.';
GO


PRINT '=== 2. A CARREGAR DADOS DE TESTE (GITHUB/SEED) ===';

-- 2.1 Papéis
INSERT INTO core.Papel (Nome) VALUES ('ADMIN'), ('ANFITRIAO'), ('CLIENTE');

-- 2.2 Utilizadores
DECLARE @Hash VARBINARY(256) = HASHBYTES('SHA2_256', 'Mypassword123!');

INSERT INTO core.Utilizador (Email, HashSenha, Nome) VALUES 
('joao.host@email.com', @Hash, 'João Anfitrião'),
('maria.cliente@email.com', @Hash, 'Maria Cliente'),
('pedro.turista@email.com', @Hash, 'Pedro Turista'),
('carlos.intruso@email.com', @Hash, 'Carlos Intruso'); -- Para testar a segurança

-- Recuperar IDs
DECLARE @IdJoao INT = (SELECT UtilizadorId FROM core.Utilizador WHERE Email = 'joao.host@email.com');
DECLARE @IdMaria INT = (SELECT UtilizadorId FROM core.Utilizador WHERE Email = 'maria.cliente@email.com');
DECLARE @IdPedro INT = (SELECT UtilizadorId FROM core.Utilizador WHERE Email = 'pedro.turista@email.com');
DECLARE @IdCarlos INT = (SELECT UtilizadorId FROM core.Utilizador WHERE Email = 'carlos.intruso@email.com');

-- 2.3 Perfis (Anfitrião/Cliente)
-- João e Carlos são Anfitriões
INSERT INTO core.Anfitriao (UtilizadorId, IBAN) VALUES (@IdJoao, 'PT50000011112222333344445');
DECLARE @AnfJoaoId INT = (SELECT AnfitriaoId FROM core.Anfitriao WHERE UtilizadorId = @IdJoao);

INSERT INTO core.Anfitriao (UtilizadorId, IBAN) VALUES (@IdCarlos, 'PT50000000000000000000000');
DECLARE @AnfCarlosId INT = (SELECT AnfitriaoId FROM core.Anfitriao WHERE UtilizadorId = @IdCarlos);

-- Maria e Pedro são Clientes
INSERT INTO core.Cliente (UtilizadorId, DataNascimento, Pais) VALUES 
(@IdMaria, '1990-05-20', 'Portugal'),
(@IdPedro, '1985-11-15', 'Espanha');

DECLARE @CliMariaId INT = (SELECT ClienteId FROM core.Cliente WHERE UtilizadorId = @IdMaria);

-- Associar Papéis
INSERT INTO core.UtilizadorPapel (UtilizadorId, PapelId) VALUES 
(@IdJoao, (SELECT PapelId FROM core.Papel WHERE Nome = 'ANFITRIAO')),
(@IdCarlos, (SELECT PapelId FROM core.Papel WHERE Nome = 'ANFITRIAO')),
(@IdMaria, (SELECT PapelId FROM core.Papel WHERE Nome = 'CLIENTE')),
(@IdPedro, (SELECT PapelId FROM core.Papel WHERE Nome = 'CLIENTE'));

-- 2.4 Propriedades e Localização
INSERT INTO core.Localizacao (Pais, Cidade, Morada) VALUES ('Portugal', 'Lisboa', 'Chiado');
DECLARE @LocId INT = SCOPE_IDENTITY();

INSERT INTO core.Propriedade (AnfitriaoId, LocalizacaoId, Titulo, Descricao, Capacidade, RatingMedio) VALUES 
(@AnfJoaoId, @LocId, 'Apartamento T2 Chiado', 'Vista incrível', 4, 0),
(@AnfCarlosId, @LocId, 'Casa Proibida do Carlos', 'O João não vê isto', 2, 0);

DECLARE @PropId INT = (SELECT TOP 1 PropriedadeId FROM core.Propriedade WHERE AnfitriaoId = @AnfJoaoId);

-- 2.5 Preços e Épocas
INSERT INTO core.Epoca (Nome, DataInicio, DataFim) VALUES ('Ano 2025', '2025-01-01', '2025-12-31');
DECLARE @EpocaId INT = SCOPE_IDENTITY();
INSERT INTO core.PrecoEpoca (PropriedadeId, EpocaId, PrecoNoite) VALUES (@PropId, @EpocaId, 120.00);

-- 2.6 Calendário (365 dias)
DECLARE @DataInicial DATE = '2025-01-01';
DECLARE @i INT = 0;
WHILE @i < 365
BEGIN
    INSERT INTO core.CalendarioDisponibilidade (PropriedadeId, Dia, Ocupado)
    VALUES (@PropId, DATEADD(DAY, @i, @DataInicial), 0);
    SET @i = @i + 1;
END

-- 2.7 Reservas e Pagamentos
-- Reserva da Maria (Confirmada e Paga)
INSERT INTO core.Reserva (PropriedadeId, ClienteId, DataCheckIn, DataCheckOut, Estado, Total)
VALUES (@PropId, @CliMariaId, '2025-01-05', '2025-01-10', 'CONFIRMADA', 600.00);
DECLARE @ReservaId BIGINT = SCOPE_IDENTITY();

INSERT INTO core.Pagamento (ReservaId, Metodo, Valor, TransacaoRef)
VALUES (@ReservaId, 'MBWAY', 600.00, 'MB-123456');

-- Inserir Avaliação (Para testar o Trigger e os KPIs)
INSERT INTO core.Avaliacao (PropriedadeId, ClienteId, ReservaId, Rating, Comentario)
VALUES (@PropId, @CliMariaId, @ReservaId, 5, 'Excelente estadia!');

PRINT '>> Dados carregados.';
GO

PRINT '=== 3. APLICAR ENCRIPTAÇÃO AOS NOVOS DADOS ===';
-- Como apagámos e inserimos de novo, os IBANs estão em texto limpo.
-- Temos de correr a encriptação novamente para preencher a coluna IBAN_Cifrado.

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'core.Anfitriao') AND name = 'IBAN_Cifrado')
BEGIN
    OPEN SYMMETRIC KEY ChaveSimetricaIBAN DECRYPTION BY CERTIFICATE CertificadoAluguer;
    
    UPDATE core.Anfitriao
    SET IBAN_Cifrado = EncryptByKey(Key_GUID('ChaveSimetricaIBAN'), IBAN);
    
    CLOSE SYMMETRIC KEY ChaveSimetricaIBAN;
    PRINT '>> Encriptação reaplicada aos novos dados.';
END
GO

PRINT '=== RESET CONCLUÍDO COM SUCESSO ===';
