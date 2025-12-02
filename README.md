[CHECKLIST_Projeto.md](https://github.com/user-attachments/files/23879808/CHECKLIST_Projeto.md)
# CHECKLIST DO PROJETO — Plataforma de Alojamentos (SQL Server)

> Documento de trabalho para acompanhar o estado dos requisitos, tarefas e entregáveis.

## 1) Estado atual (✅ feito)
- **Esquema base da BD** (tabelas, constraints, índices core) — [`core_tables.sql`](sandbox:/mnt/data/base_alojamentos_sqlserver/db/core_tables.sql)
- **Criação da BD + filegroups** — [`init.sql`](sandbox:/mnt/data/base_alojamentos_sqlserver/db/init.sql)
- **SP de disponibilidade** — [`sp_check_disponibilidade.sql`](sandbox:/mnt/data/base_alojamentos_sqlserver/db/sp_check_disponibilidade.sql)
- **Stub do gerador (≥10k)** — [`generator_stub.py`](sandbox:/mnt/data/base_alojamentos_sqlserver/scripts/generator_stub.py)
- **Template do relatório** — [`Relatorio_Template.md`](sandbox:/mnt/data/base_alojamentos_sqlserver/docs/Relatorio_Template.md)

## 2) A fazer (☐ por concluir)
### Lógica de negócio (SPs & Triggers)
- [ ] **SP_CriarReserva** (transacional): valida disponibilidade, calcula Total via `PrecoEpoca`, grava `Reserva`, marca dias ocupados.
- [ ] **SP_RegistarPagamento**: cria `Pagamento` e define `Reserva.Estado = 'CONFIRMADA'` (idempotente).
- [ ] **SP_CancelarReserva**: define `Estado = 'CANCELADA'` e liberta dias no calendário.
- [ ] **Trigger** `TRG_Avaliacao_RecalculaRating` em `Avaliacao` (INSERT/UPDATE/DELETE) para atualizar `Propriedade.RatingMedio`.

### Dados & Gerador
- [ ] Ligar o gerador a **datasets públicos** (nomes/cidades/amenities) e **citar fontes** no relatório.
- [ ] Garantir reservas **sem sobreposição** e volume **>= 10 000** registos úteis.
- [ ] Adicionar **media de vídeo** (tabela `Video` ou coluna genérica) — opcional.

### Segurança
- [ ] **Papéis** (CLIENTE, ANFITRIAO, ADMIN) no SQL Server e **GRANTs mínimos**.
- [ ] **Row-Level Security** para anfitriões nas suas propriedades/reservas.
- [ ] **Auditing** e **cifra** (TDE/column encryption conforme dados sensíveis).

### Desempenho
- [ ] **Full-Text** em `Propriedade(Titulo, Descricao)` (se aplicável).
- [ ] Índices adicionais após carga massiva; **update stats**.
- [ ] (Opcional) **Particionamento** de `Reserva` por ano/mês.

### Backups & Manutenção
- [ ] Jobs SQL Agent: **FULL** diário, **DIFF** 6–12h, **LOG** 15–30min.
- [ ] **DBCC CHECKDB** semanal; **rebuild/reorganize** e **update stats**.
- [ ] **Retenção/limpeza** e **teste de restore** documentado.

### Servidor (6 discos) — evidências
- [ ] **tempdb** dedicado (vários datafiles iguais).
- [ ] **LOG** isolado; **DATA vs INDEX** separados; **BACKUP** noutra unidade.
- [ ] Capturas/comandos no relatório com a configuração real.

### KPIs / Relatórios
- [ ] Faixas **etárias** que mais alugam por país.
- [ ] **Origem** de turistas por destino/época.
- [ ] **Ocupação** por propriedade/mês e **receita** por país/época.

### Documentação
- [ ] Preencher **Relatório** com: ERD, fontes dos dados, SPs/Triggers, segurança, backups, desempenho, manutenção, KPIs e instruções de **restore**.

### Entregáveis
- [ ] **PDF** final + **scripts** + **.bak** → **ZIP** para submissão.

## 3) Notas rápidas
- Antes dos índices avançados, faz a **carga de dados** para evitar fragmentação desnecessária.
- Mantém um **script de seed** reexecutável e uma secção no relatório com **fontes** dos datasets.
- Documenta as **decisões de arquitetura** (porquê 6 discos assim, porquê estes índices, etc.).

---

Se precisares, o próximo passo será entregar as SPs/trigger em ficheiros `.sql` prontos a colar no SSMS.
