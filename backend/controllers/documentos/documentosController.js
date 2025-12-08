const pool = require("../../db");

exports.index = async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT d.*, p.nome_projeto FROM documentos d INNER JOIN projetos p ON d.projeto_id = p.id"
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
    const result = await pool.query("DELETE FROM documentos WHERE id = $1 RETURNING *", [id]);
    if (result.rows.length === 0) return res.status(404).json({ message: "Documento não encontrado" });
    res.json({ message: "Documento deletado" });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.byProjeto = async (req, res) => {
  try {
    const { projetoId } = req.params;
    const result = await pool.query("SELECT * FROM documentos WHERE projeto_id = $1", [projetoId]);
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};