
const express = require("express");
const cors = require("cors");
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
const relatoriosController = require("./controllers/Relatorios/relatoriosController.js");


const app = express();

// Configurando CORS
app.use(cors());

// Middleware para processar JSON
app.use(express.json());

// Rotas de autenticação
app.post("/api/auth/login", authController.login);
app.post("/api/auth/refresh", authController.refresh);
app.post("/api/auth/google-login", authController.googleLogin);

// Middleware de autenticação
const authenticateToken = authController.authenticateToken;

// --- ROTAS GET e CRUDs ---
// Todas exigem um token válido (Authorization: Bearer <token>), obtido em
// /api/auth/login ou /api/auth/google-login.

// Usuários
app.get("/api/usuarios", authenticateToken, usuariosController.index);
app.post("/api/usuarios", authenticateToken, usuariosController.store);
app.get("/api/usuarios/:id", authenticateToken, usuariosController.show);
app.put("/api/usuarios/:id", authenticateToken, usuariosController.update);
app.delete("/api/usuarios/:id", authenticateToken, usuariosController.delete);

// Projetos
app.get("/api/projetos", authenticateToken, projetosController.index);
app.post("/api/projetos", authenticateToken, projetosController.store); // Usado pelo App
app.get("/api/projetos/cliente/:clienteId", authenticateToken, projetosController.byCliente);
app.get("/api/projetos/:id/detalhes", authenticateToken, projetosController.details);
app.get("/api/projetos/:id", authenticateToken, projetosController.show);
app.put("/api/projetos/:id", authenticateToken, projetosController.update);
app.delete("/api/projetos/:id", authenticateToken, projetosController.delete);

// Clientes
app.get("/api/clientes", authenticateToken, clientesController.index); // Usado pelo App
app.post("/api/clientes", authenticateToken, clientesController.store);
app.get("/api/clientes/:id/detalhes", authenticateToken, clientesController.details);
app.get("/api/clientes/:id", authenticateToken, clientesController.show);
app.put("/api/clientes/:id", authenticateToken, clientesController.update);
app.delete("/api/clientes/:id", authenticateToken, clientesController.delete);

// Endereços
app.get("/api/enderecos", authenticateToken, enderecosController.index);
app.post("/api/enderecos", authenticateToken, enderecosController.store);
app.get("/api/enderecos/:id", authenticateToken, enderecosController.show);
app.put("/api/enderecos/:id", authenticateToken, enderecosController.update);
app.delete("/api/enderecos/:id", authenticateToken, enderecosController.delete);

// Contribuidores
app.get("/api/contribuidores", authenticateToken, contribuidoresController.index); // Usado pelo App
app.post("/api/contribuidores", authenticateToken, contribuidoresController.store);
app.get("/api/contribuidores/:id/projetos", authenticateToken, contribuidoresController.projetos);
app.get("/api/contribuidores/:id", authenticateToken, contribuidoresController.show);
app.put("/api/contribuidores/:id", authenticateToken, contribuidoresController.update);
app.delete("/api/contribuidores/:id", authenticateToken, contribuidoresController.delete);

// Contribuidores Projeto (Vínculo)
app.get("/api/contribuidores-projeto", authenticateToken, contribuidoresProjetoController.index);
app.post("/api/contribuidores-projeto", authenticateToken, contribuidoresProjetoController.store); // Usado pelo App
app.get("/api/contribuidores-projeto/projeto/:projetoId", authenticateToken, contribuidoresProjetoController.byProjeto);
app.get("/api/contribuidores-projeto/contribuidor/:contribuidorId", authenticateToken, contribuidoresProjetoController.byContribuidor);
app.get("/api/contribuidores-projeto/:projetoId/:contribuidorId", authenticateToken, contribuidoresProjetoController.show);
app.put("/api/contribuidores-projeto/:projetoId/:contribuidorId", authenticateToken, contribuidoresProjetoController.update);
app.delete("/api/contribuidores-projeto/:projetoId/:contribuidorId", authenticateToken, contribuidoresProjetoController.delete);

// Documentos
app.get("/api/documentos", authenticateToken, documentosController.index);
app.post("/api/documentos", authenticateToken, documentosController.store);
app.get("/api/documentos/projeto/:projetoId", authenticateToken, documentosController.byProjeto);
app.get("/api/documentos/:id", authenticateToken, documentosController.show);
app.put("/api/documentos/:id", authenticateToken, documentosController.update);
app.delete("/api/documentos/:id", authenticateToken, documentosController.delete);
app.get("/api/documentos/:id/conteudo", authenticateToken, documentosController.getConteudo);
app.put("/api/documentos/:id/conteudo", authenticateToken, documentosController.salvarConteudo);

// Logs
app.get("/api/logs", authenticateToken, logsController.index);
app.post("/api/logs", authenticateToken, logsController.store);
app.get("/api/logs/usuario/:usuarioId", authenticateToken, logsController.byUsuario);
app.get("/api/logs/tipo/:tipo", authenticateToken, logsController.byTipo);
app.get("/api/logs/:id", authenticateToken, logsController.show);
app.delete("/api/logs/:id", authenticateToken, logsController.delete);

// Recursos
app.get("/api/recursos", authenticateToken, recursosController.index); // Usado pelo App
app.post("/api/recursos", authenticateToken, recursosController.store);
app.get("/api/recursos/:id/projetos", authenticateToken, recursosController.projetos);
app.get("/api/recursos/:id", authenticateToken, recursosController.show);
app.put("/api/recursos/:id", authenticateToken, recursosController.update);
app.delete("/api/recursos/:id", authenticateToken, recursosController.delete);

// Recursos Projeto (Vínculo)
app.get("/api/recursos-projeto", authenticateToken, recursosProjetoController.index);
app.post("/api/recursos-projeto", authenticateToken, recursosProjetoController.store); // Usado pelo App
app.get("/api/recursos-projeto/projeto/:projetoId", authenticateToken, recursosProjetoController.byProjeto);
app.get("/api/recursos-projeto/recurso/:recursoId", authenticateToken, recursosProjetoController.byRecurso);
app.get("/api/recursos-projeto/:projetoId/:recursoId", authenticateToken, recursosProjetoController.show);
app.put("/api/recursos-projeto/:projetoId/:recursoId", authenticateToken, recursosProjetoController.update);
app.delete("/api/recursos-projeto/:projetoId/:recursoId", authenticateToken, recursosProjetoController.delete);

// Requisitos
app.get("/api/requisitos", authenticateToken, requisitosController.index);
app.post("/api/requisitos", authenticateToken, requisitosController.store); // Usado pelo App
app.get("/api/requisitos/tipo/:tipo", authenticateToken, requisitosController.byTipo);
app.get("/api/requisitos/:id/projetos", authenticateToken, requisitosController.projetos);
app.get("/api/requisitos/:id", authenticateToken, requisitosController.show);
app.put("/api/requisitos/:id", authenticateToken, requisitosController.update);
app.delete("/api/requisitos/:id", authenticateToken, requisitosController.delete);

// Requisitos Projeto (Vínculo)
app.get("/api/requisitos-projeto", authenticateToken, requisitosProjetoController.index);
app.post("/api/requisitos-projeto", authenticateToken, requisitosProjetoController.store); // Usado pelo App
app.get("/api/requisitos-projeto/projeto/:projetoId", authenticateToken, requisitosProjetoController.byProjeto);
app.get("/api/requisitos-projeto/requisito/:requisitoId", authenticateToken, requisitosProjetoController.byRequisito);
app.get("/api/requisitos-projeto/status/:status", authenticateToken, requisitosProjetoController.byStatus);
app.get("/api/requisitos-projeto/:projetoId/:requisitoId", authenticateToken, requisitosProjetoController.show);
app.put("/api/requisitos-projeto/:projetoId/:requisitoId", authenticateToken, requisitosProjetoController.update);
app.delete("/api/requisitos-projeto/:projetoId/:requisitoId", authenticateToken, requisitosProjetoController.delete);

// Tecnologias
app.get("/api/tecnologias", authenticateToken, tecnologiasController.index); // Usado pelo App
app.post("/api/tecnologias", authenticateToken, tecnologiasController.store);
app.get("/api/tecnologias/categoria/:categoria", authenticateToken, tecnologiasController.byCategoria);
app.get("/api/tecnologias/:id/projetos", authenticateToken, tecnologiasController.projetos);
app.get("/api/tecnologias/:id", authenticateToken, tecnologiasController.show);
app.put("/api/tecnologias/:id", authenticateToken, tecnologiasController.update);
app.delete("/api/tecnologias/:id", authenticateToken, tecnologiasController.delete);

// Tecnologias Projeto (Vínculo)
app.get("/api/tecnologias-projeto", authenticateToken, tecnologiasProjetoController.index);
app.post("/api/tecnologias-projeto", authenticateToken, tecnologiasProjetoController.store); // Usado pelo App
app.get("/api/tecnologias-projeto/projeto/:projeto_id", authenticateToken, tecnologiasProjetoController.byProjeto);
app.get("/api/tecnologias-projeto/:projetoId/:tecnologiaId", authenticateToken, tecnologiasProjetoController.show);
app.put("/api/tecnologias-projeto/:projetoId/:tecnologiaId", authenticateToken, tecnologiasProjetoController.update);
app.delete("/api/tecnologias-projeto/:projetoId/:tecnologiaId", authenticateToken, tecnologiasProjetoController.delete);

// --- ROTAS IA ---
app.post("/api/ai/estimar-orcamento", authenticateToken, require("./controllers/aiController/aiController").estimarOrcamento);
app.post("/api/ai/gerar-requisitos", authenticateToken, require("./controllers/aiController/aiController").gerarRequisitos);
app.post("/api/ai/gerar-documento", authenticateToken, require("./controllers/aiController/aiController").gerarDocumentoIA);
app.get("/api/ai/gerar-documento/status/:jobId", authenticateToken, require("./controllers/aiController/aiController").statusJob);
app.post("/api/ai/retrabalhar-secoes", authenticateToken, require("./controllers/aiController/aiController").retrabalharSecoes);
app.get("/api/ai/retrabalhar-secoes/status/:jobId", authenticateToken, require("./controllers/aiController/aiController").statusJob);

// Rota Relatorio
app.get("/api/relatorios/dashboard", authenticateToken, relatoriosController.getDashboardStats);

// --- TREINAMENTOS E PRESENÇA (ORDEM CORRIGIDA) ---

// 1. ROTAS ESPECÍFICAS PRIMEIRO (Para não confundir com :id)
app.get("/api/treinamentos/:id/presenca", authenticateToken, treinamentosController.getPresenca);
app.post("/api/treinamentos/aluno", authenticateToken, treinamentosController.addAlunoSheet);
app.post("/api/treinamentos/dia", authenticateToken, treinamentosController.addDiaSheet);
app.put("/api/treinamentos/presenca/lote", authenticateToken, treinamentosController.salvarLote);
app.delete("/api/treinamentos/aluno", authenticateToken, treinamentosController.removerAlunoSheet); // Agora esta vem antes
app.delete("/api/treinamentos/dia", authenticateToken, treinamentosController.removerDiaSheet);     // e esta também

// Rotas de Testes
app.get("/api/testes", authenticateToken, testesController.index);
app.post("/api/testes", authenticateToken, testesController.store);
app.get("/api/testes/projeto/:projeto_id", authenticateToken, testesController.byProjeto); // Essa é a rota que a tela está tentando acessar
app.get("/api/testes/:id", authenticateToken, testesController.show);
app.put("/api/testes/:id", authenticateToken, testesController.update);
app.delete("/api/testes/:id", authenticateToken, testesController.delete);

// 2. DEPOIS AS ROTAS GENÉRICAS (CRUD)
app.get("/api/treinamentos", authenticateToken, treinamentosController.index);
app.post("/api/treinamentos", authenticateToken, treinamentosController.store);
app.get("/api/treinamentos/instrutor/:nomeInstrutor", authenticateToken, treinamentosController.byInstrutor);
app.get("/api/treinamentos/:id", authenticateToken, treinamentosController.show);
app.put("/api/treinamentos/:id", authenticateToken, treinamentosController.update);
app.delete("/api/treinamentos/:id", authenticateToken, treinamentosController.delete); // Esta captura qualquer coisa que sobrou

module.exports = app;