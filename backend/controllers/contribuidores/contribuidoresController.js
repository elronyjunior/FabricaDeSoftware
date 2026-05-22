const pool = require("../../db");

// Listar todos os contribuidores (APENAS ATIVOS)
exports.index = async (req, res) => {
  try {
    // FILTRO: Traz apenas quem está ativo
    const result = await pool.query("SELECT * FROM contribuidores WHERE ativo = true ORDER BY id ASC");
    res.json(result.rows);
  } catch (error) {
    console.error('Erro ao listar contribuidores:', error);
    res.status(500).json({ error: error.message });
  }
};

// Salvar novo contribuidor
exports.store = async (req, res) => {
  try {
    const { nome, email, telefone, cargo, empresa, ativo } = req.body;

    if (!nome || !email) {
      return res.status(400).json({ message: 'Nome e Email são obrigatórios.' });
    }

    const ativoValor = (ativo !== undefined) ? ativo : true;

    const result = await pool.query(
      `INSERT INTO contribuidores (nome, email, telefone, cargo, empresa, ativo) 
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
      [nome, email, telefone, cargo, empresa, ativoValor]
    );

    res.status(201).json(result.rows[0]);

  } catch (error) {
    console.error('Erro ao criar contribuidor:', error);
    if (error.code === '23505') {
      return res.status(400).json({ message: 'Este email já está cadastrado.' });
    }
    res.status(500).json({ error: error.message });
  }
};

// Buscar contribuidor por ID
exports.show = async (req, res) => {
  try {
    const { id } = req.params;
    // Garante que só busca se estiver ativo
    const result = await pool.query("SELECT * FROM contribuidores WHERE id = $1 AND ativo = true", [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Contribuidor não encontrado" });
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Atualizar contribuidor
exports.update = async (req, res) => {
  try {
    const { id } = req.params;
    const { nome, email, telefone, cargo, empresa, ativo } = req.body;

    const result = await pool.query(
      `UPDATE contribuidores 
       SET nome=$1, email=$2, telefone=$3, cargo=$4, empresa=$5, ativo=$6 
       WHERE id=$7 RETURNING *`,
      [nome, email, telefone, cargo, empresa, ativo, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Contribuidor não encontrado" });
    }

    res.json(result.rows[0]);

  } catch (error) {
    console.error('Erro ao atualizar contribuidor:', error);
    if (error.code === '23505') {
      return res.status(400).json({ message: 'Este email já está em uso por outro contribuidor.' });
    }
    res.status(500).json({ error: error.message });
  }
};

// Deletar contribuidor (SOFT DELETE - Apenas desativa)
exports.delete = async (req, res) => {
  try {
    const { id } = req.params;
    
    // MUDANÇA: Faz o UPDATE para false em vez de DELETE
    const result = await pool.query(
      "UPDATE contribuidores SET ativo = false WHERE id = $1 RETURNING *", 
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Contribuidor não encontrado" });
    }

    res.json({ message: "Contribuidor desativado com sucesso" });
  } catch (error) {
    // Mesmo sendo soft delete, se o banco tiver alguma trava muito específica ele avisa
    res.status(500).json({ error: error.message });
  }
};

// Buscar projetos do contribuidor
exports.projetos = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(
      `SELECT p.* FROM projetos p 
       INNER JOIN contribuidores_projeto cp ON p.id = cp.projeto_id 
       WHERE cp.contribuidor_id = $1`,
      [id]
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};