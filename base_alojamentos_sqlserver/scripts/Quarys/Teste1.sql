DECLARE @PropId INT = (SELECT TOP 1 PropriedadeId FROM core.Propriedade);
-- Tentar reservar de 6 a 8 de Janeiro (Maria está lá de 5 a 10)
EXEC core.SP_CheckDisponibilidade 
    @PropriedadeId = @PropId, 
    @CheckIn = '2025-01-06', 
    @CheckOut = '2025-01-08';