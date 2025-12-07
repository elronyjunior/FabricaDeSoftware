const pool = require("../../db");

// Listar todos os requisitos
exports.index = async (req, res) => {
  try {
    const result = await pool.query("SELECT * FROM requisitos");
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Salvar novo requisito
exports.store = async (req, res) => {
  try {
    // Ajustado: Removemos 'nome' e 'prioridade'. Adicionamos 'observacoes'.
    const { tipo, descricao, observacoes } = req.body;
    
    const result = await pool.query(
      "INSERT INTO requisitos (tipo, descricao, observacoes) VALUES ($1, $2, $3) RETURNING *",
      [tipo, descricao, observacoes]
    );
    res.status(201).json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Buscar requisito por ID
exports.show = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query("SELECT * FROM requisitos WHERE id = $1", [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Requisito não encontrado" });
    }
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Atualizar requisito
exports.update = async (req, res) => {
  try {
    const { id } = req.params;
    // Ajustado para os campos corretos
    const { tipo, descricao, observacoes } = req.body;
    
    const result = await pool.query(
      "UPDATE requisitos SET tipo=$1, descricao=$2, observacoes=$3 WHERE id=$4 RETURNING *",
      [tipo, descricao, observacoes, id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Requisito não encontrado" });
    }
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Deletar requisito
exports.delete = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query("DELETE FROM requisitos WHERE id = $1 RETURNING *", [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Requisito não encontrado" });
    }
    res.json({ message: "Requisito deletado com sucesso" });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Listar quais projetos estão usando este requisito (Isso funciona pois faz JOIN)
exports.projetos = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(
      "SELECT p.nome_projeto, p.id " + // Trazendo o nome correto
      "FROM projetos p " +
      "INNER JOIN requisitos_projeto rp ON p.id = rp.projeto_id " +
      "WHERE rp.requisito_id = $1",
      [id]
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Listar por tipo
exports.byTipo = async (req, res) => {
  try {
    const { tipo } = req.params;
    // Usando ILIKE para busca flexível
    const result = await pool.query(
      "SELECT * FROM requisitos WHERE tipo ILIKE $1",
      [tipo]
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};