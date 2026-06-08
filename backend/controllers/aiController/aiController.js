const pool = require('../../db');
const googleDocsService = require('../../service/googleDocsService');
const { chatJson } = require('../../service/ai/openaiService');
const {
  buildRequisitosPrompt,
  buildDocumentoPrompt,
  formatRequisitoForApi,
} = require('../../service/ai/aiPrompts');

async function buscarRequisitosDoProjeto(projetoId) {
  const result = await pool.query(
    `SELECT r.titulo, r.descricao, r.tipo, r.prioridade
     FROM requisitos_projeto rp
     JOIN requisitos r ON r.id = rp.requisito_id
     WHERE rp.projeto_id = $1
     ORDER BY r.id`,
    [projetoId]
  );
  return result.rows;
}

exports.gerarRequisitos = async (req, res) => {
  try {
    const { escopo, nomeProjeto } = req.body;

    if (!escopo?.trim()) {
      return res.status(400).json({ error: 'Escopo é obrigatório.' });
    }

    const prompt = buildRequisitosPrompt({
      nomeProjeto: nomeProjeto || 'Novo Projeto',
      escopo: escopo.trim(),
    });

    const data = await chatJson({
      system: prompt.system,
      user: prompt.user,
      temperature: prompt.temperature,
      maxTokens: 8000,
    });

    const requisitos = (data.requisitos || []).map(formatRequisitoForApi);
    res.json(requisitos);
  } catch (error) {
    console.error('Erro IA Requisitos:', error);
    res.status(500).json({ error: error.message || 'Falha na IA ao gerar requisitos' });
  }
};

exports.estimarOrcamento = async (req, res) => {
  try {
    const { nome, descricao, escopo, equipe, recursos, duracao_dias } = req.body;

    const prompt = `
      Atue como um Gerente de Projetos Sênior.
      Analise este projeto para estimar Orçamento e Complexidade.
      
      DADOS:
      - Projeto: ${nome}
      - Descrição: ${descricao}
      - Escopo Completo: ${escopo}
      - Duração: ${duracao_dias} dias
      - Equipe: ${equipe.length} pessoas (${equipe.map((e) => e.papel).join(', ')})
      - Recursos: ${recursos.length} itens
      
      Retorne JSON:
      {
        "orcamento_estimado": 0.00,
        "complexidade": "baixa, media ou alta"
      }
    `;

    const data = await chatJson({
      system: 'Responda apenas com JSON válido em português.',
      user: prompt,
      temperature: 0.3,
      maxTokens: 500,
    });

    res.json({
      orcamento_estimado: data.orcamento_estimado || 0.0,
      complexidade: data.complexidade || 'media',
    });
  } catch (error) {
    console.error('Erro IA Orçamento:', error);
    res.status(500).json({ error: 'Falha na IA' });
  }
};

exports.gerarDocumentoIA = async (req, res) => {
  try {
    const { projetoId, tipoDocumento, tituloDocumento, descricaoExtra } = req.body;

    if (!projetoId || !tipoDocumento || !tituloDocumento?.trim()) {
      return res.status(400).json({
        message: 'projetoId, tipoDocumento e tituloDocumento são obrigatórios.',
      });
    }

    const projetoQuery = await pool.query('SELECT * FROM projetos WHERE id = $1', [projetoId]);
    const projeto = projetoQuery.rows[0];

    if (!projeto) {
      return res.status(404).json({ message: 'Projeto não encontrado' });
    }

    const requisitos = await buscarRequisitosDoProjeto(projetoId);

    const prompt = buildDocumentoPrompt({
      projeto,
      tipoDocumento,
      tituloDocumento: tituloDocumento.trim(),
      descricaoExtra,
      requisitos,
    });

    console.log('🤖 Gerando documento JSON com IA...');
    const documentoJson = await chatJson({
      system: prompt.system,
      user: prompt.user,
      temperature: prompt.temperature,
      maxTokens: prompt.maxTokens,
    });

    documentoJson.titulo = documentoJson.titulo || tituloDocumento;
    documentoJson.tipo_documento = documentoJson.tipo_documento || tipoDocumento;
    documentoJson.metadata = {
      ...(documentoJson.metadata || {}),
      projeto: projeto.nome_projeto,
    };

    console.log('📄 Formatando Google Doc a partir do JSON...');
    const nomeArquivo = `${tituloDocumento} - ${projeto.nome_projeto}`;
    const docInfo = await googleDocsService.criarDocFromJson(nomeArquivo, documentoJson);

    const insertDoc = await pool.query(
      `INSERT INTO documentos (
        projeto_id, nome_do_arquivo, arquivo_url, tipo, descricao, data_criacao
      )
      VALUES ($1, $2, $3, $4, $5, NOW())
      RETURNING *`,
      [
        projetoId,
        tituloDocumento,
        docInfo.link,
        tipoDocumento,
        'Documento gerado automaticamente pela IA (JSON estruturado)',
      ]
    );

    console.log('✅ Documento gerado e salvo!');

    res.json({
      message: 'Documento gerado com sucesso!',
      documento: insertDoc.rows[0],
      googleDocId: docInfo.id,
    });
  } catch (error) {
    console.error('Erro ao gerar documento IA:', error);
    res.status(500).json({ error: error.message });
  }
};
