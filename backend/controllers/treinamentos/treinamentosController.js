const pool = require("../../db");

// Listar todos os treinamentos (Com nome do projeto)
exports.index = async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT t.*, p.nome_projeto " +
      "FROM treinamentos t " +
      "INNER JOIN projetos p ON t.projeto_id = p.id"
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Salvar novo treinamento
exports.store = async (req, res) => {
  try {
    // Ajustado para colunas reais: tipo_treinamento, data_termino, duracao_horas, instrutor (texto), projeto_id
    const { nome, descricao, tipo_treinamento, data_inicio, data_termino, duracao_horas, instrutor, projeto_id, documento_id } = req.body;
    
    const result = await pool.query(
      "INSERT INTO treinamentos (nome, descricao, tipo_treinamento, data_inicio, data_termino, duracao_horas, instrutor, projeto_id, documento_id) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING *",
      [nome, descricao, tipo_treinamento, data_inicio, data_termino, duracao_horas, instrutor, projeto_id, documento_id]
    );
    res.status(201).json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Buscar treinamento por ID
exports.show = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(
      "SELECT t.*, p.nome_projeto " +
      "FROM treinamentos t " +
      "INNER JOIN projetos p ON t.projeto_id = p.id " +
      "WHERE t.id = $1", 
      [id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Treinamento não encontrado" });
    }
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Atualizar treinamento
exports.update = async (req, res) => {
  try {
    const { id } = req.params;
    const { nome, descricao, tipo_treinamento, data_inicio, data_termino, duracao_horas, instrutor, projeto_id } = req.body;
    
    const result = await pool.query(
      "UPDATE treinamentos SET nome=$1, descricao=$2, tipo_treinamento=$3, data_inicio=$4, data_termino=$5, duracao_horas=$6, instrutor=$7, projeto_id=$8 WHERE id=$9 RETURNING *",
      [nome, descricao, tipo_treinamento, data_inicio, data_termino, duracao_horas, instrutor, projeto_id, id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Treinamento não encontrado" });
    }
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Deletar treinamento
exports.delete = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query("DELETE FROM treinamentos WHERE id = $1 RETURNING *", [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Treinamento não encontrado" });
    }
    res.json({ message: "Treinamento deletado com sucesso" });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Listar treinamentos por instrutor (Busca por nome, pois é VARCHAR no banco)
exports.byInstrutor = async (req, res) => {
  try {
    const { nomeInstrutor } = req.params;
    // Usando ILIKE para buscar partes do nome sem diferenciar maiúscula/minúscula
    const result = await pool.query(
      "SELECT * FROM treinamentos WHERE instrutor ILIKE $1",
      [`%${nomeInstrutor}%`]
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};