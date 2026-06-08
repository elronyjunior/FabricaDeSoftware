function parseJsonFromAi(content) {
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

  const lastObject = cleaned.lastIndexOf('}');
  const lastArray = cleaned.lastIndexOf(']');
  const end = Math.max(lastObject, lastArray);

  if (end >= 0) cleaned = cleaned.slice(0, end + 1);

  return JSON.parse(cleaned);
}

module.exports = { parseJsonFromAi };
