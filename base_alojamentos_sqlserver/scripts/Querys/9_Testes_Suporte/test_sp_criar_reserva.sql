DECLARE @NovoId BIGINT;
DECLARE @PropId INT = (SELECT TOP 1 PropriedadeId FROM core.Propriedade);
DECLARE @ClientePedro INT = (SELECT ClienteId FROM core.Cliente WHERE Pais = 'Espanha'); -- O Pedro

-- Tentar reservar 3 noites em Fevereiro
EXEC core.SP_CriarReserva 
    @PropriedadeId = @PropId,
    @ClienteId = @ClientePedro,
    @CheckIn = '2025-02-10',
    @CheckOut = '2025-02-13',
    @ReservaId = @NovoId OUTPUT;

-- Ver se ficou gravada
SELECT * FROM core.Reserva WHERE ReservaId = @NovoId;