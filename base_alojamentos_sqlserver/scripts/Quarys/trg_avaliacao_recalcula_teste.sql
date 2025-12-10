-- 1. Ver Rating atual da casa (Deve ser 0.00)
DECLARE @PropId INT = (SELECT TOP 1 PropriedadeId FROM core.Propriedade);
SELECT Titulo, RatingMedio FROM core.Propriedade WHERE PropriedadeId = @PropId;

-- 2. Inserir uma Avaliação de 5 estrelas
-- (Precisamos de uma ReservaId válida e confirmada para a chave estrangeira)
DECLARE @ReservaId BIGINT = (SELECT TOP 1 ReservaId FROM core.Reserva WHERE Estado = 'CONFIRMADA' AND PropriedadeId = @PropId);
DECLARE @ClienteId INT = (SELECT ClienteId FROM core.Reserva WHERE ReservaId = @ReservaId);

IF @ReservaId IS NOT NULL
BEGIN
    INSERT INTO core.Avaliacao (PropriedadeId, ClienteId, ReservaId, Rating, Comentario)
    VALUES (@PropId, @ClienteId, @ReservaId, 5, 'Adorei a estadia! Espetacular.');

    PRINT 'Avaliação inserida.';
END
ELSE
BEGIN
    PRINT 'ERRO: Precisa de ter uma reserva CONFIRMADA para testar isto. Use os passos anteriores.';
END

-- 3. Ver se o Rating mudou sozinho (Deve ser 5.00)
SELECT Titulo, RatingMedio FROM core.Propriedade WHERE PropriedadeId = @PropId;

-- 4. Teste extra: Inserir outra nota má (1 estrela) para ver se a média desce (para 3.00)
IF @ReservaId IS NOT NULL
BEGIN
    -- Vamos simular outra avaliação (truque rápido para teste, usando a mesma reserva só para validar a média)
    -- Num sistema real, seria outra reserva.
    INSERT INTO core.Avaliacao (PropriedadeId, ClienteId, ReservaId, Rating, Comentario)
    VALUES (@PropId, @ClienteId, @ReservaId, 1, 'Houve barulho.');

    PRINT 'Segunda avaliação inserida.';
END

-- 5. Resultado final (Deve ser a média entre 5 e 1, ou seja, 3.00)
SELECT Titulo, RatingMedio FROM core.Propriedade WHERE PropriedadeId = @PropId;