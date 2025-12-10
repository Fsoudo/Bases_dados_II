/* ==================================================================================
   performance_simple.sql — Índices e Estatísticas 
   ================================================================================== */
USE AluguerHab;
GO

PRINT '=== 1. CRIAÇÃO DE ÍNDICES ADICIONAIS ===';

-- A. Índice Filtrado para Reservas
-- Otimiza o relatório de faturação, focando apenas no dinheiro real (CONFIRMADA)
-- Ignora milhões de linhas de reservas canceladas ou pendentes.
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Reserva_EstadoConfirmada' AND object_id = OBJECT_ID('core.Reserva'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Reserva_EstadoConfirmada
    ON core.Reserva (Total)
    INCLUDE (ClienteId, PropriedadeId) 
    WHERE Estado = 'CONFIRMADA';
    
    PRINT '>> Índice filtrado IX_Reserva_EstadoConfirmada criado.';
END
GO

-- B. Índice de Cobertura para Localização
-- Acelera pesquisas por Cidade (muito comum na "Home Page" do site)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Localizacao_Cidade' AND object_id = OBJECT_ID('core.Localizacao'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Localizacao_Cidade
    ON core.Localizacao (Cidade)
    INCLUDE (Pais);
    
    PRINT '>> Índice IX_Localizacao_Cidade criado.';
END
GO

PRINT '';
PRINT '=== 2. MANUTENÇÃO DE ESTATÍSTICAS ===';

-- Força o SQL Server a reavaliar a distribuição dos dados agora que criámos índices novos.
-- Isto garante que as queries usam os índices que acabámos de criar.
EXEC sp_updatestats;

PRINT '>> Estatísticas atualizadas com sucesso.';
PRINT '=== MÓDULO DE DESEMPENHO CONCLUÍDO ===';
GO