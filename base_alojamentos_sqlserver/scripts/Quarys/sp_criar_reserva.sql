/* ==========================================================================
   sp_criar_reserva.sql — Cria uma reserva validando disponibilidade e preço
   ========================================================================== */
USE AluguerHab;
GO

IF OBJECT_ID(N'core.SP_CriarReserva', N'P') IS NOT NULL
    DROP PROCEDURE core.SP_CriarReserva;
GO

CREATE PROCEDURE core.SP_CriarReserva
    @PropriedadeId INT,
    @ClienteId INT,
    @CheckIn DATE,
    @CheckOut DATE,
    @ReservaId BIGINT OUTPUT -- Devolve o ID da reserva criada
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Validações Básicas
    IF @CheckIn >= @CheckOut
    BEGIN
        RAISERROR('Data de Check-in deve ser anterior ao Check-out.', 16, 1);
        RETURN;
    END

    -- 2. Verificar Disponibilidade (Usa a SP que já testámos!)
    DECLARE @Disponivel BIT;
    DECLARE @TabelaCheck TABLE (IsLivre BIT);

    INSERT INTO @TabelaCheck
    EXEC core.SP_CheckDisponibilidade @PropriedadeId, @CheckIn, @CheckOut;

    SELECT @Disponivel = IsLivre FROM @TabelaCheck;

    IF @Disponivel = 0
    BEGIN
        RAISERROR('A propriedade não está disponível para estas datas.', 16, 1);
        RETURN;
    END

    -- 3. Iniciar Transação (Tudo ou Nada)
    BEGIN TRANSACTION;

    BEGIN TRY
        -- 4. Calcular o Preço Total
        -- (Soma o preço de cada noite individualmente, pois pode apanhar épocas diferentes)
        DECLARE @PrecoTotal DECIMAL(12,2) = 0;
        
        -- Vamos usar uma CTE ou subquery para somar os dias
        ;WITH Datas AS (
            SELECT @CheckIn AS Dia
            UNION ALL
            SELECT DATEADD(DAY, 1, Dia)
            FROM Datas
            WHERE Dia < DATEADD(DAY, -1, @CheckOut)
        )
        SELECT @PrecoTotal = SUM(pe.PrecoNoite)
        FROM Datas d
        JOIN core.Epoca e ON d.Dia >= e.DataInicio AND d.Dia <= e.DataFim
        JOIN core.PrecoEpoca pe ON pe.EpocaId = e.EpocaId AND pe.PropriedadeId = @PropriedadeId
        OPTION (MAXRECURSION 365); -- Permite reservas até 1 ano

        -- Se não encontrou preço (ex: datas fora de época configurada), erro
        IF @PrecoTotal IS NULL OR @PrecoTotal = 0
        BEGIN
             RAISERROR('Não foi possível calcular o preço. Verifique se há épocas configuradas para estas datas.', 16, 1);
        END

        -- 5. Inserir a Reserva
        INSERT INTO core.Reserva (PropriedadeId, ClienteId, DataCheckIn, DataCheckOut, Estado, Total)
        VALUES (@PropriedadeId, @ClienteId, @CheckIn, @CheckOut, 'PENDENTE', @PrecoTotal);

        -- Guardar o ID gerado para devolver ao utilizador
        SET @ReservaId = SCOPE_IDENTITY();

        -- Confirma a transação
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Se algo correu mal, desfaz tudo
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Relança o erro original para sabermos o que foi
        DECLARE @Msg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@Msg, 16, 1);
    END CATCH
END
GO