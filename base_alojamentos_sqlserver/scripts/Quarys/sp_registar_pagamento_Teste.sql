-- 1. Descobrir qual a reserva pendente do Pedro (que criámos há pouco)
DECLARE @IdParaPagar BIGINT;
DECLARE @ValorAPagar DECIMAL(12,2);

SELECT TOP 1 @IdParaPagar = ReservaId, @ValorAPagar = Total
FROM core.Reserva 
WHERE Estado = 'PENDENTE' AND ClienteId IN (SELECT ClienteId FROM core.Cliente WHERE Pais = 'Espanha')
ORDER BY CriadaEm DESC;

PRINT 'Vou pagar a reserva ID: ' + CAST(@IdParaPagar AS VARCHAR);

-- 2. Executar o Pagamento
EXEC core.SP_RegistarPagamento
    @ReservaId = @IdParaPagar,
    @Metodo = 'MBWAY',
    @TransacaoRef = 'MB-999-888',
    @Valor = @ValorAPagar;

-- 3. Verificar o resultado final
SELECT * FROM core.Reserva WHERE ReservaId = @IdParaPagar;
SELECT * FROM core.Pagamento WHERE ReservaId = @IdParaPagar;