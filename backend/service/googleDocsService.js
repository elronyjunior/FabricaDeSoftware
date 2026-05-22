const fs = require('fs');
const path = require('path');
const { google } = require('googleapis');

// Ajuste os caminhos conforme sua estrutura atual
const TOKEN_PATH = path.join(__dirname, 'token.json'); 
const CREDENTIALS_PATH = path.join(__dirname, 'credentials.json');

const getAuthClient = () => {
  if (!fs.existsSync(TOKEN_PATH)) {
    throw new Error(`Token não encontrado em: ${TOKEN_PATH}`);
  }
  const tokenContent = fs.readFileSync(TOKEN_PATH);
  const credentials = JSON.parse(tokenContent);
  return google.auth.fromJSON(credentials);
};

// --- FUNÇÃO 1: CRIAR DOCUMENTO (COM PERMISSÃO PÚBLICA) ---
exports.criarDocComConteudo = async (titulo, conteudoTexto) => {
  try {
    const client = getAuthClient();
    const docs = google.docs({ version: 'v1', auth: client });
    const drive = google.drive({ version: 'v3', auth: client });

    console.log(`📄 Criando Doc: ${titulo}`);

    // 1. Criar Arquivo
    const createResponse = await drive.files.create({
      resource: {
        name: titulo,
        mimeType: 'application/vnd.google-apps.document',
      },
      fields: 'id, webViewLink',
    });

    const docId = createResponse.data.id;
    const webViewLink = createResponse.data.webViewLink;

    // --- NOVO: 1.5. Liberar acesso para "Qualquer pessoa com o link" ---
    await drive.permissions.create({
      fileId: docId,
      requestBody: {
        role: 'reader', // Pode ler
        type: 'anyone', // Qualquer pessoa na internet (com o link)
      },
    });
    console.log(`🔓 Acesso liberado: Qualquer pessoa com o link pode ler.`);
    // -------------------------------------------------------------------

    // 2. Processar o Markdown (**negrito**)
    const requests = [];
    let currentIndex = 1;

    const partes = conteudoTexto.split(/(\*\*.*?\*\*)/g);

    for (const parte of partes) {
      if (parte === "") continue;

      let textoLimpo = parte;
      let ehNegrito = false;

      if (parte.startsWith("**") && parte.endsWith("**")) {
        textoLimpo = parte.slice(2, -2);
        ehNegrito = true;
      }

      if (textoLimpo.length > 0) {
        requests.push({
          insertText: {
            location: { index: currentIndex },
            text: textoLimpo,
          },
        });

        if (ehNegrito) {
          requests.push({
            updateTextStyle: {
              range: {
                startIndex: currentIndex,
                endIndex: currentIndex + textoLimpo.length,
              },
              textStyle: { bold: true },
              fields: 'bold',
            },
          });
        }
        currentIndex += textoLimpo.length;
      }
    }

    if (requests.length > 0) {
      await docs.documents.batchUpdate({
        documentId: docId,
        requestBody: { requests: requests },
      });
    }

    return { id: docId, link: webViewLink };

  } catch (error) {
    console.error("Erro no Google Docs Service (Criar):", error);
    throw error;
  }
};

// --- FUNÇÃO 2: DELETAR DOCUMENTO ---
exports.deletarArquivo = async (fileId) => {
  try {
    const client = getAuthClient();
    const drive = google.drive({ version: 'v3', auth: client });

    await drive.files.delete({
      fileId: fileId,
    });
    console.log(`🗑️ Arquivo Drive ID ${fileId} deletado com sucesso.`);
  } catch (error) {
    console.error("Erro ao deletar do Drive (pode já ter sido apagado):", error.message);
  }
};