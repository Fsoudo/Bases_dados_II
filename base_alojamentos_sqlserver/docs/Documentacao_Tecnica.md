# Documentação Técnica - Base de Dados de Alojamentos

Este documento descreve a estrutura, organização e funcionalidade dos scripts SQL e Python do projeto.

---

## 1. Estrutura Base (`db/`)

Estes ficheiros representam o "esqueleto" e a infraestrutura do projeto. Devem ser os primeiros a serem executados.

*   **`1_disk_local/1_init.sql`**
    *   **Função**: Cria a base de dados `AluguerHab`.
    *   **Contexto**: Versão para desenvolvimento local (1 disco). Cria todos os filegroups em `C:\SQL_Projeto`.
*   **`6_disks_prod/1_init.sql`**
    *   **Função**: Cria a base de dados `AluguerHab`.
    *   **Contexto**: Versão para produção (6 discos). Distribui ficheiros por `E:\`, `F:\`, `G:\` conforme requisitos de performance.
*   **`2_core_tables.sql`**
    *   **Função**: Cria o esquema `core` e todas as tabelas principais (`Utilizador`, `Propriedade`, `Reserva`, `PrecoEpoca`, etc.). Define chaves primárias, estrangeiras e constraints.
*   **`3_sp_check_disponibilidade.sql`**
    *   **Função**: Stored Procedure **critica** (`core.SP_CheckDisponibilidade`).
    *   **Lógica**: Verifica se uma propriedade está livre num intervalo de datas, cruzando com reservas existentes e bloqueios manuais no calendário.

---

## 2. Lógica de Negócio (`scripts/Querys/4_Logica/`)

Scripts que implementam as operações principais do sistema (CRUD transacional).

*   **`4_sp_criar_reserva.sql`**
    *   **SP**: `core.SP_CriarReserva`
    *   **Função**: Processo transacional de reserva. Verifica disponibilidade, calcula o preço total com base na época, e insere a reserva com estado 'PENDENTE'.
*   **`4_sp_cancelar_reserva.sql`**
    *   **SP**: `core.SP_CancelarReserva`
    *   **Função**: Cancela uma reserva, libertando as datas e (opcionalmente) gerindo reembolsos/multas na lógica de negócio.
*   **`4_sp_registar_pagamento.sql`**
    *   **SP**: `core.SP_RegistarPagamento`
    *   **Função**: Regista o pagamento de uma reserva e altera o seu estado para 'CONFIRMADA'. Garante idempotência.
*   **`4_trg_avaliacao_recalcula.sql`**
    *   **Trigger**: `TRG_Avaliacao_RecalculaRating`
    *   **Função**: Disparado após INSERT/UPDATE/DELETE na tabela `Avaliacao`. Recalcula automaticamente a média (`RatingMedio`) na tabela `Propriedade`.

---

## 3. Segurança (`scripts/Querys/5_Seguranca/`)

Implementação de controlo de acessos e proteção de dados.

*   **`5_security_advanced.sql`**
    *   **Função**: Criação de Logins e Users SQL. Atribuição de permissões granulares aos papéis (ex: `Anfitriao` só pode ver suas casas).
*   **`5_security_rls.sql`**
    *   **Função**: Row-Level Security (RLS). Define políticas para que um Anfitrião veja apenas os registos (reservas, pagamentos) associados às suas propriedades.

---

## 4. Manutenção e Performance (`scripts/Querys/6_Manutencao_Performance/`)

Scripts para garantir a saúde e rapidez da base de dados.

*   **`6_maintenance_completion.sql`**
    *   **Função**: Scripts completos de backup (FULL, DIFF, LOG) e jobs de manutenção de índices.
*   **`6_performance_tuning.sql`**
    *   **Função**: Criação de índices Non-Clustered otimizados para as queries mais frequentes e Índices Full-Text para pesquisa de texto em descrições.
*   **`6_performance_validation.sql`**
    *   **Função**: Queries para testar a velocidade da BD antes e depois dos índices. Mostra planos de execução e estatísticas de IO.

---

## 5. Relatórios e KPIs (`scripts/Querys/7_Relatorios_KPIs/`)

Queries analíticas para extração de inteligência de negócio.

*   **`7_kpi_reports.sql`**
    *   **Query**: Relatórios de gestão. Ex: "Top 10 Anfitriões por Faturação", "Ocupação Média por Mês".
*   **`7_kpi_checklist_compliant.sql`**
    *   **Query**: Queries específicas pedidas no enunciado (ex: Faixas etárias, Origem dos turistas).

---

## 6. Testes e Suporte (`scripts/Querys/9_Testes_Suporte/`)

Scripts auxiliares para validação durante o desenvolvimento.

*   **Testes Unitários**: (`test_sp_criar_reserva.sql`, etc.) Script para testar individualmente cada SP e validar se o resultado é o esperado (Sucesso vs Erro).
*   **Utilitários**:
    *   `util_reseed_data.sql`: Limpa dados de teste e reinsere dados frescos.
    *   `util_alterar_recovery.sql`: Alterna entre modelos de recuperação (Simple/Full).

---

## 7. Gerador de Dados (`scripts/`)

*   **`limpar_datasets.py`**: Limpa e normaliza os CSVs brutos (`datasets/datasets_completos`) para a pasta `datasets/datasets_limpos`.
*   **`generator_stub.py`**: Script principal em Python.
    *   Lê os dados limpos.
    *   Popula a BD com >10.000 registos realistas.
    *   Gera Utilizadores, Propriedades, Épocas, Preços, Reservas e Avaliações.
