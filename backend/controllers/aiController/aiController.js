const pool = require('../../db');
const googleDocsService = require('../../service/googleDocsService');
const { chatJson } = require('../../service/ai/claudeService');
const { createJob, updateJob, getJob } = require('../../service/ai/jobStore');
const { validarSecao } = require('../../service/documentos/validarConteudoDocumento');
const {
  buildRequisitosPrompt,
  buildDocumentoPrompt,
  formatRequisitoForApi,
  buildRetrabalhoPrompt,
  buscarSecaoPorCaminho,
} = require('../../service/ai/aiPrompts');

function montarTituloRequisito(requisito) {
  const codigo = requisito.codigo_requisito || '';
  const descricao = (requisito.descricao || '').trim();
  const trechoAntesDoisPontos = descricao.split(':')[0]?.trim();
  const tituloBase =
    trechoAntesDoisPontos && trechoAntesDoisPontos.length <= 90
      ? trechoAntesDoisPontos
      : 'Requisito';

  return codigo ? `${codigo} ${tituloBase}` : tituloBase;
}

function montarDescricaoRequisito(requisito) {
  return [requisito.descricao, requisito.observacoes && `Observacoes: ${requisito.observacoes}`]
    .filter(Boolean)
    .join('\n');
}

async function buscarRequisitosDoProjeto(projetoId) {
  const result = await pool.query(
    `SELECT
       r.id,
       rp.codigo_requisito,
       r.descricao,
       r.tipo,
       rp.prioridade,
       r.observacoes
     FROM requisitos_projeto rp
     JOIN requisitos r ON r.id = rp.requisito_id
     WHERE rp.projeto_id = $1
     ORDER BY rp.codigo_requisito NULLS LAST, r.id`,
    [projetoId]
  );

  return result.rows.map((requisito) => ({
    codigo: requisito.codigo_requisito,
    titulo: montarTituloRequisito(requisito),
    descricao: montarDescricaoRequisito(requisito),
    tipo: requisito.tipo || 'Funcional',
    prioridade: requisito.prioridade || 'Media',
  }));
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
    const { nome, descricao, escopo, duracao_dias } = req.body;
    const equipe = Array.isArray(req.body.equipe) ? req.body.equipe : [];
    const recursos = Array.isArray(req.body.recursos) ? req.body.recursos : [];

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

    const orcamentoNumerico = Number(data.orcamento_estimado);

    res.json({
      orcamento_estimado: Number.isFinite(orcamentoNumerico) ? orcamentoNumerico : 0.0,
      complexidade: data.complexidade || 'media',
    });
  } catch (error) {
    console.error('Erro IA Orçamento:', error);
    res.status(500).json({ error: 'Falha na IA' });
  }
};

async function processarGeracaoDocumento(jobId, { projetoId, tipoDocumento, tituloDocumento, descricaoExtra }) {
  updateJob(jobId, { stage: 'buscando_dados_do_projeto' });

  const projetoQuery = await pool.query('SELECT * FROM projetos WHERE id = $1', [projetoId]);
  const projeto = projetoQuery.rows[0];

  if (!projeto) {
    updateJob(jobId, { status: 'error', error: 'Projeto não encontrado' });
    return;
  }

  const requisitos = await buscarRequisitosDoProjeto(projetoId);

  const prompt = buildDocumentoPrompt({
    projeto,
    tipoDocumento,
    tituloDocumento,
    descricaoExtra,
    requisitos,
  });

  updateJob(jobId, { stage: 'gerando_conteudo_com_ia' });
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

  updateJob(jobId, { stage: 'criando_documento_no_google_docs' });
  console.log('📄 Formatando Google Doc a partir do JSON...');
  const nomeArquivo = `${tituloDocumento} - ${projeto.nome_projeto}`;
  const docInfo = await googleDocsService.criarDocFromJson(nomeArquivo, documentoJson);

  const insertDoc = await pool.query(
    `INSERT INTO documentos (
      projeto_id, nome_do_arquivo, arquivo_url, tipo, descricao, data_criacao, conteudo_json
    )
    VALUES ($1, $2, $3, $4, $5, NOW(), $6)
    RETURNING *`,
    [
      projetoId,
      tituloDocumento,
      docInfo.link,
      tipoDocumento,
      'Documento gerado automaticamente pela IA (JSON estruturado)',
      JSON.stringify(documentoJson),
    ]
  );

  console.log('✅ Documento gerado e salvo!');

  updateJob(jobId, {
    status: 'done',
    result: {
      message: 'Documento gerado com sucesso!',
      documento: insertDoc.rows[0],
      googleDocId: docInfo.id,
    },
  });
}

exports.gerarDocumentoIA = async (req, res) => {
  const { projetoId, tipoDocumento, tituloDocumento, descricaoExtra } = req.body;

  if (!projetoId || !tipoDocumento || !tituloDocumento?.trim()) {
    return res.status(400).json({
      message: 'projetoId, tipoDocumento e tituloDocumento são obrigatórios.',
    });
  }

  const jobId = createJob();
  res.status(202).json({ jobId, status: 'processing' });

  processarGeracaoDocumento(jobId, {
    projetoId,
    tipoDocumento,
    tituloDocumento: tituloDocumento.trim(),
    descricaoExtra,
  }).catch((error) => {
    console.error('Erro ao gerar documento IA:', error);
    updateJob(jobId, { status: 'error', error: error.message || 'Falha na IA ao gerar documento' });
  });
};

// Reescreve com IA apenas a(s) seção(ões) indicadas por "caminho" (índice do
// array em cada nível de secoes/subsecoes), usando o resto do documento só
// como contexto estrutural (títulos, não o texto completo) — o custo/tempo
// dessa chamada escala com o que foi selecionado, não com o tamanho do
// documento inteiro. Não toca no banco: opera sobre o JSON que o cliente já
// tem em memória (inclusive edições ainda não salvas) e devolve só as
// seções reescritas; salvar continua sendo uma ação separada do usuário.
async function processarRetrabalhoSecoes(jobId, { documento, caminhos, instrucao }) {
  updateJob(jobId, { stage: 'gerando_reescrita_com_ia' });

  const prompt = buildRetrabalhoPrompt({ documento, caminhos, instrucao });

  const data = await chatJson({
    system: prompt.system,
    user: prompt.user,
    temperature: prompt.temperature,
    maxTokens: prompt.maxTokens,
  });

  const secoesRetornadas = Array.isArray(data.secoes) ? data.secoes : [];

  for (const item of secoesRetornadas) {
    const erro = validarSecao(item.secao, `secoes[caminho=${JSON.stringify(item.caminho)}]`);
    if (erro) {
      updateJob(jobId, { status: 'error', error: `A IA retornou uma seção inválida: ${erro}` });
      return;
    }
  }

  updateJob(jobId, {
    status: 'done',
    result: { secoes: secoesRetornadas },
  });
}

exports.retrabalharSecoes = async (req, res) => {
  const { documento, caminhos, instrucao } = req.body;

  if (!documento || !Array.isArray(documento.secoes)) {
    return res.status(400).json({ message: 'documento (com secoes) é obrigatório.' });
  }

  if (!Array.isArray(caminhos) || caminhos.length === 0) {
    return res.status(400).json({ message: 'Selecione ao menos uma seção para retrabalhar.' });
  }

  for (const caminho of caminhos) {
    if (!Array.isArray(caminho) || caminho.some((indice) => !Number.isInteger(indice) || indice < 0)) {
      return res.status(400).json({ message: `Caminho inválido: ${JSON.stringify(caminho)}` });
    }
    if (!buscarSecaoPorCaminho(documento.secoes, caminho)) {
      return res.status(400).json({ message: `Seção não encontrada no caminho ${JSON.stringify(caminho)}` });
    }
  }

  const jobId = createJob();
  res.status(202).json({ jobId, status: 'processing' });

  processarRetrabalhoSecoes(jobId, { documento, caminhos, instrucao }).catch((error) => {
    console.error('Erro ao retrabalhar seções com IA:', error);
    updateJob(jobId, { status: 'error', error: error.message || 'Falha na IA ao retrabalhar seções' });
  });
};

// Genérico: consulta o status de qualquer job de IA (geração de documento ou
// retrabalho de seções), já que o jobStore não distingue a origem.
exports.statusJob = (req, res) => {
  const job = getJob(req.params.jobId);

  if (!job) {
    return res.status(404).json({ error: 'Job não encontrado ou expirado' });
  }

  res.json(job);
};
