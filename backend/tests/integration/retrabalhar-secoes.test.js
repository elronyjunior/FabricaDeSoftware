const request = require('supertest');
const app = require('../../app');
const { gerarTokenTeste } = require('../helpers/auth');

// Testa só as validações e a autenticação da rota — a chamada real à IA é
// verificada manualmente (não faz sentido gastar chamadas reais e pagas
// numa suíte de CI, nem mockar o SDK inteiro pra um teste de contrato).
describe('POST /api/ai/retrabalhar-secoes', () => {
  const token = gerarTokenTeste();
  const authHeader = `Bearer ${token}`;

  const documentoValido = {
    titulo: 'Doc',
    secoes: [
      { titulo: '1. Intro', nivel: 1, conteudo: 'Texto', itens: [], subsecoes: [] },
      { titulo: '2. Escopo', nivel: 1, conteudo: 'Texto', itens: [], subsecoes: [] },
    ],
  };

  it('rejeita sem token', async () => {
    const res = await request(app)
      .post('/api/ai/retrabalhar-secoes')
      .send({ documento: documentoValido, caminhos: [[0]], instrucao: '' });

    expect(res.status).toBe(401);
  });

  it('rejeita quando documento está ausente', async () => {
    const res = await request(app)
      .post('/api/ai/retrabalhar-secoes')
      .set('Authorization', authHeader)
      .send({ caminhos: [[0]], instrucao: '' });

    expect(res.status).toBe(400);
  });

  it('rejeita quando caminhos está ausente ou vazio', async () => {
    const res = await request(app)
      .post('/api/ai/retrabalhar-secoes')
      .set('Authorization', authHeader)
      .send({ documento: documentoValido, caminhos: [], instrucao: '' });

    expect(res.status).toBe(400);
  });

  it('rejeita um caminho com índice negativo ou não-inteiro', async () => {
    const res = await request(app)
      .post('/api/ai/retrabalhar-secoes')
      .set('Authorization', authHeader)
      .send({ documento: documentoValido, caminhos: [[-1]], instrucao: '' });

    expect(res.status).toBe(400);
  });

  it('rejeita um caminho que não existe no documento', async () => {
    const res = await request(app)
      .post('/api/ai/retrabalhar-secoes')
      .set('Authorization', authHeader)
      .send({ documento: documentoValido, caminhos: [[99]], instrucao: '' });

    expect(res.status).toBe(400);
  });

  it('rejeita quando o job de status não existe', async () => {
    const res = await request(app)
      .get('/api/ai/retrabalhar-secoes/status/id-que-nao-existe')
      .set('Authorization', authHeader);

    expect(res.status).toBe(404);
  });
});
