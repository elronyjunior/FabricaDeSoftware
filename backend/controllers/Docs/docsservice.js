const { google } = require('googleapis');
const { createGoogleAuthClient } = require('../../config/env');

const getAuthClient = () => createGoogleAuthClient();

async function criarDocumentoFinal() {
  try {
    // 1. Autentica como RONALDO (usando o token)
    const client = getAuthClient();
    const docs = google.docs({ version: 'v1', auth: client });
    const drive = google.drive({ version: 'v3', auth: client });

    console.log("👤 Autenticado como Ronaldo. Criando documento...");

    // 2. Cria o arquivo no seu "Meu Drive" (Raiz)
    // Se quiser colocar naquela pasta específica, descomente a linha 'parents'
    const createResponse = await drive.files.create({
      resource: {
        name: 'Relatório Fábrica de Software (Final)',
        mimeType: 'application/vnd.google-apps.document',
        // parents: ['SEU_ID_DA_PASTA_AQUI'], // Opcional: só se quiser organizar
      },
      fields: 'id',
    });

    const docId = createResponse.data.id;
    console.log(`✅ Sucesso Absoluto! Documento criado.`);
    console.log(`🆔 ID: ${docId}`);

    // 3. Escreve o conteúdo (Título, Texto, Formatação)
    await docs.documents.batchUpdate({
      documentId: docId,
      requestBody: {
        requests: [
          {
            insertText: {
              location: { index: 1 },
              text: "Relatório de Teste\n\nEste documento foi criado pelo Node.js autenticado via OAuth 2.0.\nO problema de cota foi resolvido pois estamos usando seu armazenamento pessoal!",
            },
          },
          {
            updateTextStyle: {
              range: { startIndex: 1, endIndex: 19 }, // "Relatório de Teste"
              textStyle: {
                bold: true,
                fontSize: { magnitude: 16, unit: 'PT' },
                foregroundColor: { color: { rgbColor: { red: 0, green: 0.5, blue: 0 } } } // Verde
              },
              fields: 'bold,fontSize,foregroundColor',
            }
          }
        ],
      },
    });

    console.log("✍️ Texto inserido!");
    console.log(`🔗 Link para ver o arquivo: https://docs.google.com/document/d/${docId}`);

  } catch (error) {
    console.error("❌ Erro:", error.message);
  }
}

criarDocumentoFinal();