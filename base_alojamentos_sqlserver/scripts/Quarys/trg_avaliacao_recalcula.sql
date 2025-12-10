/* ==================================================================================
   trg_avaliacao_recalcula.sql — Trigger para manter a média de Rating atualizada
   ================================================================================== */
USE AluguerHab;
GO

CREATE OR ALTER TRIGGER core.TRG_Avaliacao_RecalculaRating
ON core.Avaliacao
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Identificar quais as propriedades afetadas
    -- (Pode ser a propriedade da avaliação inserida OU a da avaliação apagada)
    DECLARE @PropsAfetadas TABLE (PropriedadeId INT);

    INSERT INTO @PropsAfetadas
    SELECT PropriedadeId FROM inserted
    UNION
    SELECT PropriedadeId FROM deleted;

    -- 2. Recalcular a média para essas propriedades
    UPDATE p
    SET p.RatingMedio = ISNULL(Sub.Media, 0)
    FROM core.Propriedade p
    JOIN @PropsAfetadas pa ON p.PropriedadeId = pa.PropriedadeId
    OUTER APPLY (
        SELECT CAST(AVG(CAST(Rating AS DECIMAL(10,2))) AS DECIMAL(3,2)) AS Media
        FROM core.Avaliacao a
        WHERE a.PropriedadeId = p.PropriedadeId
    ) Sub;
END
GO