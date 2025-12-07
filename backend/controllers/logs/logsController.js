const pool = require("../../db");

// Listar logs (Mais recentes primeiro)
exports.index = async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT * FROM logs ORDER BY data_hora DESC LIMIT 100"
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Não precisamos de STORE/UPDATE pois o banco faz via Trigger
exports.store = async (req, res) => {
    res.status(400).json({ message: "Logs são gerados automaticamente pelo banco." });
};

// Buscar logs de uma tabela específica
exports.byTipo = async (req, res) => { // No server.js você chamou de :tipo (tabela)
  try {
    const { tipo } = req.params; // Aqui 'tipo' seria o nome da tabela. Ex: 'projetos'
    const result = await pool.query(
      "SELECT * FROM logs WHERE nome_tabela = $1 ORDER BY data_hora DESC",
      [tipo]
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Buscar logs de um usuário específico (quem modificou)
exports.byUsuario = async (req, res) => {
  try {
    const { usuarioId } = req.params;
    const result = await pool.query(
      "SELECT * FROM logs WHERE modificado_por_id = $1 ORDER BY data_hora DESC",
      [usuarioId]
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.show = async (req, res) => {
    try {
      const { id } = req.params;
      const result = await pool.query("SELECT * FROM logs WHERE id = $1", [id]);
      if (result.rows.length === 0) return res.status(404).json({ message: "Log não encontrado" });
      res.json(result.rows[0]);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
};

// Deletar Log (Geralmente logs não se deletam, mas se precisar limpar...)
exports.delete = async (req, res) => {
    try {
      const { id } = req.params;
      const result = await pool.query("DELETE FROM logs WHERE id = $1 RETURNING *", [id]);
      if (result.rows.length === 0) return res.status(404).json({ message: "Log não encontrado" });
      res.json({ message: "Log deletado" });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
};