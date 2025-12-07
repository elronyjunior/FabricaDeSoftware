const pool = require("../../db");

// Listar todas as relações recurso-projeto
exports.index = async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT rp.*, r.nome as recurso_nome, p.nome_projeto as projeto_nome " + // Corrigido p.nome para p.nome_projeto
      "FROM recursos_projeto rp " +
      "INNER JOIN recursos r ON rp.recurso_id = r.id " +
      "INNER JOIN projetos p ON rp.projeto_id = p.id"
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Salvar nova relação recurso-projeto
exports.store = async (req, res) => {
  try {
    // Ajustado para os campos reais do banco: custo_hora, data_alocacao, data_desalocacao
    const { recurso_id, projeto_id, custo_hora, data_alocacao, data_desalocacao } = req.body;
    
    const result = await pool.query(
      "INSERT INTO recursos_projeto (recurso_id, projeto_id, custo_hora, data_alocacao, data_desalocacao) VALUES ($1, $2, $3, $4, $5) RETURNING *",
      [recurso_id, projeto_id, custo_hora, data_alocacao, data_desalocacao]
    );
    res.status(201).json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Buscar relação específica (Necessita dos dois IDs)
exports.show = async (req, res) => {
  try {
    const { projetoId, recursoId } = req.params; // Recebe os dois IDs
    const result = await pool.query(
      "SELECT rp.*, r.nome as recurso_nome, p.nome_projeto as projeto_nome " +
      "FROM recursos_projeto rp " +
      "INNER JOIN recursos r ON rp.recurso_id = r.id " +
      "INNER JOIN projetos p ON rp.projeto_id = p.id " +
      "WHERE rp.projeto_id = $1 AND rp.recurso_id = $2",
      [projetoId, recursoId]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Relação recurso-projeto não encontrada" });
    }
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Atualizar relação
exports.update = async (req, res) => {
  try {
    const { projetoId, recursoId } = req.params;
    const { custo_hora, data_alocacao, data_desalocacao } = req.body;
    
    const result = await pool.query(
      "UPDATE recursos_projeto SET custo_hora=$1, data_alocacao=$2, data_desalocacao=$3 WHERE projeto_id=$4 AND recurso_id=$5 RETURNING *",
      [custo_hora, data_alocacao, data_desalocacao, projetoId, recursoId]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Relação recurso-projeto não encontrada" });
    }
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Deletar relação
exports.delete = async (req, res) => {
  try {
    const { projetoId, recursoId } = req.params;
    const result = await pool.query(
        "DELETE FROM recursos_projeto WHERE projeto_id = $1 AND recurso_id = $2 RETURNING *", 
        [projetoId, recursoId]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Relação recurso-projeto não encontrada" });
    }
    res.json({ message: "Relação recurso-projeto deletada com sucesso" });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Listar por projeto
exports.byProjeto = async (req, res) => {
  try {
    const { projetoId } = req.params;
    const result = await pool.query(
      "SELECT rp.*, r.nome as recurso_nome " +
      "FROM recursos_projeto rp " +
      "INNER JOIN recursos r ON rp.recurso_id = r.id " +
      "WHERE rp.projeto_id = $1",
      [projetoId]
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Listar por recurso
exports.byRecurso = async (req, res) => {
  try {
    const { recursoId } = req.params;
    const result = await pool.query(
      "SELECT rp.*, p.nome_projeto as projeto_nome " +
      "FROM recursos_projeto rp " +
      "INNER JOIN projetos p ON rp.projeto_id = p.id " +
      "WHERE rp.recurso_id = $1",
      [recursoId]
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};