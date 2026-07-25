const pool = require("../../db");
const googleDocsService = require("../../service/googleDocsService");
const { validarConteudoDocumento } = require("../../service/documentos/validarConteudoDocumento");

// Colunas usadas nas listagens: exclui conteudo_json (pode ser um JSON grande
// por documento) e expõe só se existe conteúdo editável, para não pesar o
// payload de uma tela que lista vários documentos ao mesmo tempo.
const COLUNAS_LISTA = `
  d.id, d.tipo, d.descricao, d.arquivo_url, d.nome_do_arquivo,
  d.data_criacao, d.data_aprovacao, d.projeto_id, d.aprovado_por_id,
  (d.conteudo_json IS NOT NULL) AS tem_conteudo_editavel
`;

exports.index = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT ${COLUNAS_LISTA}, p.nome_projeto FROM documentos d INNER JOIN projetos p ON d.projeto_id = p.id`
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.store = async (req, res) => {
  try {
    const { tipo, descricao, arquivo_url, nome_do_arquivo, projeto_id, aprovado_por_id } = req.body;
    const result = await pool.query(
      "INSERT INTO documentos (tipo, descricao, arquivo_url, nome_do_arquivo, projeto_id, aprovado_por_id) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *",
      [tipo, descricao, arquivo_url, nome_do_arquivo, projeto_id, aprovado_por_id]
    );
    res.status(201).json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.show = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query("SELECT * FROM documentos WHERE id = $1", [id]);
    if (result.rows.length === 0) return res.status(404).json({ message: "Documento não encontrado" });
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.update = async (req, res) => {
  try {
    const { id } = req.params;
    const { tipo, descricao, arquivo_url, nome_do_arquivo, aprovado_por_id } = req.body;
    const result = await pool.query(
      "UPDATE documentos SET tipo=$1, descricao=$2, arquivo_url=$3, nome_do_arquivo=$4, aprovado_por_id=$5 WHERE id=$6 RETURNING *",
      [tipo, descricao, arquivo_url, nome_do_arquivo, aprovado_por_id, id]
    );
    if (result.rows.length === 0) return res.status(404).json({ message: "Documento não encontrado" });
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.delete = async (req, res) => {
  try {
    const { id } = req.params;

    // 1. Buscar o documento para pegar o Link
    const result = await pool.query("SELECT * FROM documentos WHERE id = $1", [id]);
    const doc = result.rows[0];

    if (!doc) {
      return res.status(404).json({ message: "Documento não encontrado" });
    }

    // 2. Tentar extrair o ID do Google Drive a partir do Link
    // Links normais: https://docs.google.com/document/d/ID_DO_ARQUIVO/edit
    const match = doc.arquivo_url.match(/\/d\/([a-zA-Z0-9-_]+)/);
    
    if (match && match[1]) {
      const googleFileId = match[1];
      console.log(`Tentando apagar arquivo do Drive ID: ${googleFileId}`);
      await googleDocsService.deletarArquivo(googleFileId);
    }

    // 3. Apagar do Banco de Dados
    await pool.query("DELETE FROM documentos WHERE id = $1", [id]);

    res.json({ message: "Documento excluído do Banco e do Drive!" });

  } catch (error) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
};

exports.byProjeto = async (req, res) => {
  try {
    const { projetoId } = req.params;
    const result = await pool.query(
      `SELECT ${COLUNAS_LISTA} FROM documentos d WHERE d.projeto_id = $1`,
      [projetoId]
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Conteúdo estruturado (JSON) do documento, para o editor in-app.
exports.getConteudo = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query("SELECT conteudo_json FROM documentos WHERE id = $1", [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Documento não encontrado" });
    }

    res.json({ conteudo_json: result.rows[0].conteudo_json });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Salva o JSON editado pelo editor in-app. Endpoint dedicado (não reaproveita
// o "update" genérico) para não arriscar sobrescrever tipo/descricao/etc. com
// undefined, e porque isso vira o ponto natural para a futura rastreabilidade
// de alterações.
exports.salvarConteudo = async (req, res) => {
  try {
    const { id } = req.params;
    const { conteudo_json } = req.body;

    const erro = validarConteudoDocumento(conteudo_json);
    if (erro) {
      return res.status(400).json({ message: `Conteúdo inválido: ${erro}` });
    }

    const result = await pool.query(
      "UPDATE documentos SET conteudo_json = $1 WHERE id = $2 RETURNING id, conteudo_json",
      [JSON.stringify(conteudo_json), id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Documento não encontrado" });
    }

    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};