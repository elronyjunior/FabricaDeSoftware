const pool = require("../../db");

// Listar todos os usuários
exports.index = async (req, res) => {
  try {
    const result = await pool.query("SELECT id, nome, email, nivel FROM usuarios");
    res.json(result.rows);
  } catch (error) {
    console.error('Erro ao atualizar usuário:', error);
    res.status(500).json({ error: error.message });
  }
};

// Salvar novo usuário
exports.store = async (req, res) => {
  try {
    const { nome, email, senha, nivel } = req.body;

    // Validações básicas
    if (!nome || !email || !senha) {
      return res.status(400).json({ message: 'nome, email e senha são obrigatórios' });
    }

    // Ainda não aplicamos hash nas senhas — armazenar como recebido
    // Incluir telefone no INSERT caso seja fornecido, e retornar telefone também
    const insertQuery = `INSERT INTO usuarios (nome, email, senha, nivel, telefone)
      VALUES ($1, $2, $3, $4, $5) RETURNING id, nome, email, nivel, telefone`;

    // se nivel não for fornecido, usar colaborador como padrão
    const nivelValor = nivel || 'USUARIO';

    const result = await pool.query(insertQuery, [nome, email, senha, nivelValor, req.body.telefone || null]);

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Erro ao criar usuário:', error);

    // detectar erro de constraint (ex: email já existente)
    if (error.code === '23505') {
      // unique_violation
      return res.status(400).json({ message: 'Já existe um usuário com esse email' });
    }

    res.status(500).json({ error: error.message });
  }
};

// Buscar usuário por ID
exports.show = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(
      "SELECT id, nome, email, nivel FROM usuarios WHERE id = $1",
      [id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Usuário não encontrado" });
    }
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Atualizar usuário
exports.update = async (req, res) => {
  try {
    const { id } = req.params;
    const { nome, email, senha, nivel } = req.body;

    let query;
    let params;

    if (senha) {
      // Não aplicar hash por enquanto — atualizar senha em plaintext
      query = "UPDATE usuarios SET nome=$1, email=$2, senha=$3, nivel=$4, telefone=$5 WHERE id=$6 RETURNING id, nome, email, nivel, telefone";
      params = [nome, email, senha, nivel, req.body.telefone || null, id];
    } else {
      query = "UPDATE usuarios SET nome=$1, email=$2, nivel=$3, telefone=$4 WHERE id=$5 RETURNING id, nome, email, nivel, telefone";
      params = [nome, email, nivel, req.body.telefone || null, id];
    }

    const result = await pool.query(query, params);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Usuário não encontrado" });
    }
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Deletar usuário
exports.delete = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query("DELETE FROM usuarios WHERE id = $1 RETURNING *", [id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Usuário não encontrado" });
    }
    res.json({ message: "Usuário deletado com sucesso" });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
