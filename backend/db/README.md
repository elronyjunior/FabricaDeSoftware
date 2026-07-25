# backend/db/schema.sql

DDL gerado automaticamente a partir do banco Postgres real do projeto
(via `information_schema` + `pg_catalog`, sem `pg_dump`). Usado apenas para
provisionar o Postgres descartável do CI e para testes locais — não é uma
migration e não deve ser aplicado contra o banco de produção/dev (ele não usa
`CREATE TYPE IF NOT EXISTS`, então falha se os tipos já existirem).

## Como regenerar

Se o schema real mudar (nova tabela/coluna), regenere este arquivo apontando
para o banco atual:

1. Rode uma introspecção equivalente via `information_schema.columns`,
   `information_schema.table_constraints` e `pg_enum` (tipos ENUM custom:
   `complexidade_projeto`, `prioridade_requisito`, `nivel_usuario`).
2. Ou, se tiver `pg_dump` disponível: `pg_dump --schema-only --no-owner --no-privileges <banco> > backend/db/schema.sql`
   e então adicione manualmente os `CREATE TYPE ... AS ENUM (...)` no topo,
   se o `pg_dump` não os incluir na mesma ordem.
3. Rode `npm test` (backend) para confirmar que o schema novo sobe limpo no
   Postgres de teste do CI.

## Alterações manuais aplicadas depois da geração inicial

Como não há migration framework, cada alteração de schema feita depois da
geração inicial precisa ser replicada manualmente em TRÊS lugares: este
arquivo, o banco de dev/produção real, e (se você tiver um `fabrica_software_test`
local) o banco de teste local. Esqueça um desses e o CI ou os testes locais
divergem silenciosamente do banco real.

- `conteudo_json jsonb` adicionada em `documentos` — armazena o JSON estruturado
  gerado pela IA (antes descartado após criar o Google Doc), para permitir
  edição in-app. Aplicada via `ALTER TABLE documentos ADD COLUMN conteudo_json jsonb;`
  (operação instantânea/segura em coluna nullable, mesmo com linhas existentes).
