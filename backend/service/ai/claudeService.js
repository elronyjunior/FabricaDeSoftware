const Anthropic = require('@anthropic-ai/sdk');
const { claudeApiKey, claudeModel } = require('../../config/env');
const { parseJsonFromAi } = require('./jsonParser');

const anthropic = new Anthropic({ apiKey: claudeApiKey });

async function chatJson({ system, user, temperature = 0.4, maxTokens = 16000 }) {
  if (!claudeApiKey) {
    throw new Error('Claude_API não configurada no .env');
  }

  console.log('🚀 Iniciando requisição (streaming) para a API do Claude...');
  console.time('⏳ Tempo total da API do Claude');
  const stream = anthropic.messages.stream({
    model: claudeModel,
    temperature,
    max_tokens: maxTokens,
    system,
    messages: [
      { role: 'user', content: user },
    ],
  });
  const response = await stream.finalMessage();
  console.timeEnd('⏳ Tempo total da API do Claude');

  const content = response.content[0]?.text;
  console.log(`📊 Tamanho da resposta bruta do Claude: ${content ? content.length : 0} caracteres`);

  if (response.stop_reason === 'max_tokens') {
    console.warn('⚠️  Resposta da IA truncada (max_tokens atingido). Tentando reparar JSON...');
  }

  return parseJsonFromAi(content);
}

module.exports = { chatJson };
