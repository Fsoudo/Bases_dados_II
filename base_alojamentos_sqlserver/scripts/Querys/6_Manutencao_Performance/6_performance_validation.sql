/* ==================================================================================
   performance_validation.sql — Validação dos Índices e Estatísticas
   ================================================================================== */
USE AluguerHab;
GO

PRINT '=== 1. VERIFICAÇÃO DOS ÍNDICES ===';

-- Verificar se o índice filtrado existe
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Reserva_EstadoConfirmada' AND object_id = OBJECT_ID('core.Reserva'))
BEGIN
    PRINT '[SUCESSO] O índice filtrado "IX_Reserva_EstadoConfirmada" existe.';
END
ELSE
BEGIN
    PRINT '[ERRO] O índice "IX_Reserva_EstadoConfirmada" NÃO foi encontrado.';
END

-- Verificar se o índice de cidade existe
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Localizacao_Cidade' AND object_id = OBJECT_ID('core.Localizacao'))
BEGIN
    PRINT '[SUCESSO] O índice "IX_Localizacao_Cidade" existe.';
END
ELSE
BEGIN
    PRINT '[ERRO] O índice "IX_Localizacao_Cidade" NÃO foi encontrado.';
END
GO

PRINT '';
PRINT '=== 2. VERIFICAÇÃO DAS ESTATÍSTICAS ===';

-- Mostra quando foi a última atualização das estatísticas para as tabelas principais
SELECT 
    OBJECT_NAME(object_id) AS Tabela,
    name AS NomeEstatistica,
    STATS_DATE(object_id, stats_id) AS UltimaAtualizacao
FROM sys.stats
WHERE OBJECT_NAME(object_id) IN ('Reserva', 'Localizacao', 'Propriedade')
ORDER BY UltimaAtualizacao DESC;
GO