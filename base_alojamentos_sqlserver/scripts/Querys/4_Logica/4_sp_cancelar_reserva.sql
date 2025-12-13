/* ==============================================================================
   sp_cancelar_reserva.sql — Cancela uma reserva e liberta as datas
   ============================================================================== */
USE AluguerHab;
GO

IF OBJECT_ID(N'core.SP_CancelarReserva', N'P') IS NOT NULL
    DROP PROCEDURE core.SP_CancelarReserva;
GO

CREATE PROCEDURE core.SP_CancelarReserva
    @ReservaId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Verificar se a reserva existe
    DECLARE @EstadoAtual NVARCHAR(30);
    
    SELECT @EstadoAtual = Estado
    FROM core.Reserva
    WHERE ReservaId = @ReservaId;

    IF @EstadoAtual IS NULL
    BEGIN
        RAISERROR('Reserva não encontrada.', 16, 1);
        RETURN;
    END

    -- 2. Verificar se já estava cancelada
    IF @EstadoAtual = 'CANCELADA'
    BEGIN
        RAISERROR('Esta reserva já se encontra cancelada.', 16, 1);
        RETURN;
    END

    -- 3. Executar o cancelamento
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Atualiza o estado
        UPDATE core.Reserva
        SET Estado = 'CANCELADA'
        WHERE ReservaId = @ReservaId;

        -- (Opcional) Se tivéssemos lógica de reembolso, seria aqui.
        
        COMMIT TRANSACTION;
        PRINT 'Reserva ' + CAST(@ReservaId AS NVARCHAR) + ' cancelada com sucesso.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @Msg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@Msg, 16, 1);
    END CATCH
END
GO