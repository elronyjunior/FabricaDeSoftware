const pool = require("../../db");

// Listar todas as associações (com nomes para facilitar leitura)
exports.index = async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT tp.*, t.nome as tecnologia_nome, p.nome_projeto as projeto_nome " +
      "FROM tecnologias_projeto tp " +
      "INNER JOIN tecnologias t ON tp.tecnologia_id = t.id " +
      "INNER JOIN projetos p ON tp.projeto_id = p.id"
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Adicionar tecnologia ao projeto
exports.store = async (req, res) => {
  try {
    // Ajustado para as colunas reais: data_aprovacao, aprovado_por_id
    const { projeto_id, tecnologia_id, aprovado_por_id, data_aprovacao } = req.body;
    
    const result = await pool.query(
      "INSERT INTO tecnologias_projeto (projeto_id, tecnologia_id, aprovado_por_id, data_aprovacao) VALUES ($1, $2, $3, $4) RETURNING *",
      [projeto_id, tecnologia_id, aprovado_por_id, data_aprovacao]
    );
    res.status(201).json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Buscar tecnologia específica de um projeto (Chave Composta)
exports.show = async (req, res) => {
  try {
    const { projetoId, tecnologiaId } = req.params;
    const result = await pool.query(
      "SELECT tp.*, t.nome as tecnologia_nome " +
      "FROM tecnologias_projeto tp " +
      "INNER JOIN tecnologias t ON tp.tecnologia_id = t.id " +
      "WHERE tp.projeto_id = $1 AND tp.tecnologia_id = $2", 
      [projetoId, tecnologiaId]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Tecnologia não vinculada a este projeto" });
    }
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Atualizar (Ex: mudar quem aprovou ou a data)
exports.update = async (req, res) => {
  try {
    const { projetoId, tecnologiaId } = req.params;
    const { aprovado_por_id, data_aprovacao } = req.body;
    
    const result = await pool.query(
      "UPDATE tecnologias_projeto SET aprovado_por_id=$1, data_aprovacao=$2 WHERE projeto_id=$3 AND tecnologia_id=$4 RETURNING *",
      [aprovado_por_id, data_aprovacao, projetoId, tecnologiaId]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Registro não encontrado para atualização" });
    }
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Deletar tecnologia do projeto
exports.delete = async (req, res) => {
  try {
    const { projetoId, tecnologiaId } = req.params;
    const result = await pool.query(
        "DELETE FROM tecnologias_projeto WHERE projeto_id = $1 AND tecnologia_id = $2 RETURNING *", 
        [projetoId, tecnologiaId]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Registro não encontrado" });
    }
    res.json({ message: "Tecnologia removida do projeto com sucesso" });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Listar todas as tecnologias de um projeto específico
exports.byProjeto = async (req, res) => {
  try {
    const { projeto_id } = req.params;
    const result = await pool.query(
      "SELECT tp.*, t.nome as tecnologia_nome, t.categoria " +
      "FROM tecnologias_projeto tp " +
      "INNER JOIN tecnologias t ON tp.tecnologia_id = t.id " +
      "WHERE tp.projeto_id = $1",
      [projeto_id]
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};