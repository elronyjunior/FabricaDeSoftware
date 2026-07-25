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

function dimensionPt(magnitude) {
  return { magnitude, unit: 'PT' };
}

function buildTableCellRequests(tableElement, rows) {
  const requests = [];
  const tableRows = tableElement.table?.tableRows || [];
  const tableStartIndex = tableElement.startIndex;

  if (Number.isInteger(tableStartIndex)) {
    requests.push({
      updateTableCellStyle: {
        tableStartLocation: { index: tableStartIndex },
        tableCellStyle: {
          contentAlignment: 'MIDDLE',
          paddingTop: dimensionPt(4),
          paddingRight: dimensionPt(4),
          paddingBottom: dimensionPt(4),
          paddingLeft: dimensionPt(4),
        },
        fields: 'contentAlignment,paddingTop,paddingRight,paddingBottom,paddingLeft',
      },
    });

    if (rows[0]?.length) {
      requests.push({
        updateTableCellStyle: {
          tableRange: {
            tableCellLocation: {
              tableStartLocation: { index: tableStartIndex },
              rowIndex: 0,
              columnIndex: 0,
            },
            rowSpan: 1,
            columnSpan: rows[0].length,
          },
          tableCellStyle: {
            backgroundColor: {
              color: {
                rgbColor: { red: 0.94, green: 0.94, blue: 0.94 },
              },
            },
          },
          fields: 'backgroundColor',
        },
      });
    }
  }

  for (let rowIndex = Math.min(tableRows.length, rows.length) - 1; rowIndex >= 0; rowIndex -= 1) {
    const tableCells = tableRows[rowIndex].tableCells || [];
    const row = rows[rowIndex] || [];

    for (let colIndex = Math.min(tableCells.length, row.length) - 1; colIndex >= 0; colIndex -= 1) {
      const text = row[colIndex];
      if (!text) continue;

      const startIndex = tableCells[colIndex].startIndex + 1;
      const isHeader = rowIndex === 0;
      const fields = ['weightedFontFamily', 'fontSize'];
      const textStyle = {
        weightedFontFamily: { fontFamily: 'Arial' },
        fontSize: dimensionPt(10),
      };

      if (isHeader) {
        textStyle.bold = true;
        fields.push('bold');
      }

      requests.push({
        insertText: {
          location: { index: startIndex },
          text,
        },
      });
      requests.push({
        updateTextStyle: {
          range: { startIndex, endIndex: startIndex + text.length },
          textStyle,
          fields: fields.join(','),
        },
      });
    }
  }

  return requests;
}

async function inserirTabelasNativas(docs, docId, tableJobs) {
  if (!tableJobs.length) return;

  // Processa da maior posição para a menor: como cada insercao acontece no
  // proprio ponto do marcador, indices ainda nao processados (menores) nunca
  // sao deslocados, entao todas as tabelas podem ser criadas em 1 unica chamada.
  const jobsDesc = [...tableJobs].sort((a, b) => b.markerStart - a.markerStart);
  const structureRequests = jobsDesc.flatMap((job) => [
    {
      deleteContentRange: {
        range: {
          startIndex: job.markerStart,
          endIndex: job.markerEnd,
        },
      },
    },
    {
      insertTable: {
        rows: job.rows.length,
        columns: job.columnCount,
        location: { index: job.markerStart },
      },
    },
  ]);

  await docs.documents.batchUpdate({
    documentId: docId,
    requestBody: { requests: structureRequests },
  });

  // 1 unica leitura do documento para localizar todas as tabelas inseridas,
  // em vez de 1 leitura por tabela.
  const document = await docs.documents.get({ documentId: docId });
  const tabelasInseridas = (document.data.body?.content || [])
    .filter((element) => element.table)
    .sort((a, b) => a.startIndex - b.startIndex);

  // A ordem relativa das tabelas no documento final corresponde a ordem
  // original dos marcadores (cada insercao substitui seu proprio marcador).
  const jobsAsc = [...tableJobs].sort((a, b) => a.markerStart - b.markerStart);
  const paresOrdenados = jobsAsc.map((job, index) => ({ job, tableElement: tabelasInseridas[index] }));

  paresOrdenados.forEach(({ job, tableElement }) => {
    if (!tableElement) {
      throw new Error(`Nao foi possivel localizar a tabela ${job.marker} no Google Docs.`);
    }
  });

  // Inserir texto em uma tabela desloca os indices de tudo que vem depois dela
  // no documento. Por isso, dentro deste unico batchUpdate, as tabelas devem
  // ser processadas da que esta mais no fim do documento para a que esta mais
  // no inicio (mesma logica ja usada entre celulas de uma mesma tabela).
  const cellRequests = [...paresOrdenados]
    .sort((a, b) => b.tableElement.startIndex - a.tableElement.startIndex)
    .flatMap(({ job, tableElement }) => buildTableCellRequests(tableElement, job.rows));

  if (cellRequests.length) {
    await docs.documents.batchUpdate({
      documentId: docId,
      requestBody: { requests: cellRequests },
    });
  }
}

exports.criarDocFromJson = async (tituloArquivo, documentoJson) => {
  const client = getAuthClient();
  const docs = google.docs({ version: 'v1', auth: client });
  const drive = google.drive({ version: 'v3', auth: client });

  console.log(`📄 Criando Doc estruturado: ${tituloArquivo}`);

  const { id: docId, link } = await criarArquivoDoc(drive, tituloArquivo);
  const builder = new GoogleDocBuilder();
  const requests = builder.buildFromDocumentJson(documentoJson);
  const tableJobs = builder.getTableJobs();

  if (requests.length > 0) {
    await docs.documents.batchUpdate({
      documentId: docId,
      requestBody: { requests },
    });
  }

  if (tableJobs.length > 0) {
    await inserirTabelasNativas(docs, docId, tableJobs);
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
