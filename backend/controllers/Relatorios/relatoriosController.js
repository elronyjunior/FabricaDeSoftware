const pool = require("../../db");

exports.getDashboardStats = async (req, res) => {
  try {
    // 1. Totais Gerais
    const totalProjetosQuery = await pool.query("SELECT COUNT(*) FROM projetos");
    const totalOrcamentoQuery = await pool.query("SELECT SUM(orcamento_estimado) FROM projetos");
    const projetosAtivosQuery = await pool.query("SELECT COUNT(*) FROM projetos WHERE data_final IS NULL");

    // 2. Projetos por Complexidade (Para Gráfico de Pizza)
    const complexidadeQuery = await pool.query(`
      SELECT complexidade, COUNT(*) as quantidade 
      FROM projetos 
      WHERE complexidade IS NOT NULL 
      GROUP BY complexidade
    `);

    // 3. Top 5 Projetos mais Caros (Orçamento)
    const topProjetosCaros = await pool.query(`
      SELECT nome_projeto, orcamento_estimado 
      FROM projetos 
      ORDER BY orcamento_estimado DESC 
      LIMIT 5
    `);

    // 4. Custo de Recursos por Projeto (Cálculo Estimado)
    // CORREÇÃO: Removemos o EXTRACT. (Data - Data) já retorna dias em Inteiro no Postgres.
    const custoRecursosQuery = await pool.query(`
      SELECT 
        p.nome_projeto,
        SUM(
          ((COALESCE(rp.data_desalocacao, CURRENT_DATE) - rp.data_alocacao) * 8 * rp.custo_hora)
        ) as custo_recursos_atual
      FROM projetos p
      INNER JOIN recursos_projeto rp ON p.id = rp.projeto_id
      GROUP BY p.nome_projeto
      ORDER BY custo_recursos_atual DESC
      LIMIT 5
    `);

    res.json({
      resumo: {
        total_projetos: parseInt(totalProjetosQuery.rows[0].count),
        projetos_ativos: parseInt(projetosAtivosQuery.rows[0].count),
        orcamento_total: parseFloat(totalOrcamentoQuery.rows[0].sum || 0),
      },
      grafico_complexidade: complexidadeQuery.rows,
      grafico_orcamento: topProjetosCaros.rows,
      grafico_custo_recursos: custoRecursosQuery.rows
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
};