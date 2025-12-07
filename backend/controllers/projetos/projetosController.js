const pool = require("../../db");

// Listar projetos (trazendo nomes de cliente e responsável)
exports.index = async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT p.*, c.razao_social as cliente_nome, u.nome as responsavel_nome " +
      "FROM projetos p " +
      "INNER JOIN clientes c ON p.cliente_id = c.id " +
      "LEFT JOIN usuarios u ON p.responsavel_id = u.id"
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Criar Projeto
exports.store = async (req, res) => {
  try {
    const { 
      nome_projeto, descricao, modelo_projeto, metodologia, escopo, 
      data_inicio, data_final_previsto, complexidade, orcamento_estimado, 
      cliente_id, responsavel_id, criado_por_id 
    } = req.body;

    const result = await pool.query(
      `INSERT INTO projetos 
      (nome_projeto, descricao, modelo_projeto, metodologia, escopo, data_inicio, data_final_previsto, complexidade, orcamento_estimado, cliente_id, responsavel_id, criado_por_id) 
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12) 
      RETURNING *`,
      [nome_projeto, descricao, modelo_projeto, metodologia, escopo, data_inicio, data_final_previsto, complexidade, orcamento_estimado, cliente_id, responsavel_id, criado_por_id]
    );
    res.status(201).json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Detalhes Completos (Pode ser expandido para trazer requisitos e tarefas no futuro)
exports.details = async (req, res) => {
    try {
      const { id } = req.params;
      const result = await pool.query(
        "SELECT p.*, c.razao_social, c.contato, u.nome as responsavel_nome " +
        "FROM projetos p " +
        "INNER JOIN clientes c ON p.cliente_id = c.id " +
        "LEFT JOIN usuarios u ON p.responsavel_id = u.id " +
        "WHERE p.id = $1",
        [id]
      );
      if (result.rows.length === 0) {
        return res.status(404).json({ message: "Projeto não encontrado" });
      }
      res.json(result.rows[0]);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
};

// Buscar por ID simples
exports.show = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query("SELECT * FROM projetos WHERE id = $1", [id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Projeto não encontrado" });
    }
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Atualizar Projeto
exports.update = async (req, res) => {
  try {
    const { id } = req.params;
    const { 
      nome_projeto, descricao, modelo_projeto, metodologia, escopo, 
      data_inicio, data_final_previsto, data_final, complexidade, orcamento_estimado, 
      cliente_id, responsavel_id 
    } = req.body;

    const result = await pool.query(
      `UPDATE projetos SET 
      nome_projeto=$1, descricao=$2, modelo_projeto=$3, metodologia=$4, escopo=$5, 
      data_inicio=$6, data_final_previsto=$7, data_final=$8, complexidade=$9, orcamento_estimado=$10, 
      cliente_id=$11, responsavel_id=$12 
      WHERE id=$13 RETURNING *`,
      [nome_projeto, descricao, modelo_projeto, metodologia, escopo, data_inicio, data_final_previsto, data_final, complexidade, orcamento_estimado, cliente_id, responsavel_id, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Projeto não encontrado" });
    }
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Deletar Projeto
exports.delete = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query("DELETE FROM projetos WHERE id = $1 RETURNING *", [id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Projeto não encontrado" });
    }
    res.json({ message: "Projeto deletado com sucesso" });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Listar Projetos por Cliente
exports.byCliente = async (req, res) => {
  try {
    const { clienteId } = req.params;
    const result = await pool.query("SELECT * FROM projetos WHERE cliente_id = $1", [clienteId]);
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};