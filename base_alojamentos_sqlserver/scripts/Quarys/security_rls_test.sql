/* ==================================================================================
   Teste de Segurança RLS
   ================================================================================== */
USE AluguerHab;
GO

PRINT '>>> TESTE 1: Sou o Administrador (db_owner) <<<';
PRINT 'Devo ver TODAS as propriedades:';
SELECT PropriedadeId, Titulo, AnfitriaoId FROM core.Propriedade;
GO

PRINT '';
PRINT '>>> TESTE 2: Vou encarnar o João (joao.host@email.com) <<<';
EXECUTE AS USER = 'joao.host@email.com';
    
    PRINT 'Agora sou: ' + USER_NAME();
    PRINT 'A tentar ler a tabela Propriedade...';
    
    -- Se o RLS funcionar, aqui só deve aparecer a casa do João. 
    -- As casas de outros anfitriões devem desaparecer.
    SELECT PropriedadeId, Titulo, AnfitriaoId FROM core.Propriedade;

REVERT; -- Voltar a ser eu mesmo
GO