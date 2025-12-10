/* ==================================================================================
   security_rls.sql — Implementação de Row-Level Security (Segurança ao nível da linha)
   ================================================================================== */
USE AluguerHab;
GO

-- 1. CRIAÇÃO DE UTILIZADORES PARA TESTE
-- Vamos criar um utilizador SQL para simular o nosso anfitrião 'João'
-- (Assumindo que o email dele nos dados de teste é 'joao.host@email.com')
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'joao.host@email.com')
BEGIN
    CREATE USER [joao.host@email.com] WITHOUT LOGIN;
    -- Dar permissões mínimas: Apenas ler e escrever no schema 'core'
    GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::core TO [joao.host@email.com];
END
GO

-- 2. FUNÇÃO DE SEGURANÇA (O "Porteiro")
-- Esta função devolve 1 se o utilizador tiver permissão para ver a linha, ou nada se não tiver.
CREATE OR ALTER FUNCTION core.fn_SegurancaPropriedade(@AnfitriaoId INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN SELECT 1 AS Acesso
WHERE 
    -- Regra A: Se for o 'dbo' (dono da base) ou Administrador, vê tudo
    IS_MEMBER('db_owner') = 1
    OR IS_MEMBER('sysadmin') = 1
    OR
    -- Regra B: Se o utilizador logado corresponder ao dono desta propriedade
    (
      @AnfitriaoId IN (
          SELECT a.AnfitriaoId 
          FROM core.Anfitriao a
          JOIN core.Utilizador u ON a.UtilizadorId = u.UtilizadorId
          -- A magia acontece aqui: Comparar o User do SQL Server com o Email na tabela
          WHERE u.Email = USER_NAME() 
      )
    );
GO

-- 3. POLÍTICA DE SEGURANÇA (A "Lei")
-- Aplica a função acima à tabela Propriedade
DROP SECURITY POLICY IF EXISTS core.Pol_SegurancaPropriedades;
GO

CREATE SECURITY POLICY core.Pol_SegurancaPropriedades
    ADD FILTER PREDICATE core.fn_SegurancaPropriedade(AnfitriaoId) 
    ON core.Propriedade,
    ADD BLOCK PREDICATE core.fn_SegurancaPropriedade(AnfitriaoId) 
    ON core.Propriedade
    WITH (STATE = ON); -- Ativar a segurança
GO