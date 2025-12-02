
# Relatório — Plataforma de Alojamentos (SQL Server)

## 1. Introdução
Contexto do problema, objetivos, escopo do projeto.

## 2. Requisitos e Funcionalidades
- Consulta de propriedades (características, fotos/vídeos, preços por época, avaliações).
- Reserva com verificação de disponibilidade e pagamento.
- Perfis de utilizador: cliente, anfitrião, administrador.
- Requisitos técnicos: SQL Server, >=6 discos, >=10k registos com gerador, etc.

## 3. Modelo de Dados (ERD)
Desenho do diagrama; descrição de entidades e relações.

## 4. Criação da Base de Dados
Decisões sobre filegroups/discos; scripts `init.sql`, `core_tables.sql`.

## 5. Método de Preenchimento
Arquitectura do gerador; datasets públicos usados; volume; validação.

## 6. Stored Procedures e Triggers
Principais SPs (ex.: disponibilidade, criar reserva, registar pagamento); triggers (recalcular rating).

## 7. Segurança
Papéis, permissões, row-level security (se aplicável), encriptação, auditoria.

## 8. Backups
Estratégia (FULL/DIFF/LOG), retenção, testes de restore.

## 9. Desempenho
Índices, Query Store, análise de planos, particionamento (se aplicável).

## 10. Manutenção / Automatização
Jobs (índices, stats, limpeza, backups), monitorização.

## 11. KPIs / Relatórios
Faixas etárias por país, origem de turistas, ocupação por mês/propriedade, faturação.

## 12. Conclusão
Resultados, trabalho futuro.

## 13. Referências
Datasets públicos, documentação e artigos técnicos.
