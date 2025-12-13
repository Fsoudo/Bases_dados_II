/* ==============================================================================
   sp_registar_pagamento.sql — Regista pagamento e confirma a reserva
   ============================================================================== */
USE AluguerHab;
GO

IF OBJECT_ID(N'core.SP_RegistarPagamento', N'P') IS NOT NULL
    DROP PROCEDURE core.SP_RegistarPagamento;
GO

CREATE PROCEDURE core.SP_RegistarPagamento
    @ReservaId BIGINT,
    @Metodo NVARCHAR(50),      -- Ex: 'MBWAY', 'CARTAO', 'PAYPAL'
    @TransacaoRef NVARCHAR(100), -- Ex: 'REF-123456789'
    @Valor DECIMAL(12,2)
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Validar se a reserva existe
    DECLARE @EstadoAtual NVARCHAR(30);
    DECLARE @TotalEsperado DECIMAL(12,2);

    SELECT @EstadoAtual = Estado, @TotalEsperado = Total
    FROM core.Reserva
    WHERE ReservaId = @ReservaId;

    IF @EstadoAtual IS NULL
    BEGIN
        RAISERROR('Reserva não encontrada.', 16, 1);
        RETURN;
    END

    -- 2. Validar se já está paga
    IF @EstadoAtual = 'CONFIRMADA'
    BEGIN
        RAISERROR('Esta reserva já se encontra paga e confirmada.', 16, 1);
        RETURN;
    END
    
    IF @EstadoAtual = 'CANCELADA'
    BEGIN
        RAISERROR('Não é possível pagar uma reserva cancelada.', 16, 1);
        RETURN;
    END

    -- 3. Validar valores (Segurança básica)
    IF @Valor < @TotalEsperado
    BEGIN
        RAISERROR('Valor insuficiente. O pagamento deve cobrir o total da reserva.', 16, 1);
        RETURN;
    END

    -- 4. Transação: Gravar Pagamento + Atualizar Reserva
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Insere o registo financeiro
        INSERT INTO core.Pagamento (ReservaId, Metodo, Valor, TransacaoRef)
        VALUES (@ReservaId, @Metodo, @Valor, @TransacaoRef);

        -- Atualiza o estado da reserva
        UPDATE core.Reserva
        SET Estado = 'CONFIRMADA'
        WHERE ReservaId = @ReservaId;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @Msg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@Msg, 16, 1);
    END CATCH
END
GO