const { google } = require('googleapis');
const { createGoogleAuthClient } = require('../config/env');
const { GoogleDocBuilder } = require('./ai/googleDocBuilder');

const getAuthClient = () => createGoogleAuthClient();

async function criarArquivoDoc(drive, titulo) {
  const createResponse = await drive.files.create({
    resource: {
      name: titulo,
      mimeType: 'application/vnd.google-apps.document',
    },
    fields: 'id, webViewLink',
  });

  const docId = createResponse.data.id;

  await drive.permissions.create({
    fileId: docId,
    requestBody: { role: 'reader', type: 'anyone' },
  });

  return { id: docId, link: createResponse.data.webViewLink };
}

exports.criarDocFromJson = async (tituloArquivo, documentoJson) => {
  const client = getAuthClient();
  const docs = google.docs({ version: 'v1', auth: client });
  const drive = google.drive({ version: 'v3', auth: client });

  console.log(`📄 Criando Doc estruturado: ${tituloArquivo}`);

  const { id: docId, link } = await criarArquivoDoc(drive, tituloArquivo);
  const builder = new GoogleDocBuilder();
  const requests = builder.buildFromDocumentJson(documentoJson);

  if (requests.length > 0) {
    await docs.documents.batchUpdate({
      documentId: docId,
      requestBody: { requests },
    });
  }

  return { id: docId, link };
};

// Mantido para compatibilidade (texto/markdown simples)
exports.criarDocComConteudo = async (titulo, conteudoTexto) => {
  try {
    const client = getAuthClient();
    const docs = google.docs({ version: 'v1', auth: client });
    const drive = google.drive({ version: 'v3', auth: client });

    console.log(`📄 Criando Doc: ${titulo}`);

    const { id: docId, link: webViewLink } = await criarArquivoDoc(drive, titulo);
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