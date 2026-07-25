// controllers/chat/chatController.js
const Anthropic = require("@anthropic-ai/sdk");
const { claudeApiKey } = require("../../config/env");

const anthropic = new Anthropic({
  apiKey: claudeApiKey,
});

exports.sendMessage = async (req, res) => {
  try {
    const { message } = req.body;

    // Validação básica
    if (!message) {
      return res.status(400).json({ 
        message: "O corpo da requisição deve conter uma 'message'." 
      });
    }

    // Chamada para a API da Anthropic (Claude)
    const response = await anthropic.messages.create({
      model: "claude-sonnet-4-5",
      messages: [
        { role: "user", content: message }
      ],
      system: "Você é um assistente útil integrado a um sistema de gerenciamento de projetos.",
      max_tokens: 500, // Limita o tamanho da resposta para economizar
    });

    const responseText = response.content[0].text;

    // Retorna a resposta para o seu Frontend em Flutter
    res.json({
      response: responseText,
      usage: response.usage // Opcional: para você monitorar o gasto de tokens
    });

  } catch (error) {
    console.error("Erro ao chamar Claude:", error);
    
    // Tratamento de erro específico da Anthropic
    if (error.status) {
      return res.status(error.status).json({ error: error.message });
    }
    
    res.status(500).json({ 
      error: "Erro interno ao processar mensagem com a IA." 
    });
  }
};