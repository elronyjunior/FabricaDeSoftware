const pool = require("../../db");

// Listar todas as relações
exports.index = async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT rp.*, r.descricao as requisito_descricao, p.nome_projeto " +
      "FROM requisitos_projeto rp " +
      "INNER JOIN requisitos r ON rp.requisito_id = r.id " +
      "INNER JOIN projetos p ON rp.projeto_id = p.id"
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Salvar nova relação (Associar requisito ao projeto)
exports.store = async (req, res) => {
  try {
    // Ajustado para campos do banco: codigo_requisito, prioridade, criado_por_id
    const { requisito_id, projeto_id, codigo_requisito, prioridade, criado_por_id } = req.body;
    
    const result = await pool.query(
      "INSERT INTO requisitos_projeto (requisito_id, projeto_id, codigo_requisito, prioridade, criado_por_id) VALUES ($1, $2, $3, $4, $5) RETURNING *",
      [requisito_id, projeto_id, codigo_requisito, prioridade, criado_por_id]
    );
    res.status(201).json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Buscar relação específica (Chave Composta)
exports.show = async (req, res) => {
  try {
    const { projetoId, requisitoId } = req.params;
    const result = await pool.query(
      "SELECT rp.*, r.descricao as requisito_descricao, p.nome_projeto " +
      "FROM requisitos_projeto rp " +
      "INNER JOIN requisitos r ON rp.requisito_id = r.id " +
      "INNER JOIN projetos p ON rp.projeto_id = p.id " +
      "WHERE rp.projeto_id = $1 AND rp.requisito_id = $2",
      [projetoId, requisitoId]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Relação requisito-projeto não encontrada" });
    }
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Atualizar relação (Ex: Mudar prioridade ou aprovar)
exports.update = async (req, res) => {
  try {
    const { projetoId, requisitoId } = req.params;
    const { codigo_requisito, prioridade, data_aprovacao, aprovado_por_id } = req.body;
    
    const result = await pool.query(
      "UPDATE requisitos_projeto SET codigo_requisito=$1, prioridade=$2, data_aprovacao=$3, aprovado_por_id=$4 WHERE projeto_id=$5 AND requisito_id=$6 RETURNING *",
      [codigo_requisito, prioridade, data_aprovacao, aprovado_por_id, projetoId, requisitoId]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Relação requisito-projeto não encontrada" });
    }
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Deletar relação
exports.delete = async (req, res) => {
  try {
    const { projetoId, requisitoId } = req.params;
    const result = await pool.query(
        "DELETE FROM requisitos_projeto WHERE projeto_id = $1 AND requisito_id = $2 RETURNING *", 
        [projetoId, requisitoId]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Relação requisito-projeto não encontrada" });
    }
    res.json({ message: "Requisito removido do projeto com sucesso" });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Listar por projeto
exports.byProjeto = async (req, res) => {
  try {
    const { projetoId } = req.params;
    const result = await pool.query(
      "SELECT rp.*, r.descricao, r.tipo " +
      "FROM requisitos_projeto rp " +
      "INNER JOIN requisitos r ON rp.requisito_id = r.id " +
      "WHERE rp.projeto_id = $1",
      [projetoId]
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Listar por requisito
exports.byRequisito = async (req, res) => {
  try {
    const { requisitoId } = req.params;
    const result = await pool.query(
      "SELECT rp.*, p.nome_projeto " +
      "FROM requisitos_projeto rp " +
      "INNER JOIN projetos p ON rp.projeto_id = p.id " +
      "WHERE rp.requisito_id = $1",
      [requisitoId]
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Listar por status não existe, mas existe por Prioridade
exports.byStatus = async (req, res) => { 
    // Mantive o nome da função para não quebrar seu front, mas a lógica agora busca por PRIORIDADE
    // Se preferir, renomeie para 'byPrioridade'
  try {
    const { status } = req.params; // Aqui 'status' vai receber 'alta', 'media', etc.
    const result = await pool.query(
      "SELECT rp.*, p.nome_projeto " +
      "FROM requisitos_projeto rp " +
      "INNER JOIN projetos p ON rp.projeto_id = p.id " +
      "WHERE rp.prioridade = $1",
      [status]
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};