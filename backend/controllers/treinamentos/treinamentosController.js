const pool = require("../../db");
const googleSheetsService = require("../../service/googleSheetsService");

// ===================================================================================
// CRUD PRINCIPAL (BANCO DE DADOS)
// ===================================================================================

// 1. Listar todos os treinamentos
exports.index = async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT t.*, p.nome_projeto FROM treinamentos t INNER JOIN projetos p ON t.projeto_id = p.id ORDER BY t.id DESC"
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// 2. Salvar Treinamento (Com Transação + Criação Automática da Planilha)
exports.store = async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const { nome, descricao, tipo_treinamento, data_inicio, data_termino, duracao_horas, instrutor, projeto_id } = req.body;

    // A. Cria o registro do treinamento
    const treinamentoResult = await client.query(
      `INSERT INTO treinamentos 
      (nome, descricao, tipo_treinamento, data_inicio, data_termino, duracao_horas, instrutor, projeto_id) 
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8) 
      RETURNING id, nome`,
      [nome, descricao, tipo_treinamento, data_inicio, data_termino, duracao_horas, instrutor, projeto_id]
    );
    
    const novoTreinamento = treinamentoResult.rows[0];
    const treinamentoId = novoTreinamento.id;

    // B. Cria a Planilha no Google Drive
    console.log("📊 Criando planilha de presença...");
    const sheetInfo = await googleSheetsService.criarPlanilhaPresenca(nome);

    // C. Salva o Documento no Banco
    const docResult = await client.query(
      `INSERT INTO documentos 
      (projeto_id, nome_do_arquivo, arquivo_url, tipo, descricao, data_criacao) 
      VALUES ($1, $2, $3, $4, $5, NOW()) 
      RETURNING id`,
      [
        projeto_id, 
        `Lista de Presença - ${nome}`, 
        sheetInfo.link, 
        'Lista de Presença', 
        `Gerado automaticamente para o treinamento #${treinamentoId}`
      ]
    );
    const documentoId = docResult.rows[0].id;

    // D. Vincula o Documento ao Treinamento
    await client.query(
      "UPDATE treinamentos SET documento_id = $1 WHERE id = $2",
      [documentoId, treinamentoId]
    );

    await client.query('COMMIT');
    res.status(201).json(novoTreinamento);

  } catch (error) {
    await client.query('ROLLBACK');
    console.error("Erro ao criar treinamento:", error);
    res.status(500).json({ error: error.message });
  } finally {
    client.release();
  }
};

// 3. Buscar treinamento por ID
exports.show = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query("SELECT t.*, p.nome_projeto FROM treinamentos t INNER JOIN projetos p ON t.projeto_id = p.id WHERE t.id = $1", [id]);
    if (result.rows.length === 0) return res.status(404).json({ message: "Treinamento não encontrado" });
    res.json(result.rows[0]);
  } catch (error) { res.status(500).json({ error: error.message }); }
};

// 4. Atualizar treinamento
exports.update = async (req, res) => {
  try {
    const { id } = req.params;
    const { nome, descricao, tipo_treinamento, data_inicio, data_termino, duracao_horas, instrutor, projeto_id } = req.body;
    const result = await pool.query(
      "UPDATE treinamentos SET nome=$1, descricao=$2, tipo_treinamento=$3, data_inicio=$4, data_termino=$5, duracao_horas=$6, instrutor=$7, projeto_id=$8 WHERE id=$9 RETURNING *",
      [nome, descricao, tipo_treinamento, data_inicio, data_termino, duracao_horas, instrutor, projeto_id, id]
    );
    if (result.rows.length === 0) return res.status(404).json({ message: "Treinamento não encontrado" });
    res.json(result.rows[0]);
  } catch (error) { res.status(500).json({ error: error.message }); }
};

// 5. Deletar treinamento (CORRIGIDO: ORDEM DE EXCLUSÃO)
exports.delete = async (req, res) => {
  const client = await pool.connect();
  try {
    const { id } = req.params;
    await client.query('BEGIN');

    // 1. Descobrir qual é o documento antes de apagar o treinamento
    const treinoQuery = await client.query("SELECT documento_id FROM treinamentos WHERE id = $1", [id]);
    
    if (treinoQuery.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ message: "Treinamento não encontrado" });
    }

    const documentoId = treinoQuery.rows[0].documento_id;

    // 2. Apagar o TREINAMENTO PRIMEIRO (Para liberar a chave estrangeira)
    await client.query("DELETE FROM treinamentos WHERE id = $1", [id]);

    // 3. Agora sim, apagar o Documento e o Arquivo do Drive
    if (documentoId) {
      // Pega URL para apagar do Drive
      const docQuery = await client.query("SELECT arquivo_url FROM documentos WHERE id = $1", [documentoId]);
      
      if (docQuery.rows.length > 0) {
        const url = docQuery.rows[0].arquivo_url;
        const match = url.match(/\/d\/([a-zA-Z0-9-_]+)/);
        
        if (match && match[1] && googleSheetsService.deletarArquivo) {
          console.log(`🗑️ Apagando planilha do Drive: ${match[1]}`);
          // Apaga do Drive (catch para não travar se já não existir)
          await googleSheetsService.deletarArquivo(match[1]).catch(e => console.log("Aviso: Erro ao apagar do Drive (ignorado)."));
        }
      }
      
      // Apaga o registro da tabela documentos
      await client.query("DELETE FROM documentos WHERE id = $1", [documentoId]);
    }

    await client.query('COMMIT');
    res.json({ message: "Treinamento e planilha excluídos com sucesso" });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error("Erro ao deletar treinamento:", error);
    res.status(500).json({ error: error.message });
  } finally {
    client.release();
  }
};

// 6. Buscar por instrutor
exports.byInstrutor = async (req, res) => {
  try {
    const { nomeInstrutor } = req.params;
    const result = await pool.query("SELECT * FROM treinamentos WHERE instrutor ILIKE $1", [`%${nomeInstrutor}%`]);
    res.json(result.rows);
  } catch (error) { res.status(500).json({ error: error.message }); }
};


// ===================================================================================
// INTEGRAÇÃO GOOGLE SHEETS
// ===================================================================================

// Ler Dados da Planilha
exports.getPresenca = async (req, res) => {
  try {
    const { id } = req.params;
    
    // Busca a URL via JOIN
    const result = await pool.query(
      `SELECT d.arquivo_url FROM treinamentos t 
       INNER JOIN documentos d ON t.documento_id = d.id 
       WHERE t.id = $1`, [id]
    );

    if (result.rows.length === 0) return res.status(404).json({ message: "Planilha não encontrada." });

    const link = result.rows[0].arquivo_url;
    const match = link.match(/\/d\/([a-zA-Z0-9-_]+)/);
    
    if (!match || !match[1]) return res.status(400).json({ message: "Link inválido." });
    
    const dados = await googleSheetsService.lerPlanilhaCompleta(match[1]);
    res.json({ sheetId: match[1], ...dados });

  } catch (error) { res.status(500).json({ error: error.message }); }
};

// Adicionar Aluno (Linha)
exports.addAlunoSheet = async (req, res) => {
  try {
    const { sheetId, nome, email } = req.body;
    await googleSheetsService.adicionarAluno(sheetId, nome, email);
    res.json({ message: "Aluno adicionado" });
  } catch (error) { res.status(500).json({ error: error.message }); }
};

// Adicionar Dia (Coluna)
exports.addDiaSheet = async (req, res) => {
  try {
    const { sheetId, data } = req.body;
    await googleSheetsService.adicionarDia(sheetId, data);
    res.json({ message: "Dia adicionado" });
  } catch (error) { res.status(500).json({ error: error.message }); }
};

// Salvar Presenças em Lote
exports.salvarLote = async (req, res) => {
  try {
    const { sheetId, mudancas } = req.body;
    await googleSheetsService.salvarPresencasLote(sheetId, mudancas);
    res.json({ message: "Salvo com sucesso" });
  } catch (error) { res.status(500).json({ error: error.message }); }
};

// Remover Aluno (DELETE via Query Params)
exports.removerAlunoSheet = async (req, res) => {
  try {
    const { sheetId, rowIndex } = req.query; // Importante: req.query
    if (!sheetId || !rowIndex) return res.status(400).json({ message: "Parâmetros inválidos" });
    
    await googleSheetsService.removerAluno(sheetId, rowIndex);
    res.json({ message: "Aluno removido" });
  } catch (error) { res.status(500).json({ error: error.message }); }
};

// Remover Dia (DELETE via Query Params)
exports.removerDiaSheet = async (req, res) => {
  try {
    const { sheetId, diaIndex } = req.query; // Importante: req.query
    if (!sheetId || diaIndex === undefined) return res.status(400).json({ message: "Parâmetros inválidos" });

    await googleSheetsService.removerDia(sheetId, diaIndex);
    res.json({ message: "Dia removido" });
  } catch (error) { res.status(500).json({ error: error.message }); }
};