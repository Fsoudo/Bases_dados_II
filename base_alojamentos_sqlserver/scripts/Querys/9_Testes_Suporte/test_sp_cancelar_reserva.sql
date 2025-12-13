-- Teste: Cancelar a última reserva feita
DECLARE @UltimaReserva BIGINT = (SELECT TOP 1 ReservaId FROM core.Reserva ORDER BY ReservaId DESC);

EXEC core.SP_CancelarReserva @ReservaId = @UltimaReserva;

-- Verificar se o estado mudou
SELECT * FROM core.Reserva WHERE ReservaId = @UltimaReserva;