const request = require('supertest');
const app = require('../../app');
const { pool, limparBanco } = require('../helpers/db');

describe('POST /api/auth/login', () => {
  beforeEach(async () => {
    await limparBanco();
    await pool.query(
      `INSERT INTO usuarios (nome, email, senha, nivel) VALUES ($1, $2, $3, $4)`,
      ['Usuária Teste', 'teste@fabrica.com', 'senha123', 'USUARIO']
    );
  });

  afterAll(async () => {
    await pool.end();
  });

  it('retorna um token para credenciais válidas', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'teste@fabrica.com', senha: 'senha123' });

    expect(res.status).toBe(200);
    expect(res.body.token).toEqual(expect.any(String));
    expect(res.body.usuario.email).toBe('teste@fabrica.com');
  });

  it('aceita o email em qualquer capitalização', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'TESTE@fabrica.com', senha: 'senha123' });

    expect(res.status).toBe(200);
  });

  it('rejeita senha incorreta', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'teste@fabrica.com', senha: 'senha-errada' });

    expect(res.status).toBe(401);
  });

  it('rejeita quando email não existe', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'ninguem@fabrica.com', senha: 'senha123' });

    expect(res.status).toBe(401);
  });

  it('retorna 400 quando faltam campos obrigatórios', async () => {
    const res = await request(app).post('/api/auth/login').send({ email: 'teste@fabrica.com' });

    expect(res.status).toBe(400);
  });
});
