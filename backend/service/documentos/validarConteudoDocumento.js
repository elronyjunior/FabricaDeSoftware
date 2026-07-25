// Validação do JSON estruturado de um documento antes de salvar edições.
// O cliente (editor in-app) só deveria mandar formas válidas, mas nunca
// confiamos cegamente em input externo. `tabelas` não é editável no editor
// in-app (v1), então só checamos que continua sendo uma lista, sem validar
// a estrutura interna dela.

function eTexto(valor) {
  return typeof valor === 'string';
}

function validarSecao(secao, caminho) {
  if (typeof secao !== 'object' || secao === null || Array.isArray(secao)) {
    return `${caminho}: deve ser um objeto`;
  }

  if (!eTexto(secao.titulo)) {
    return `${caminho}.titulo: deve ser texto`;
  }

  if (!Number.isInteger(secao.nivel) || secao.nivel < 1 || secao.nivel > 3) {
    return `${caminho}.nivel: deve ser um número inteiro entre 1 e 3`;
  }

  if (secao.conteudo != null && !eTexto(secao.conteudo)) {
    return `${caminho}.conteudo: deve ser texto`;
  }

  if (secao.itens != null) {
    if (!Array.isArray(secao.itens) || secao.itens.some((item) => !eTexto(item))) {
      return `${caminho}.itens: deve ser uma lista de textos`;
    }
  }

  if (secao.subsecoes != null) {
    if (!Array.isArray(secao.subsecoes)) {
      return `${caminho}.subsecoes: deve ser uma lista`;
    }
    for (let i = 0; i < secao.subsecoes.length; i += 1) {
      const erro = validarSecao(secao.subsecoes[i], `${caminho}.subsecoes[${i}]`);
      if (erro) return erro;
    }
  }

  return null;
}

// Retorna null quando válido, ou uma string descrevendo o primeiro problema.
function validarConteudoDocumento(conteudo) {
  if (typeof conteudo !== 'object' || conteudo === null || Array.isArray(conteudo)) {
    return 'conteudo_json deve ser um objeto';
  }

  if (conteudo.titulo !== undefined && !eTexto(conteudo.titulo)) {
    return 'titulo deve ser texto';
  }

  if (conteudo.sumario_executivo != null && !eTexto(conteudo.sumario_executivo)) {
    return 'sumario_executivo deve ser texto';
  }

  if (conteudo.conclusao != null && !eTexto(conteudo.conclusao)) {
    return 'conclusao deve ser texto';
  }

  if (conteudo.metadata != null && (typeof conteudo.metadata !== 'object' || Array.isArray(conteudo.metadata))) {
    return 'metadata deve ser um objeto';
  }

  if (!Array.isArray(conteudo.secoes)) {
    return 'secoes deve ser uma lista';
  }

  for (let i = 0; i < conteudo.secoes.length; i += 1) {
    const erro = validarSecao(conteudo.secoes[i], `secoes[${i}]`);
    if (erro) return erro;
  }

  if (conteudo.tabelas != null && !Array.isArray(conteudo.tabelas)) {
    return 'tabelas deve ser uma lista';
  }

  return null;
}

module.exports = { validarConteudoDocumento, validarSecao };
