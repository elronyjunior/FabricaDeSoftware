const OpenAI = require("openai");
const pool = require("../../db");
// Importando o service corretamente (note o ../../service no singular)
const googleDocsService = require("../../service/googleDocsService");

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY, 
});

// 1. Gerar Requisitos (Função Antiga)
exports.gerarRequisitos = async (req, res) => {
  try {
    const { escopo, nomeProjeto } = req.body;
    const prompt = `
      Você é um analista de requisitos sênior.
      Com base no seguinte projeto: "${nomeProjeto}" e escopo: "${escopo}".
      Gere uma lista de no minimo 10 requisitos (misture funcionais e não funcionais).
      IMPORTANTE: Responda APENAS com um JSON válido no seguinte formato, sem textos adicionais, sem markdown (\`\`\`json):
        [
            {
            "titulo": "Nome curto do requisito",
            "descricao": "Descrição detalhada",
            "tipo": "Funcional" ou "Não Funcional",
            "prioridade": "Alta", "Média" ou "Baixa"
            }
        ]
    `;
    const completion = await openai.chat.completions.create({
      model: "gpt-3.5-turbo",
      messages: [{ role: "user", content: prompt }],
      temperature: 0.7,
    });
    let content = completion.choices[0].message.content.replace(/```json/g, '').replace(/```/g, '').trim();
    res.json(JSON.parse(content));
  } catch (error) {
    console.error("Erro IA Requisitos:", error);
    res.status(500).json({ error: "Falha na IA" });
  }
};

// 2. Estimar Orçamento (Função Antiga)
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
      - Equipe: ${equipe.length} pessoas (${equipe.map(e => e.papel).join(', ')})
      - Recursos: ${recursos.length} itens
      
      TAREFA:
      1. Estime o custo total (float) considerando mercado de TI Brasil.
      2. Defina a complexidade técnica entre: 'baixa', 'media', ou 'alta'.
      
      SAÍDA OBRIGATÓRIA (JSON puro):
      {
        "orcamento_estimado": 0.00,
        "complexidade": "string"
      }
    `;

    const completion = await openai.chat.completions.create({
      model: "gpt-3.5-turbo",
      messages: [{ role: "user", content: prompt }],
      temperature: 0.3,
    });

    let content = completion.choices[0].message.content.replace(/```json/g, '').replace(/```/g, '').trim();
    const resultado = JSON.parse(content);

    res.json({ 
      orcamento_estimado: resultado.orcamento_estimado || 0.0,
      complexidade: resultado.complexidade || 'media'
    });

  } catch (error) {
    console.error("Erro IA Orçamento:", error);
    res.status(500).json({ error: "Falha na IA" });
  }
};

// 3. Gerar Documento e Salvar no Docs (VERSÃO CORRIGIDA FINAL)
exports.gerarDocumentoIA = async (req, res) => {
  try {
    const { projetoId, tipoDocumento, tituloDocumento, descricaoExtra } = req.body;

    // A. Busca APENAS o projeto (Removemos o cliente para não dar erro de coluna)
    const projetoQuery = await pool.query(`
      SELECT * FROM projetos WHERE id = $1
    `, [projetoId]);

    const projeto = projetoQuery.rows[0];
    
    if (!projeto) {
      return res.status(404).json({ message: "Projeto não encontrado" });
    }

    // B. Monta o Prompt
    let promptContexto = `
      Você é um Arquiteto de Software Sênior.
      Gere um documento técnico detalhado do tipo: **${tipoDocumento}**.
      
      DADOS DO PROJETO:
      - Nome: ${projeto.nome_projeto}
      - Descrição: ${projeto.descricao || 'Sem descrição'}
      - Modelo: ${projeto.modelo_projeto || 'Padrão'}
      
      INSTRUÇÕES EXTRAS: ${descricaoExtra || 'Siga as melhores práticas.'}
      
      Gere o conteúdo em texto corrido e bem estruturado.
    `;

    // C. Chama a IA
    console.log("🤖 Gerando conteúdo com IA...");
    const completion = await openai.chat.completions.create({
      model: "gpt-3.5-turbo-16k",
      messages: [{ role: "user", content: promptContexto }],
      temperature: 0.5,
    });

    const conteudoGerado = completion.choices[0].message.content;

    // D. Cria o Doc no Google Drive
    console.log("📄 Criando Google Doc...");
    const nomeArquivo = `${tituloDocumento} - ${projeto.nome_projeto}`;
    const docInfo = await googleDocsService.criarDocComConteudo(nomeArquivo, conteudoGerado);

    // E. Salva no Banco (AGORA COM OS NOMES CERTOS DA SUA TABELA)
    // Mapeamento:
    // nome -> nome_do_arquivo
    // link -> arquivo_url
    // Adicionei também 'descricao' fixo como "Gerado via IA"
    const insertDoc = await pool.query(`
      INSERT INTO documentos (
        projeto_id, 
        nome_do_arquivo, 
        arquivo_url, 
        tipo, 
        descricao,
        data_criacao
      )
      VALUES ($1, $2, $3, $4, $5, NOW())
      RETURNING *
    `, [
      projetoId,             // $1
      tituloDocumento,       // $2 (nome_do_arquivo)
      docInfo.link,          // $3 (arquivo_url)
      tipoDocumento,         // $4 (tipo)
      'Documento gerado automaticamente pela IA', // $5 (descricao)
    ]);

    console.log("✅ Documento gerado e salvo na tabela correta!");
    
    res.json({
      message: "Documento gerado com sucesso!",
      documento: insertDoc.rows[0],
      googleDocId: docInfo.id
    });

  } catch (error) {
    console.error("Erro ao gerar documento IA:", error);
    res.status(500).json({ error: error.message });
  }

  exports.deletarArquivo = async (fileId) => {
  try {
    const client = getAuthClient();
    const drive = google.drive({ version: 'v3', auth: client });

    await drive.files.delete({
      fileId: fileId,
    });
    console.log(`🗑️ Arquivo ${fileId} deletado do Drive.`);
  } catch (error) {
    console.error("Erro ao deletar do Drive:", error);
    // Não lançamos erro aqui para não impedir de apagar do banco se o arquivo já sumiu
  }
};
};