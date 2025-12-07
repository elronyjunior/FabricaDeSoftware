const pool = require("../../db");

// Listar todos os contribuidores
exports.index = async (req, res) => {
  try {
    // Selecionando todas as colunas
    const result = await pool.query("SELECT * FROM contribuidores ORDER BY id ASC");
    res.json(result.rows);
  } catch (error) {
    console.error('Erro ao listar contribuidores:', error);
    res.status(500).json({ error: error.message });
  }
};

// Salvar novo contribuidor
exports.store = async (req, res) => {
  try {
    // Pegando apenas os campos que existem na tabela nova
    const { nome, email, telefone, cargo, empresa, ativo } = req.body;

    // Validação básica
    if (!nome || !email) {
      return res.status(400).json({ message: 'Nome e Email são obrigatórios.' });
    }

    // Se 'ativo' não for enviado, assume true (padrão do banco)
    const ativoValor = (ativo !== undefined) ? ativo : true;

    const result = await pool.query(
      `INSERT INTO contribuidores (nome, email, telefone, cargo, empresa, ativo) 
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
      [nome, email, telefone, cargo, empresa, ativoValor]
    );

    res.status(201).json(result.rows[0]);

  } catch (error) {
    console.error('Erro ao criar contribuidor:', error);
    // Erro de chave única (Email duplicado)
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
    const result = await pool.query("SELECT * FROM contribuidores WHERE id = $1", [id]);
    
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

// Deletar contribuidor
exports.delete = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(
      "UPDATE contribuidores SET ativo = false WHERE id = $1 RETURNING *", 
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Contribuidor não encontrado" });
    }

    res.json({ message: "Contribuidor deletado com sucesso" });
  } catch (error) {
    // Erro comum: Violação de chave estrangeira (se ele tiver projetos vinculados)
    if (error.code === '23503') {
       return res.status(400).json({ message: "Não é possível excluir este contribuidor pois ele está vinculado a projetos." });
    }
    res.status(500).json({ error: error.message });
  }
};

// Buscar projetos do contribuidor
// (Mantido igual, assumindo que as tabelas 'projetos' e 'contribuidores_projeto' existem)
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