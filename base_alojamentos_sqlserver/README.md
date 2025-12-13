# Plataforma de Aluguer — Projeto SQL Server

Este repositório contém a base de dados, gerador de dados e documentação para a plataforma de alojamentos (reservas, pagamentos, avaliações).

## Estrutura
```
/db
  init.sql                -> cria a BD, filegroups e configurações base
  core_tables.sql         -> tabelas principais + constraints
  sp_check_disponibilidade.sql -> SP para verificar disponibilidade
/docs
  Relatorio_Template.md   -> esqueleto do relatório final
/scripts
  generator_stub.py       -> esqueleto do gerador de dados (>=10k registos)
/backups                  -> destino previsto para backups (.bak, .trn)
```

## Passos rápidos
1. Criar a BD no SQL Server com `db/init.sql` (ajusta os caminhos dos discos no topo).
2. Criar tabelas com `db/core_tables.sql`.
3. Criar SP de disponibilidade com `db/sp_check_disponibilidade.sql`.
4. Configurar o gerador em `/scripts/generator_stub.py` (ligação ao SQL Server + CSVs públicos).
5. Preencher o relatório: `/docs/Relatorio_Template.md`.
