const pool = require("../../db");

// Listar todas as relações contribuidor-projeto
exports.index = async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT cp.*, c.nome as contribuidor_nome, p.nome_projeto as projeto_nome " + // Ajustado para nome_projeto conforme SQL
      "FROM contribuidores_projeto cp " +
      "INNER JOIN contribuidores c ON cp.contribuidor_id = c.id " +
      "INNER JOIN projetos p ON cp.projeto_id = p.id"
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Salvar nova relação contribuidor-projeto
exports.store = async (req, res) => {
  try {
    // Removido 'papel' pois não existe no SQL
    const { contribuidor_id, projeto_id, data_inicio, data_fim } = req.body;
    
    const result = await pool.query(
      "INSERT INTO contribuidores_projeto (contribuidor_id, projeto_id, data_inicio, data_fim) VALUES ($1, $2, $3, $4) RETURNING *",
      [contribuidor_id, projeto_id, data_inicio, data_fim]
    );
    res.status(201).json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Buscar relação específica (Necessita dos dois IDs)
exports.show = async (req, res) => {
  try {
    const { projetoId, contribuidorId } = req.params; // Recebe os dois IDs
    const result = await pool.query(
      "SELECT cp.*, c.nome as contribuidor_nome, p.nome_projeto as projeto_nome " +
      "FROM contribuidores_projeto cp " +
      "INNER JOIN contribuidores c ON cp.contribuidor_id = c.id " +
      "INNER JOIN projetos p ON cp.projeto_id = p.id " +
      "WHERE cp.projeto_id = $1 AND cp.contribuidor_id = $2",
      [projetoId, contribuidorId]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Relação contribuidor-projeto não encontrada" });
    }
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Atualizar relação (Baseado na chave composta)
exports.update = async (req, res) => {
  try {
    const { projetoId, contribuidorId } = req.params;
    const { data_inicio, data_fim } = req.body; // Geralmente não alteramos as chaves (ids) no update, apenas os dados
    
    const result = await pool.query(
      "UPDATE contribuidores_projeto SET data_inicio=$1, data_fim=$2 WHERE projeto_id=$3 AND contribuidor_id=$4 RETURNING *",
      [data_inicio, data_fim, projetoId, contribuidorId]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Relação contribuidor-projeto não encontrada" });
    }
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Deletar relação
exports.delete = async (req, res) => {
  try {
    const { projetoId, contribuidorId } = req.params;
    const result = await pool.query(
        "DELETE FROM contribuidores_projeto WHERE projeto_id = $1 AND contribuidor_id = $2 RETURNING *", 
        [projetoId, contribuidorId]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Relação contribuidor-projeto não encontrada" });
    }
    res.json({ message: "Relação contribuidor-projeto deletada com sucesso" });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Listar por projeto
exports.byProjeto = async (req, res) => {
  try {
    const { projetoId } = req.params;
    const result = await pool.query(
      "SELECT cp.*, c.nome as contribuidor_nome " +
      "FROM contribuidores_projeto cp " +
      "INNER JOIN contribuidores c ON cp.contribuidor_id = c.id " +
      "WHERE cp.projeto_id = $1",
      [projetoId]
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Listar por contribuidor
exports.byContribuidor = async (req, res) => {
  try {
    const { contribuidorId } = req.params;
    const result = await pool.query(
      "SELECT cp.*, p.nome_projeto as projeto_nome " +
      "FROM contribuidores_projeto cp " +
      "INNER JOIN projetos p ON cp.projeto_id = p.id " +
      "WHERE cp.contribuidor_id = $1",
      [contribuidorId]
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};