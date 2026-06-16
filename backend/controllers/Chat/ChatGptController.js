// controllers/chat/chatController.js
const OpenAI = require("openai");
const { anthropicApiKey } = require("../../config/env");

const openai = new OpenAI({
  apiKey: anthropicApiKey,
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

    // Chamada para a API da OpenAI
    // Você pode trocar o model para 'gpt-4o' se tiver acesso e quiser mais inteligência (é mais caro)
    const completion = await openai.chat.completions.create({
      model: "gpt-3.5-turbo", 
      messages: [
        { role: "system", content: "Você é um assistente útil integrado a um sistema de gerenciamento de projetos." },
        { role: "user", content: message }
      ],
      max_tokens: 500, // Limita o tamanho da resposta para economizar
    });

    const responseText = completion.choices[0].message.content;

    // Retorna a resposta para o seu Frontend em Flutter
    res.json({
      response: responseText,
      usage: completion.usage // Opcional: para você monitorar o gasto de tokens
    });

  } catch (error) {
    console.error("Erro ao chamar OpenAI:", error);
    
    // Tratamento de erro específico da OpenAI
    if (error.response) {
      return res.status(error.response.status).json(error.response.data);
    }
    
    res.status(500).json({ 
      error: "Erro interno ao processar mensagem com a IA." 
    });
  }
};