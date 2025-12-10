/* =============================================================
   seed_data_test.sql — Inserção de Dados de Teste (Manual)
   ============================================================= */
USE AluguerHab;
GO

PRINT 'A iniciar inserção de dados de teste...';

-- 1. INSERIR PAPÉIS (Roles)
INSERT INTO core.Papel (Nome) VALUES ('ADMIN'), ('ANFITRIAO'), ('CLIENTE');

-- 2. INSERIR UTILIZADORES
-- Senha simulada (hash dummy)
DECLARE @Hash VARBINARY(256) = HASHBYTES('SHA2_256', 'Mypassword123!');

-- Anfitrião: João
INSERT INTO core.Utilizador (Email, HashSenha, Nome) VALUES ('joao.host@email.com', @Hash, 'João Anfitrião');
DECLARE @IdJoao INT = SCOPE_IDENTITY();

-- Cliente 1: Maria
INSERT INTO core.Utilizador (Email, HashSenha, Nome) VALUES ('maria.cliente@email.com', @Hash, 'Maria Cliente');
DECLARE @IdMaria INT = SCOPE_IDENTITY();

-- Cliente 2: Pedro
INSERT INTO core.Utilizador (Email, HashSenha, Nome) VALUES ('pedro.turista@email.com', @Hash, 'Pedro Turista');
DECLARE @IdPedro INT = SCOPE_IDENTITY();

-- 3. ASSOCIAR PAPÉIS E DETALHES
-- João é Anfitrião
INSERT INTO core.UtilizadorPapel (UtilizadorId, PapelId) 
SELECT @IdJoao, PapelId FROM core.Papel WHERE Nome = 'ANFITRIAO';

INSERT INTO core.Anfitriao (UtilizadorId, IBAN) VALUES (@IdJoao, 'PT50000011112222333344445');
DECLARE @AnfitriaoId INT = SCOPE_IDENTITY();

-- Maria é Cliente
INSERT INTO core.UtilizadorPapel (UtilizadorId, PapelId) 
SELECT @IdMaria, PapelId FROM core.Papel WHERE Nome = 'CLIENTE';

INSERT INTO core.Cliente (UtilizadorId, DataNascimento, Pais) VALUES (@IdMaria, '1990-05-20', 'Portugal');
DECLARE @ClienteMariaId INT = SCOPE_IDENTITY();

-- Pedro é Cliente
INSERT INTO core.UtilizadorPapel (UtilizadorId, PapelId) 
SELECT @IdPedro, PapelId FROM core.Papel WHERE Nome = 'CLIENTE';

INSERT INTO core.Cliente (UtilizadorId, DataNascimento, Pais) VALUES (@IdPedro, '1985-11-15', 'Espanha');

-- 4. CRIAR LOCALIZAÇÃO E PROPRIEDADE
INSERT INTO core.Localizacao (Pais, Cidade, Morada, Latitude, Longitude)
VALUES ('Portugal', 'Lisboa', 'Rua Garrett, Chiado', 38.710, -9.142);
DECLARE @LocId INT = SCOPE_IDENTITY();

INSERT INTO core.Propriedade (AnfitriaoId, LocalizacaoId, Titulo, Descricao, Capacidade, RatingMedio)
VALUES (@AnfitriaoId, @LocId, 'Apartamento T2 Chiado', 'Vista incrível sobre a cidade', 4, 0);
DECLARE @PropId INT = SCOPE_IDENTITY();

-- 5. DEFINIR PREÇOS E ÉPOCAS
INSERT INTO core.Epoca (Nome, DataInicio, DataFim) VALUES ('Ano 2025', '2025-01-01', '2025-12-31');
DECLARE @EpocaId INT = SCOPE_IDENTITY();

INSERT INTO core.PrecoEpoca (PropriedadeId, EpocaId, PrecoNoite) VALUES (@PropId, @EpocaId, 120.00);

-- 6. CRIAR CALENDÁRIO (365 dias para a propriedade)
-- Truque simples para gerar dias sequenciais em SQL
DECLARE @DataInicial DATE = '2025-01-01';
DECLARE @i INT = 0;

WHILE @i < 365
BEGIN
    INSERT INTO core.CalendarioDisponibilidade (PropriedadeId, Dia, Ocupado)
    VALUES (@PropId, DATEADD(DAY, @i, @DataInicial), 0);
    SET @i = @i + 1;
END

-- 7. CRIAR UMA RESERVA CONFIRMADA (OCUPAÇÃO)
-- A Maria reservou de 5 a 10 de Janeiro de 2025
INSERT INTO core.Reserva (PropriedadeId, ClienteId, DataCheckIn, DataCheckOut, Estado, Total)
VALUES (@PropId, @ClienteMariaId, '2025-01-05', '2025-01-10', 'CONFIRMADA', 600.00);

PRINT 'Dados de teste inseridos com sucesso!';
GO