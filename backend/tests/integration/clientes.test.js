const request = require('supertest');
const app = require('../../app');
const { pool, limparBanco } = require('../helpers/db');
const { gerarTokenTeste } = require('../helpers/auth');

describe('CRUD /api/clientes', () => {
  const token = gerarTokenTeste();
  const authHeader = `Bearer ${token}`;

  beforeEach(async () => {
    await limparBanco();
  });

  afterAll(async () => {
    await pool.end();
  });

  const clienteExemplo = {
    razao_social: 'Empresa Teste LTDA',
    cnpj: '00.000.000/0001-00',
    email: 'contato@empresateste.com',
    telefone: '11999999999',
    setor: 'Tecnologia',
    contato: 'Fulano de Tal',
  };

  it('rejeita requisições sem token', async () => {
    const res = await request(app).get('/api/clientes');
    expect(res.status).toBe(401);
  });

  it('rejeita requisições com token inválido', async () => {
    const res = await request(app).get('/api/clientes').set('Authorization', 'Bearer token-invalido');
    expect(res.status).toBe(403);
  });

  it('cria um cliente e o retorna no GET /api/clientes', async () => {
    const criado = await request(app)
      .post('/api/clientes')
      .set('Authorization', authHeader)
      .send(clienteExemplo);

    expect(criado.status).toBe(201);
    expect(criado.body.id).toBeDefined();
    expect(criado.body.razao_social).toBe(clienteExemplo.razao_social);

    const lista = await request(app).get('/api/clientes').set('Authorization', authHeader);
    expect(lista.status).toBe(200);
    expect(lista.body).toHaveLength(1);
    expect(lista.body[0].cnpj).toBe(clienteExemplo.cnpj);
  });

  it('busca um cliente por id', async () => {
    const criado = await request(app)
      .post('/api/clientes')
      .set('Authorization', authHeader)
      .send(clienteExemplo);

    const res = await request(app)
      .get(`/api/clientes/${criado.body.id}`)
      .set('Authorization', authHeader);

    expect(res.status).toBe(200);
    expect(res.body.email).toBe(clienteExemplo.email);
  });

  it('retorna 404 ao buscar um cliente inexistente', async () => {
    const res = await request(app).get('/api/clientes/999999').set('Authorization', authHeader);
    expect(res.status).toBe(404);
  });

  it('atualiza um cliente existente', async () => {
    const criado = await request(app)
      .post('/api/clientes')
      .set('Authorization', authHeader)
      .send(clienteExemplo);

    const res = await request(app)
      .put(`/api/clientes/${criado.body.id}`)
      .set('Authorization', authHeader)
      .send({ ...clienteExemplo, razao_social: 'Empresa Teste Atualizada' });

    expect(res.status).toBe(200);
    expect(res.body.razao_social).toBe('Empresa Teste Atualizada');
  });

  it('rejeita CNPJ duplicado', async () => {
    await request(app).post('/api/clientes').set('Authorization', authHeader).send(clienteExemplo);
    const duplicado = await request(app)
      .post('/api/clientes')
      .set('Authorization', authHeader)
      .send(clienteExemplo);

    expect(duplicado.status).toBe(500);
  });

  it('deleta um cliente existente', async () => {
    const criado = await request(app)
      .post('/api/clientes')
      .set('Authorization', authHeader)
      .send(clienteExemplo);

    const del = await request(app)
      .delete(`/api/clientes/${criado.body.id}`)
      .set('Authorization', authHeader);
    expect(del.status).toBe(200);

    const buscaDepois = await request(app)
      .get(`/api/clientes/${criado.body.id}`)
      .set('Authorization', authHeader);
    expect(buscaDepois.status).toBe(404);
  });
});
