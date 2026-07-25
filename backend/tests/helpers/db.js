const pool = require('../../db');

// Limpa todas as tabelas entre testes de integração, mantendo o schema.
// A ordem não importa graças ao CASCADE, mas listamos por clareza.
async function limparBanco() {
  await pool.query(`
    TRUNCATE TABLE
      logs, documentos, treinamentos, testes,
      contribuidores_projeto, recursos_projeto, tecnologias_projeto, requisitos_projeto,
      projetos, contribuidores, recursos, requisitos, tecnologias,
      clientes, enderecos, usuarios
    RESTART IDENTITY CASCADE;
  `);
}

module.exports = { pool, limparBanco };
