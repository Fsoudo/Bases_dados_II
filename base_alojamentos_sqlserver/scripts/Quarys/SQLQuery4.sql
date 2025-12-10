/* ================================================
   sp_check_disponibilidade.sql — Verifica janela
   ================================================ */
USE AluguerHab;
GO

IF OBJECT_ID(N'core.SP_CheckDisponibilidade', N'P') IS NOT NULL
    DROP PROCEDURE core.SP_CheckDisponibilidade;
GO

CREATE PROCEDURE core.SP_CheckDisponibilidade
    @PropriedadeId INT,
    @CheckIn DATE,
    @CheckOut DATE
AS
BEGIN
    SET NOCOUNT ON;

    IF @CheckIn >= @CheckOut
    BEGIN
        RAISERROR('Intervalo inválido.', 16, 1);
        RETURN;
    END

    DECLARE @ExisteChoque BIT = 0;

    -- 1) janela colide com reservas confirmadas?
    IF EXISTS (
        SELECT 1
        FROM core.Reserva r
        WHERE r.PropriedadeId = @PropriedadeId
          AND r.Estado = N'CONFIRMADA'
          AND r.DataCheckIn < @CheckOut
          AND r.DataCheckOut > @CheckIn
    )
    BEGIN
        SET @ExisteChoque = 1;
    END

    -- 2) Calendário indica dias ocupados na janela?
    IF EXISTS (
        SELECT 1
        FROM core.CalendarioDisponibilidade c
        WHERE c.PropriedadeId = @PropriedadeId
          AND c.Dia >= @CheckIn AND c.Dia < @CheckOut
          AND c.Ocupado = 1
    )
    BEGIN
        SET @ExisteChoque = 1;
    END

    SELECT Disponivel = IIF(@ExisteChoque = 0, 1, 0);
END
GO