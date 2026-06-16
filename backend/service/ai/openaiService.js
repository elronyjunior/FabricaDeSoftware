const Anthropic = require('@anthropic-ai/sdk');

const {
  anthropicApiKey,
  anthropicModel,
} = require('../../config/env');

const { parseJsonFromAi } = require('./jsonParser');

const anthropic = new Anthropic({
  apiKey: anthropicApiKey,
});

async function chatJson({
  system,
  user,
  temperature = 0.4,
  maxTokens = 8000,
}) {
  if (!anthropicApiKey) {
    throw new Error('ANTHROPIC_API_KEY não configurada no .env');
  }

  const response = await anthropic.messages.create({
    model: anthropicModel,
    max_tokens: maxTokens,
    temperature,
    system,
    messages: [
      {
        role: 'user',
        content: user,
      },
    ],
  });

  const content = response.content?.[0]?.text || '{}';

  return parseJsonFromAi(content);
}
console.log("Modelo:", anthropicModel);
module.exports = { chatJson };