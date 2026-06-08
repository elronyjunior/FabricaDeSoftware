const OpenAI = require('openai');
const { openaiApiKey, openaiModel } = require('../../config/env');
const { parseJsonFromAi } = require('./jsonParser');

const openai = new OpenAI({ apiKey: openaiApiKey });

async function chatJson({ system, user, temperature = 0.4, maxTokens = 8000 }) {
  if (!openaiApiKey) {
    throw new Error('OPENAI_API_KEY não configurada no .env');
  }

  const completion = await openai.chat.completions.create({
    model: openaiModel,
    temperature,
    max_tokens: maxTokens,
    response_format: { type: 'json_object' },
    messages: [
      { role: 'system', content: system },
      { role: 'user', content: user },
    ],
  });

  const content = completion.choices[0]?.message?.content;
  return parseJsonFromAi(content);
}

module.exports = { chatJson };
