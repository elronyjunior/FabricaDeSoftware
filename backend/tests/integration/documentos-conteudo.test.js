const request = require('supertest');
const app = require('../../app');
const { pool, limparBanco } = require('../helpers/db');
const { gerarTokenTeste } = require('../helpers/auth');

describe('GET/PUT /api/documentos/:id/conteudo', () => {
  const token = gerarTokenTeste();
  const authHeader = `Bearer ${token}`;

  let projetoId;
  let documentoComConteudoId;
  let documentoSemConteudoId;

  const conteudoValido = {
    titulo: 'Documento de Teste',
    tipo_documento: 'Requisitos',
    versao: '1.0',
    metadata: { projeto: 'Projeto X', autor: 'IA', objetivo: 'Testar' },
    sumario_executivo: 'Resumo do documento.',
    secoes: [
      {
        titulo: '1. Introdução',
        nivel: 1,
        conteudo: 'Texto da introdução.',
        itens: ['Item A', 'Item B'],
        subsecoes: [
          {
            titulo: '1.1 Objetivo',
            nivel: 2,
            conteudo: 'Texto do objetivo.',
            itens: [],
            subsecoes: [],
          },
        ],
      },
    ],
    tabelas: [],
    conclusao: 'Texto de conclusão.',
  };

  beforeEach(async () => {
    await limparBanco();

    const usuario = await pool.query(
      `INSERT INTO usuarios (nome, email, senha, nivel) VALUES ($1, $2, $3, $4) RETURNING id`,
      ['Usuária Teste', 'usuaria@fabrica.com', 'senha123', 'USUARIO']
    );
    const cliente = await pool.query(
      `INSERT INTO clientes (razao_social, cnpj, email) VALUES ($1, $2, $3) RETURNING id`,
      ['Cliente Teste LTDA', '11.111.111/0001-11', 'contato@clienteteste.com']
    );
    const projeto = await pool.query(
      `INSERT INTO projetos (nome_projeto, cliente_id, criado_por_id) VALUES ($1, $2, $3) RETURNING id`,
      ['Projeto Teste', cliente.rows[0].id, usuario.rows[0].id]
    );
    projetoId = projeto.rows[0].id;

    const comConteudo = await pool.query(
      `INSERT INTO documentos (projeto_id, nome_do_arquivo, arquivo_url, tipo, conteudo_json)
       VALUES ($1, $2, $3, $4, $5) RETURNING id`,
      [projetoId, 'Doc Com Conteudo', 'https://docs.google.com/document/d/abc123/edit', 'Requisitos', JSON.stringify(conteudoValido)]
    );
    documentoComConteudoId = comConteudo.rows[0].id;

    const semConteudo = await pool.query(
      `INSERT INTO documentos (projeto_id, nome_do_arquivo, arquivo_url, tipo)
       VALUES ($1, $2, $3, $4) RETURNING id`,
      [projetoId, 'Doc Legado', 'https://docs.google.com/document/d/legado456/edit', 'Arquitetura']
    );
    documentoSemConteudoId = semConteudo.rows[0].id;
  });

  afterAll(async () => {
    await pool.end();
  });

  describe('GET', () => {
    it('rejeita sem token', async () => {
      const res = await request(app).get(`/api/documentos/${documentoComConteudoId}/conteudo`);
      expect(res.status).toBe(401);
    });

    it('retorna o conteúdo estruturado de um documento novo', async () => {
      const res = await request(app)
        .get(`/api/documentos/${documentoComConteudoId}/conteudo`)
        .set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body.conteudo_json.titulo).toBe('Documento de Teste');
      expect(res.body.conteudo_json.secoes).toHaveLength(1);
      expect(res.body.conteudo_json.secoes[0].subsecoes).toHaveLength(1);
    });

    it('retorna conteudo_json nulo para documento legado', async () => {
      const res = await request(app)
        .get(`/api/documentos/${documentoSemConteudoId}/conteudo`)
        .set('Authorization', authHeader);

      expect(res.status).toBe(200);
      expect(res.body.conteudo_json).toBeNull();
    });

    it('retorna 404 para documento inexistente', async () => {
      const res = await request(app).get('/api/documentos/999999/conteudo').set('Authorization', authHeader);
      expect(res.status).toBe(404);
    });
  });

  describe('PUT', () => {
    it('rejeita sem token', async () => {
      const res = await request(app)
        .put(`/api/documentos/${documentoComConteudoId}/conteudo`)
        .send({ conteudo_json: conteudoValido });

      expect(res.status).toBe(401);
    });

    it('salva um conteúdo editado válido', async () => {
      const editado = {
        ...conteudoValido,
        secoes: [
          { ...conteudoValido.secoes[0], titulo: '1. Introdução Editada', subsecoes: [] },
          { titulo: '2. Nova Seção', nivel: 1, conteudo: '', itens: [], subsecoes: [] },
        ],
      };

      const res = await request(app)
        .put(`/api/documentos/${documentoComConteudoId}/conteudo`)
        .set('Authorization', authHeader)
        .send({ conteudo_json: editado });

      expect(res.status).toBe(200);
      expect(res.body.conteudo_json.secoes).toHaveLength(2);
      expect(res.body.conteudo_json.secoes[0].titulo).toBe('1. Introdução Editada');

      const relido = await request(app)
        .get(`/api/documentos/${documentoComConteudoId}/conteudo`)
        .set('Authorization', authHeader);
      expect(relido.body.conteudo_json.secoes).toHaveLength(2);
    });

    it('rejeita nivel fora do intervalo permitido', async () => {
      const invalido = {
        ...conteudoValido,
        secoes: [{ titulo: 'X', nivel: 99, conteudo: '', itens: [], subsecoes: [] }],
      };

      const res = await request(app)
        .put(`/api/documentos/${documentoComConteudoId}/conteudo`)
        .set('Authorization', authHeader)
        .send({ conteudo_json: invalido });

      expect(res.status).toBe(400);
    });

    it('rejeita secoes que não é uma lista', async () => {
      const invalido = { ...conteudoValido, secoes: 'não é uma lista' };

      const res = await request(app)
        .put(`/api/documentos/${documentoComConteudoId}/conteudo`)
        .set('Authorization', authHeader)
        .send({ conteudo_json: invalido });

      expect(res.status).toBe(400);
    });

    it('rejeita itens com valores não-texto', async () => {
      const invalido = {
        ...conteudoValido,
        secoes: [{ titulo: 'X', nivel: 1, conteudo: '', itens: [123], subsecoes: [] }],
      };

      const res = await request(app)
        .put(`/api/documentos/${documentoComConteudoId}/conteudo`)
        .set('Authorization', authHeader)
        .send({ conteudo_json: invalido });

      expect(res.status).toBe(400);
    });

    it('retorna 404 para documento inexistente', async () => {
      const res = await request(app)
        .put('/api/documentos/999999/conteudo')
        .set('Authorization', authHeader)
        .send({ conteudo_json: conteudoValido });

      expect(res.status).toBe(404);
    });
  });
});
