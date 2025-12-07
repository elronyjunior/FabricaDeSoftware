const express = require("express");
const cors = require("cors");
require('dotenv').config(); 
const authController = require("./controllers/auth/authController.js");
const usuariosController = require("./controllers/usuarios/usuariosController.js");
const projetosController = require("./controllers/projetos/projetosController.js");
const clientesController = require("./controllers/clientes/clientesController.js");
const enderecosController = require("./controllers/enderecos/enderecosController.js");
const contribuidoresController = require("./controllers/contribuidores/contribuidoresController.js");
const contribuidoresProjetoController = require("./controllers/contribuidoresProjeto/contribuidoresProjetoController.js");
const documentosController = require("./controllers/documentos/documentosController.js");
const logsController = require("./controllers/logs/logsController.js");
const recursosController = require("./controllers/recursos/recursosController.js");
const recursosProjetoController = require("./controllers/recursosProjeto/recursosProjetoController.js");
const requisitosController = require("./controllers/requisitos/requisitosController.js");
const requisitosProjetoController = require("./controllers/requisitosProjeto/requisitosProjetoController.js");
const tecnologiasController = require("./controllers/tecnologias/tecnologiasController.js");
const tecnologiasProjetoController = require("./controllers/tecnologiasProjeto/tecnologiasProjetoController.js");
const testesController = require("./controllers/testes/testesController.js");
const treinamentosController = require("./controllers/treinamentos/treinamentosController.js");
const chatController = require("./controllers/Chat/ChatGptController.js");

const app = express();

// Configurando CORS
app.use(cors());

// Middleware para processar JSON
app.use(express.json());

// Rotas de autenticação
app.post("/api/auth/login", authController.login);
app.post("/api/auth/refresh", authController.refresh);
app.post("/api/auth/google-login", authController.googleLogin); // Esta é a linha nova

// Middleware de autenticação para rotas protegidas
const authenticateToken = authController.authenticateToken;

// Rotas da API de usuários
app.get("/api/usuarios", usuariosController.index);
app.post("/api/usuarios", usuariosController.store);
app.get("/api/usuarios/:id", usuariosController.show);
app.put("/api/usuarios/:id", usuariosController.update);
app.delete("/api/usuarios/:id", usuariosController.delete);

// Rotas da API de projetos
app.get("/api/projetos", projetosController.index);
app.post("/api/projetos", projetosController.store);
app.get("/api/projetos/cliente/:clienteId", projetosController.byCliente);
app.get("/api/projetos/:id/detalhes", projetosController.details);
app.get("/api/projetos/:id", projetosController.show);
app.put("/api/projetos/:id", projetosController.update);
app.delete("/api/projetos/:id", projetosController.delete);

// Rotas da API de clientes
app.get("/api/clientes", clientesController.index);
app.post("/api/clientes", clientesController.store);
app.get("/api/clientes/:id/detalhes", clientesController.details);
app.get("/api/clientes/:id", clientesController.show);
app.put("/api/clientes/:id", clientesController.update);
app.delete("/api/clientes/:id", clientesController.delete);

// Rotas da API de endereços
app.get("/api/enderecos", enderecosController.index);
app.post("/api/enderecos", enderecosController.store);
app.get("/api/enderecos/:id", enderecosController.show);
app.put("/api/enderecos/:id", enderecosController.update);
app.delete("/api/enderecos/:id", enderecosController.delete);

// Rotas da API de contribuidores
app.get("/api/contribuidores", contribuidoresController.index);
app.post("/api/contribuidores", contribuidoresController.store);
app.get("/api/contribuidores/:id/projetos", contribuidoresController.projetos);
app.get("/api/contribuidores/:id", contribuidoresController.show);
app.put("/api/contribuidores/:id", contribuidoresController.update);
app.delete("/api/contribuidores/:id", contribuidoresController.delete);

// Rotas da API de contribuidores_projeto
app.get("/api/contribuidores-projeto", contribuidoresProjetoController.index);
app.post("/api/contribuidores-projeto", contribuidoresProjetoController.store);
app.get("/api/contribuidores-projeto/projeto/:projetoId", contribuidoresProjetoController.byProjeto);
app.get("/api/contribuidores-projeto/contribuidor/:contribuidorId", contribuidoresProjetoController.byContribuidor);
app.get("/api/contribuidores-projeto/:projetoId/:contribuidorId", contribuidoresProjetoController.show);
app.put("/api/contribuidores-projeto/:projetoId/:contribuidorId", contribuidoresProjetoController.update);
app.delete("/api/contribuidores-projeto/:projetoId/:contribuidorId", contribuidoresProjetoController.delete);

// Rotas da API de documentos
app.get("/api/documentos", documentosController.index);
app.post("/api/documentos", documentosController.store);
app.get("/api/documentos/projeto/:projetoId", documentosController.byProjeto);
app.get("/api/documentos/:id", documentosController.show);
app.put("/api/documentos/:id", documentosController.update);
app.delete("/api/documentos/:id", documentosController.delete);

// Rotas da API de logs
app.get("/api/logs", logsController.index);
app.post("/api/logs", logsController.store);
app.get("/api/logs/usuario/:usuarioId", logsController.byUsuario);
app.get("/api/logs/tipo/:tipo", logsController.byTipo);
app.get("/api/logs/:id", logsController.show);
app.delete("/api/logs/:id", logsController.delete);

// Rotas da API de recursos
app.get("/api/recursos", recursosController.index);
app.post("/api/recursos", recursosController.store);
app.get("/api/recursos/:id/projetos", recursosController.projetos);
app.get("/api/recursos/:id", recursosController.show);
app.put("/api/recursos/:id", recursosController.update);
app.delete("/api/recursos/:id", recursosController.delete);

// Rotas da API de recursos_projeto
app.get("/api/recursos-projeto", recursosProjetoController.index);
app.post("/api/recursos-projeto", recursosProjetoController.store);
app.get("/api/recursos-projeto/projeto/:projetoId", recursosProjetoController.byProjeto);
app.get("/api/recursos-projeto/recurso/:recursoId", recursosProjetoController.byRecurso);
app.get("/api/recursos-projeto/:id", recursosProjetoController.show);
app.put("/api/recursos-projeto/:id", recursosProjetoController.update);
app.delete("/api/recursos-projeto/:id", recursosProjetoController.delete);

// Rotas da API de requisitos
app.get("/api/requisitos", requisitosController.index);
app.post("/api/requisitos", requisitosController.store);
app.get("/api/requisitos/tipo/:tipo", requisitosController.byTipo);
app.get("/api/requisitos/prioridade/:prioridade", requisitosController.byPrioridade);
app.get("/api/requisitos/:id/projetos", requisitosController.projetos);
app.get("/api/requisitos/:id", requisitosController.show);
app.put("/api/requisitos/:id", requisitosController.update);
app.delete("/api/requisitos/:id", requisitosController.delete);

// Rotas da API de requisitos_projeto
app.get("/api/requisitos-projeto", requisitosProjetoController.index);
app.post("/api/requisitos-projeto", requisitosProjetoController.store);
app.get("/api/requisitos-projeto/projeto/:projetoId", requisitosProjetoController.byProjeto);
app.get("/api/requisitos-projeto/requisito/:requisitoId", requisitosProjetoController.byRequisito);
app.get("/api/requisitos-projeto/status/:status", requisitosProjetoController.byStatus);
app.get("/api/requisitos-projeto/:id", requisitosProjetoController.show);
app.put("/api/requisitos-projeto/:id", requisitosProjetoController.update);
app.delete("/api/requisitos-projeto/:id", requisitosProjetoController.delete);

// Rotas da API de tecnologias
app.get("/api/tecnologias", tecnologiasController.index);
app.post("/api/tecnologias", tecnologiasController.store);
app.get("/api/tecnologias/categoria/:categoria", tecnologiasController.byCategoria);
app.get("/api/tecnologias/:id/projetos", tecnologiasController.projetos);
app.get("/api/tecnologias/:id", tecnologiasController.show);
app.put("/api/tecnologias/:id", tecnologiasController.update);
app.delete("/api/tecnologias/:id", tecnologiasController.delete);

// Rotas da API de tecnologias_projeto
app.get("/api/tecnologias-projeto", tecnologiasProjetoController.index);
app.post("/api/tecnologias-projeto", tecnologiasProjetoController.store);
app.get("/api/tecnologias-projeto/projeto/:projeto_id", tecnologiasProjetoController.byProjeto);
app.get("/api/tecnologias-projeto/:id", tecnologiasProjetoController.show);
app.put("/api/tecnologias-projeto/:id", tecnologiasProjetoController.update);
app.delete("/api/tecnologias-projeto/:id", tecnologiasProjetoController.delete);

// Rotas da API de testes
app.get("/api/testes", testesController.index);
app.post("/api/testes", testesController.store);
app.get("/api/testes/projeto/:projeto_id", testesController.byProjeto);
app.get("/api/testes/status/:status", testesController.byStatus);
app.get("/api/testes/:id", testesController.show);
app.put("/api/testes/:id", testesController.update);
app.delete("/api/testes/:id", testesController.delete);

// Rotas da API de treinamentos
app.get("/api/treinamentos", treinamentosController.index);
app.post("/api/treinamentos", treinamentosController.store);
app.get("/api/treinamentos/status/:status", treinamentosController.byStatus);
app.get("/api/treinamentos/instrutor/:instrutor_id", treinamentosController.byInstrutor);
app.get("/api/treinamentos/:id", treinamentosController.show);
app.put("/api/treinamentos/:id", treinamentosController.update);
app.delete("/api/treinamentos/:id", treinamentosController.delete);

//rota chatGPT
app.post("/api/chat/message", authenticateToken, chatController.sendMessage);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Servidor rodando em http://localhost:${PORT}`);
});