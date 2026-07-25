/**
 * Sanitiza a saída do Claude substituindo newlines literais dentro de strings JSON
 */
function sanitizeJsonNewlines(text) {
  let result = '';
  let inString = false;
  let escape = false;
  for (let i = 0; i < text.length; i++) {
    const ch = text[i];
    if (escape) { result += ch; escape = false; continue; }
    if (ch === '\\' && inString) { result += ch; escape = true; continue; }
    if (ch === '"') { result += ch; inString = !inString; continue; }
    if (inString && ch === '\r') { if (text[i + 1] === '\n') i++; result += '\\n'; continue; }
    if (inString && ch === '\n') { result += '\\n'; continue; }
    result += ch;
  }
  return result;
}

/**
 * Reparo robusto de JSON truncado por max_tokens.
 * Ele verifica se a string parou no meio, fecha a string, 
 * limpa vírgulas/dois pontos pendentes e fecha os colchetes/chaves abertas.
 */
function repairTruncatedJson(text) {
  let s = text;
  
  // 1. Determinar se paramos no meio de uma string
  let inString = false;
  let escape = false;
  for (let i = 0; i < s.length; i++) {
    if (escape) { escape = false; continue; }
    if (s[i] === '\\') { escape = true; continue; }
    if (s[i] === '"') { inString = !inString; continue; }
  }

  // 2. Se a string estiver aberta, fecha a string
  if (escape) {
    s = s.slice(0, -1); // remove a barra invertida isolada no fim
  }
  if (inString) {
    s += '"';
  }

  // 3. Remove vírgula pendente (ex: "campo": "valor",)
  s = s.replace(/(,\s*)$/, '');
  // Se parou logo após dois-pontos (ex: "campo": ), adiciona um null pra fechar o par
  s = s.replace(/(:\s*)$/, ': null');

  // 4. Empilha chaves/colchetes abertos, na ordem em que foram abertos
  const pilha = [];
  inString = false;
  escape = false;
  for (let i = 0; i < s.length; i++) {
    if (escape) { escape = false; continue; }
    if (s[i] === '\\') { escape = true; continue; }
    if (s[i] === '"') { inString = !inString; continue; }
    if (!inString) {
      if (s[i] === '{') pilha.push('}');
      else if (s[i] === '[') pilha.push(']');
      else if (s[i] === '}' || s[i] === ']') pilha.pop();
    }
  }

  // 5. Fecha do mais interno pro mais externo (ordem LIFO, respeitando o
  // aninhamento real — ex: "{[{" deve fechar como "}]}", nunca "]}}")
  while (pilha.length > 0) { s += pilha.pop(); }

  return s;
}

function parseJsonFromAi(content) {
  console.time('⚙️ Tempo total de parsing e limpeza do JSON');
  if (!content || typeof content !== 'string') {
    throw new Error('Resposta vazia da IA');
  }

  let cleaned = content.trim();
  cleaned = cleaned.replace(/^```json\s*/i, '').replace(/^```\s*/i, '').replace(/\s*```$/g, '');

  const firstObject = cleaned.indexOf('{');
  const firstArray = cleaned.indexOf('[');
  let start = -1;

  if (firstObject === -1) start = firstArray;
  else if (firstArray === -1) start = firstObject;
  else start = Math.min(firstObject, firstArray);

  if (start > 0) cleaned = cleaned.slice(start);

  cleaned = sanitizeJsonNewlines(cleaned);

  try {
    const parsed = JSON.parse(cleaned);
    console.log('✅ JSON validado e parseado de primeira!');
    console.timeEnd('⚙️ Tempo total de parsing e limpeza do JSON');
    return parsed;
  } catch (err) {
    console.log(`❌ Erro no parse direto: ${err.message}`);
  }

  console.warn('⚠️  JSON inválido, iniciando processo de reparo robusto (fechando strings e chaves)...');
  console.time('🛠️ Tempo do processo de reparo');
  const repaired = repairTruncatedJson(cleaned);
  console.timeEnd('🛠️ Tempo do processo de reparo');

  try {
    const result = JSON.parse(repaired);
    console.log('✅ JSON reparado com sucesso (conteúdo parcial preservado).');
    console.timeEnd('⚙️ Tempo total de parsing e limpeza do JSON');
    return result;
  } catch (repairErr) {
    console.timeEnd('⚙️ Tempo total de parsing e limpeza do JSON');
    throw new Error(`Falha ao parsear JSON da IA (mesmo após reparo): ${repairErr.message}`);
  }
}

module.exports = { parseJsonFromAi };
