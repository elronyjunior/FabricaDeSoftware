const REQUISITOS_SYSTEM = `Você é um analista de requisitos sênior especializado em engenharia de software.
Sempre responda em português do Brasil.
Sua saída DEVE ser um JSON válido, sem markdown, sem comentários e sem texto fora do JSON.`;

function buildRequisitosPrompt({ nomeProjeto, escopo }) {
  return {
    system: REQUISITOS_SYSTEM,
    user: `Projeto: "${nomeProjeto}"
Escopo detalhado:
"""
${escopo}
"""

Gere no mínimo 15 requisitos (mínimo 60% funcionais e 40% não funcionais).
Cada requisito deve ser profundamente detalhado, como em um documento IEEE/BRD profissional.

Retorne EXCLUSIVAMENTE este JSON:
{
  "requisitos": [
    {
      "codigo": "RF-001 ou RNF-001",
      "titulo": "Título claro e específico",
      "descricao": "Descrição completa em 4 a 8 frases explicando o que o sistema deve fazer ou garantir, incluindo contexto de negócio e impacto.",
      "tipo": "Funcional ou Não Funcional",
      "prioridade": "Alta, Média ou Baixa",
      "categoria": "Ex: Autenticação, Performance, UX, Segurança, Integração",
      "ator_principal": "Quem executa ou se beneficia",
      "criterios_aceite": [
        "Critério mensurável 1",
        "Critério mensurável 2",
        "Critério mensurável 3"
      ],
      "pre_condicoes": "Condições necessárias antes da execução",
      "pos_condicoes": "Estado esperado após atendimento",
      "dependencias": ["Outros requisitos ou sistemas relacionados"],
      "riscos": "Riscos se o requisito não for atendido"
    }
  ]
}

Regras:
- Códigos únicos e sequenciais (RF para funcionais, RNF para não funcionais).
- Critérios de aceite sempre mensuráveis e testáveis.
- Evite requisitos genéricos ou vagos.`,
    temperature: 0.5,
  };
}

const DOCUMENTO_SYSTEM = `Você é um arquiteto de software e analista de negócios sênior.
Produza documentação técnica profissional em português do Brasil.
Sempre responda com JSON válido, sem markdown externo, sem comentários.`;

const DOCUMENTO_SCHEMA = `{
  "titulo": "Título completo do documento",
  "tipo_documento": "Tipo informado",
  "versao": "1.0",
  "metadata": {
    "projeto": "Nome do projeto",
    "autor": "IA - Fábrica de Software",
    "objetivo": "Objetivo principal do documento"
  },
  "sumario_executivo": "Parágrafo de 5 a 8 frases com visão geral executiva",
  "secoes": [
    {
      "titulo": "1. Nome da seção",
      "nivel": 1,
      "conteudo": "Parágrafos detalhados da seção",
      "itens": ["[RF-001] Título do requisito: descrição completa quando aplicável"],
      "subsecoes": [
        {
          "titulo": "1.1 Subseção",
          "nivel": 2,
          "conteudo": "Texto detalhado",
          "itens": []
        }
      ]
    }
  ],
  "tabelas": [
    {
      "titulo": "Título da tabela",
      "cabecalhos": ["Coluna 1", "Coluna 2"],
      "linhas": [["valor", "valor"]]
    }
  ],
  "conclusao": "Parágrafo de conclusão e próximos passos"
}`;

const TIPO_INSTRUCOES = {
  Requisitos: `Documento de Especificação de Requisitos (ERS).
Siga a lógica do modelo "Requisitos do Projeto": seções numeradas, subseções por categoria e requisitos como itens de lista.
Estrutura recomendada: 1. Introdução (1.1 Objetivo, 1.2 Público-Alvo), 2. Requisitos Funcionais (RF), 3. Segurança, 4. Requisitos Não Funcionais (RNF), regras de negócio, restrições e matriz de rastreabilidade.
Para requisitos em "itens", use sempre o padrão "[RF-001] Nome: descrição" ou "[RNF-001] Nome: descrição"; não inclua marcador manual.
Inclua: visão do produto, stakeholders, glossário, requisitos funcionais detalhados, requisitos não funcionais (performance, segurança, usabilidade, disponibilidade), regras de negócio, restrições e matriz de rastreabilidade.
Mínimo 8 seções principais e 3 tabelas.`,
  'Casos de Uso': `Documento de Casos de Uso UML.
Inclua: atores, diagrama descritivo, casos de uso detalhados (nome, ID, ator, descrição, pré/pós-condições, fluxo principal, fluxos alternativos, exceções).
Mínimo 6 casos de uso completos em subseções.`,
  Arquitetura: `Documento de Arquitetura de Software.
Inclua: contexto, visão lógica, visão física, tecnologias, camadas, integrações, decisões arquiteturais (ADRs), requisitos não funcionais atendidos e riscos técnicos.`,
  API: `Documento de Especificação de API REST.
Inclua: visão geral, autenticação, convenções, endpoints detalhados (método, path, parâmetros, body, respostas, erros), modelos de dados e exemplos.`,
  Modelagem: `Documento de Modelagem de Dados.
Inclua: entidades, atributos, relacionamentos, cardinalidade, dicionário de dados e regras de integridade.`,
  Testes: `Plano de Testes.
Inclua: escopo, estratégia, tipos de teste, ambientes, casos de teste detalhados, critérios de entrada/saída e matriz de rastreabilidade.`,
  Código: `Documento de Padrões e Estrutura de Código.
Inclua: stack, organização de pastas, convenções de nomenclatura, padrões de projeto, fluxo de desenvolvimento e boas práticas.`,
};

function buildDocumentoPrompt({ projeto, tipoDocumento, tituloDocumento, descricaoExtra, requisitos }) {
  const instrucaoTipo = TIPO_INSTRUCOES[tipoDocumento] || `Documento técnico do tipo ${tipoDocumento} com alto nível de detalhe profissional.`;

  const requisitosTexto = requisitos.length
    ? requisitos.map((r) => `- [${r.tipo}] ${r.titulo}: ${r.descricao}`).join('\n')
    : 'Nenhum requisito cadastrado no projeto ainda.';

  return {
    system: DOCUMENTO_SYSTEM,
    user: `Gere um documento técnico completo e detalhado.

TIPO: ${tipoDocumento}
TÍTULO SOLICITADO: ${tituloDocumento}

PROJETO:
- Nome: ${projeto.nome_projeto}
- Descrição: ${projeto.descricao || 'Sem descrição'}
- Modelo: ${projeto.modelo_projeto || 'Padrão'}
- Escopo: ${projeto.escopo || 'Não informado'}

REQUISITOS JÁ CADASTRADOS NO PROJETO:
${requisitosTexto}

INSTRUÇÕES ESPECÍFICAS DO TIPO:
${instrucaoTipo}

INSTRUÇÕES EXTRAS DO USUÁRIO:
${descricaoExtra || 'Siga as melhores práticas de engenharia de software.'}

Retorne EXCLUSIVAMENTE um JSON neste formato:
${DOCUMENTO_SCHEMA}

Regras:
- Conteúdo profundo e específico ao projeto (não genérico).
- Seções com parágrafos longos e bem elaborados.
- Use subsecoes aninhadas quando necessário.
- Tabelas devem ter dados realistas do projeto.
- Mínimo 6 secoes principais.
- Numere os títulos de secoes e subsecoes no próprio campo "titulo" (ex: "2.1 Gestão de Acesso e Perfis").
- Não use markdown, HTML, pipes, asteriscos, hífens ou bullets manuais para simular formatação.
- A formatação visual será aplicada pelo código no Google Docs; o JSON deve trazer somente dados estruturados.`,
    temperature: 0.45,
    maxTokens: 12000,
  };
}

function formatRequisitoForApi(requisito) {
  const partes = [requisito.descricao || ''];

  if (requisito.categoria) partes.push(`\nCategoria: ${requisito.categoria}`);
  if (requisito.ator_principal) partes.push(`Ator principal: ${requisito.ator_principal}`);
  if (requisito.pre_condicoes) partes.push(`Pré-condições: ${requisito.pre_condicoes}`);
  if (requisito.pos_condicoes) partes.push(`Pós-condições: ${requisito.pos_condicoes}`);

  if (Array.isArray(requisito.criterios_aceite) && requisito.criterios_aceite.length) {
    partes.push('\nCritérios de aceite:');
    requisito.criterios_aceite.forEach((c) => partes.push(`• ${c}`));
  }

  if (Array.isArray(requisito.dependencias) && requisito.dependencias.length) {
    partes.push(`\nDependências: ${requisito.dependencias.join(', ')}`);
  }

  if (requisito.riscos) partes.push(`\nRiscos: ${requisito.riscos}`);

  return {
    codigo: requisito.codigo || null,
    titulo: requisito.titulo || 'Requisito',
    descricao: partes.join('\n').trim(),
    tipo: requisito.tipo || 'Funcional',
    prioridade: requisito.prioridade || 'Média',
    criterios_aceite: requisito.criterios_aceite || [],
    categoria: requisito.categoria || null,
  };
}

module.exports = {
  buildRequisitosPrompt,
  buildDocumentoPrompt,
  formatRequisitoForApi,
};
