const pool = require("../../db");

// Listar todos os testes (Com JOIN para ver o nome do projeto)
exports.index = async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT t.*, p.nome_projeto " +
      "FROM testes t " +
      "INNER JOIN projetos p ON t.projeto_id = p.id"
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Salvar novo teste
exports.store = async (req, res) => {
  try {
    // Ajustado para aceitar APENAS o que existe no banco
    const { nome, descricao, projeto_id } = req.body;
    
    const result = await pool.query(
      "INSERT INTO testes (nome, descricao, projeto_id) VALUES ($1, $2, $3) RETURNING *",
      [nome, descricao, projeto_id]
    );
    res.status(201).json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Buscar teste por ID
exports.show = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(
      "SELECT t.*, p.nome_projeto " +
      "FROM testes t " +
      "INNER JOIN projetos p ON t.projeto_id = p.id " +
      "WHERE t.id = $1", 
      [id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Teste não encontrado" });
    }
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Atualizar teste
exports.update = async (req, res) => {
  try {
    const { id } = req.params;
    const { nome, descricao, projeto_id } = req.body;
    
    const result = await pool.query(
      "UPDATE testes SET nome=$1, descricao=$2, projeto_id=$3 WHERE id=$4 RETURNING *",
      [nome, descricao, projeto_id, id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Teste não encontrado" });
    }
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Deletar teste
exports.delete = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query("DELETE FROM testes WHERE id = $1 RETURNING *", [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Teste não encontrado" });
    }
    res.json({ message: "Teste deletado com sucesso" });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Listar testes por projeto
exports.byProjeto = async (req, res) => {
  try {
    const { projeto_id } = req.params;
    const result = await pool.query(
      "SELECT * FROM testes WHERE projeto_id = $1",
      [projeto_id]
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};