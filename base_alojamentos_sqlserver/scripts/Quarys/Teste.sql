DECLARE @PropId INT = (SELECT TOP 1 PropriedadeId FROM core.Propriedade);
-- Tentar reservar em Fevereiro (Livre)
EXEC core.SP_CheckDisponibilidade 
    @PropriedadeId = @PropId, 
    @CheckIn = '2025-02-01', 
    @CheckOut = '2025-02-05';