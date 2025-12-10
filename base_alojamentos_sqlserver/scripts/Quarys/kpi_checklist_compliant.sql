/* ==================================================================================
   kpi_checklist_compliant.sql — Relatórios Exatos para a Checklist
   ================================================================================== */
USE AluguerHab;
GO

PRINT '=== 1. FAIXAS ETÁRIAS QUE MAIS ALUGAM POR PAÍS ===';
PRINT 'Requisito: Analisar idade dos clientes agrupada por país.';

SELECT 
    c.Pais AS PaisCliente,
    -- Calcular a Faixa Etária dinamicamente
    CASE 
        WHEN DATEDIFF(YEAR, c.DataNascimento, GETDATE()) < 25 THEN 'Jovens (18-24)'
        WHEN DATEDIFF(YEAR, c.DataNascimento, GETDATE()) BETWEEN 25 AND 35 THEN 'Jovens Adultos (25-35)'
        WHEN DATEDIFF(YEAR, c.DataNascimento, GETDATE()) BETWEEN 36 AND 50 THEN 'Adultos (36-50)'
        WHEN DATEDIFF(YEAR, c.DataNascimento, GETDATE()) > 50 THEN 'Seniores (+50)'
        ELSE 'Desconhecido'
    END AS FaixaEtaria,
    COUNT(r.ReservaId) AS TotalReservas
FROM core.Cliente c
JOIN core.Reserva r ON c.ClienteId = r.ClienteId
WHERE r.Estado = 'CONFIRMADA'
GROUP BY c.Pais, 
    CASE 
        WHEN DATEDIFF(YEAR, c.DataNascimento, GETDATE()) < 25 THEN 'Jovens (18-24)'
        WHEN DATEDIFF(YEAR, c.DataNascimento, GETDATE()) BETWEEN 25 AND 35 THEN 'Jovens Adultos (25-35)'
        WHEN DATEDIFF(YEAR, c.DataNascimento, GETDATE()) BETWEEN 36 AND 50 THEN 'Adultos (36-50)'
        WHEN DATEDIFF(YEAR, c.DataNascimento, GETDATE()) > 50 THEN 'Seniores (+50)'
        ELSE 'Desconhecido'
    END
ORDER BY c.Pais, TotalReservas DESC;
GO

PRINT '';
PRINT '=== 2. ORIGEM DE TURISTAS POR DESTINO E ÉPOCA ===';
PRINT 'Requisito: Quem vai para onde e em que altura?';

SELECT 
    c.Pais AS OrigemTurista,
    l.Cidade AS Destino,
    ISNULL(e.Nome, 'Fora de Época') AS Epoca,
    COUNT(r.ReservaId) AS QuantidadeReservas
FROM core.Reserva r
JOIN core.Cliente c ON r.ClienteId = c.ClienteId
JOIN core.Propriedade p ON r.PropriedadeId = p.PropriedadeId
JOIN core.Localizacao l ON p.LocalizacaoId = l.LocalizacaoId
-- Tentativa de ligar à Época baseada na data de checkin
LEFT JOIN core.Epoca e ON r.DataCheckIn BETWEEN e.DataInicio AND e.DataFim
WHERE r.Estado = 'CONFIRMADA'
GROUP BY c.Pais, l.Cidade, e.Nome
ORDER BY QuantidadeReservas DESC;
GO

PRINT '';
PRINT '=== 3. OCUPAÇÃO POR PROPRIEDADE/MÊS E RECEITA POR PAÍS/ÉPOCA ===';

PRINT '>>> Tabela 3.1: Ocupação por Propriedade e Mês';
SELECT 
    p.Titulo AS Propriedade,
    YEAR(r.DataCheckIn) AS Ano,
    MONTH(r.DataCheckIn) AS Mes,
    COUNT(r.ReservaId) AS DiasOcupados -- Simplificado: Conta nº reservas iniciadas no mês
FROM core.Reserva r
JOIN core.Propriedade p ON r.PropriedadeId = p.PropriedadeId
WHERE r.Estado = 'CONFIRMADA'
GROUP BY p.Titulo, YEAR(r.DataCheckIn), MONTH(r.DataCheckIn)
ORDER BY p.Titulo, Mes;

PRINT '>>> Tabela 3.2: Receita Total por País e Época';
SELECT 
    c.Pais AS PaisCliente,
    ISNULL(e.Nome, 'Fora de Época') AS Epoca,
    SUM(r.Total) AS ReceitaTotal
FROM core.Reserva r
JOIN core.Cliente c ON r.ClienteId = c.ClienteId
LEFT JOIN core.Epoca e ON r.DataCheckIn BETWEEN e.DataInicio AND e.DataFim
WHERE r.Estado = 'CONFIRMADA'
GROUP BY c.Pais, e.Nome
ORDER BY ReceitaTotal DESC;
GO