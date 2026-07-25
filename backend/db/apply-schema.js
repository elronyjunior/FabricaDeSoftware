// Aplica backend/db/schema.sql no banco apontado pelas variáveis de ambiente
// DB_HOST/DB_PORT/DB_USER/DB_PASSWORD/DB_NAME. Usado pelo CI para provisionar
// o Postgres de teste, e localmente para bootstrap de um banco de teste novo.
const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

async function main() {
  const client = new Client({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
  });

  await client.connect();

  // schema.sql cria tipos ENUM, que não suportam "IF NOT EXISTS" no Postgres.
  // Isso é seguro num container novo do CI, mas re-rodar localmente contra o
  // mesmo banco de teste já aplicado falharia — então pulamos nesse caso.
  const jaAplicado = await client.query(
    `SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'usuarios'`
  );

  if (jaAplicado.rows.length > 0) {
    console.log(`Schema já aplicado em ${process.env.DB_NAME}@${process.env.DB_HOST}, nada a fazer.`);
    await client.end();
    return;
  }

  const sql = fs.readFileSync(path.join(__dirname, 'schema.sql'), 'utf8');
  await client.query(sql);
  await client.end();
  console.log(`Schema aplicado em ${process.env.DB_NAME}@${process.env.DB_HOST}`);
}

main().catch((err) => {
  console.error('Erro ao aplicar schema:', err.message);
  process.exit(1);
});
