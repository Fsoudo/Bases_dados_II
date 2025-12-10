/* ==================================================================================
   kpi_reports.sql — Relatórios de Gestão e Indicadores (KPIs)
   ================================================================================== */
USE AluguerHab;
GO

PRINT '=== RELATÓRIO 1: TAXA DE OCUPAÇÃO E FATURAÇÃO POR PROPRIEDADE ===';
PRINT 'Mostra quais as casas que rendem mais dinheiro e estão mais cheias.';
PRINT '-------------------------------------------------------------------';

SELECT 
    p.Titulo,
    l.Cidade,
    COUNT(r.ReservaId) AS TotalReservas,
    -- Soma apenas as reservas CONFIRMADAS para saber o lucro real
    ISNULL(SUM(CASE WHEN r.Estado = 'CONFIRMADA' THEN r.Total ELSE 0 END), 0) AS FaturacaoTotal,
    -- Calcula a duração média das estadias
    AVG(DATEDIFF(DAY, r.DataCheckIn, r.DataCheckOut)) AS MediaDiasEstadia
FROM core.Propriedade p
JOIN core.Localizacao l ON p.LocalizacaoId = l.LocalizacaoId
LEFT JOIN core.Reserva r ON p.PropriedadeId = r.PropriedadeId
GROUP BY p.Titulo, l.Cidade
ORDER BY FaturacaoTotal DESC;
GO

PRINT '';
PRINT '=== RELATÓRIO 2: TOP CLIENTES (QUEM GASTA MAIS?) ===';
PRINT 'Identifica os "Golden Clients" para campanhas de marketing.';
PRINT '-------------------------------------------------------------------';

SELECT TOP 5
    u.Nome AS NomeCliente,
    c.Pais AS Origem,
    COUNT(r.ReservaId) AS NumeroReservas,
    ISNULL(SUM(r.Total), 0) AS TotalGasto
FROM core.Cliente c
JOIN core.Utilizador u ON c.UtilizadorId = u.UtilizadorId
JOIN core.Reserva r ON c.ClienteId = r.ClienteId
WHERE r.Estado = 'CONFIRMADA'
GROUP BY u.Nome, c.Pais
ORDER BY TotalGasto DESC;
GO

PRINT '';
PRINT '=== RELATÓRIO 3: ORIGEM DOS TURISTAS (ANÁLISE GEOGRÁFICA) ===';
PRINT 'De onde vêm os nossos clientes?';
PRINT '-------------------------------------------------------------------';

SELECT 
    c.Pais AS PaisOrigem,
    COUNT(DISTINCT c.ClienteId) AS TotalClientes,
    COUNT(r.ReservaId) AS TotalReservasFeitas
FROM core.Cliente c
LEFT JOIN core.Reserva r ON c.ClienteId = r.ClienteId
GROUP BY c.Pais
ORDER BY TotalReservasFeitas DESC;
GO