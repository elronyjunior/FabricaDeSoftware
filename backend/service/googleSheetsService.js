const { google } = require('googleapis');
const { createGoogleAuthClient } = require('../config/env');

const getAuthClient = () => createGoogleAuthClient();

const getSheetsClient = () => {
  const auth = getAuthClient();
  return google.sheets({ version: 'v4', auth });
};

// --- FUNÇÕES AUXILIARES ---

async function _getAbaInfo(sheets, spreadsheetId) {
  const meta = await sheets.spreadsheets.get({
    spreadsheetId,
    fields: 'sheets.properties'
  });
  // Retorna dados da primeira aba (index 0)
  return {
    title: meta.data.sheets[0].properties.title,
    sheetId: meta.data.sheets[0].properties.sheetId
  };
}

function getColumnLetter(colIndex) {
  let temp, letter = '';
  while (colIndex >= 0) {
    temp = (colIndex) % 26;
    letter = String.fromCharCode(temp + 65) + letter;
    colIndex = (colIndex - temp - 1) / 2;
    if(colIndex < 0) break;
  }
  return letter;
}

// --- MÉTODOS PRINCIPAIS ---

// 1. Criar Planilha Inicial (ESTRATÉGIA NOVA: CRIAR -> RENOMEAR)
exports.criarPlanilhaPresenca = async (tituloTreinamento) => {
  try {
    const sheets = getSheetsClient();
    
    // Passo A: Cria planilha padrão (sem definir abas para evitar erro 500)
    const createRes = await sheets.spreadsheets.create({
      resource: { properties: { title: `Presença - ${tituloTreinamento}` } }
    });
    
    const spreadsheetId = createRes.data.spreadsheetId;
    
    // Passo B: Descobre qual é o ID da aba padrão criada (geralmente 0, mas garantimos aqui)
    const abaPadrao = await _getAbaInfo(sheets, spreadsheetId);
    
    // Passo C: Renomeia para 'Chamada' e aplica Negrito (Tudo em um batch)
    await sheets.spreadsheets.batchUpdate({
      spreadsheetId,
      resource: {
        requests: [
          // 1. Renomear aba
          {
            updateSheetProperties: {
              properties: { sheetId: abaPadrao.sheetId, title: 'Chamada' },
              fields: 'title'
            }
          },
          // 2. Negrito na primeira linha
          {
            repeatCell: {
              range: { sheetId: abaPadrao.sheetId, startRowIndex: 0, endRowIndex: 1 },
              cell: { userEnteredFormat: { textFormat: { bold: true } } },
              fields: 'userEnteredFormat.textFormat.bold',
            },
          }
        ]
      },
    });

    // Passo D: Insere o Texto do Cabeçalho
    await sheets.spreadsheets.values.update({
      spreadsheetId,
      range: 'Chamada!A1:B1', // Agora garantimos que se chama Chamada
      valueInputOption: 'RAW',
      resource: { values: [['Nome do Aluno', 'Email']] },
    });

    // Passo E: Permissão Pública
    const drive = google.drive({ version: 'v3', auth: getAuthClient() });
    await drive.permissions.create({
      fileId: spreadsheetId,
      requestBody: { role: 'writer', type: 'anyone' }
    });

    return { id: spreadsheetId, link: createRes.data.spreadsheetUrl };
  } catch (error) {
    console.error("Erro ao criar planilha:", error);
    throw error;
  }
};

exports.lerPlanilhaCompleta = async (spreadsheetId) => {
  try {
    const sheets = getSheetsClient();
    const aba = await _getAbaInfo(sheets, spreadsheetId);
    
    const response = await sheets.spreadsheets.values.get({
      spreadsheetId,
      range: `'${aba.title}'!A:Z`,
    });

    const rows = response.data.values || [];
    if (rows.length === 0) return { headers: [], alunos: [] };

    const headers = rows[0]; 
    const data = rows.slice(1); 

    const alunos = data.map((row, index) => {
      const alunoObj = { 
        rowIndex: index + 2, 
        nome: row[0], 
        email: row[1], 
        presencas: {} 
      };
      
      for (let i = 2; i < headers.length; i++) {
        alunoObj.presencas[headers[i]] = row[i] || ""; 
      }
      return alunoObj;
    });

    return { headers: headers.slice(2), alunos }; 
  } catch (error) {
    console.error("Erro ao ler planilha:", error);
    throw error;
  }
};

exports.adicionarAluno = async (spreadsheetId, nome, email) => {
  try {
    const sheets = getSheetsClient();
    const aba = await _getAbaInfo(sheets, spreadsheetId);
    
    const response = await sheets.spreadsheets.values.get({ spreadsheetId, range: `'${aba.title}'!1:1` });
    const headers = response.data.values ? response.data.values[0] : [];
    const qtdDias = headers.length > 2 ? headers.length - 2 : 0;
    
    const linhaAluno = [nome, email];
    for(let i=0; i<qtdDias; i++) linhaAluno.push("-"); 

    await sheets.spreadsheets.values.append({
      spreadsheetId,
      range: `'${aba.title}'!A:A`,
      valueInputOption: 'USER_ENTERED',
      resource: { values: [linhaAluno] },
    });
    return true;
  } catch (error) {
    console.error("Erro ao add aluno:", error);
    throw error;
  }
};

exports.adicionarDia = async (spreadsheetId, dataTexto) => {
  try {
    const sheets = getSheetsClient();
    const aba = await _getAbaInfo(sheets, spreadsheetId);
    
    const response = await sheets.spreadsheets.values.get({ spreadsheetId, range: `'${aba.title}'!1:1` });
    const headers = response.data.values ? response.data.values[0] : [];
    
    const proximoNumero = (headers.length > 2) ? headers.length - 2 + 1 : 1;
    const dataFinal = dataTexto || new Date().toLocaleDateString('pt-BR', {day:'2-digit', month:'2-digit'});
    const tituloColuna = `Dia ${proximoNumero} (${dataFinal})`;

    const columnLetter = getColumnLetter(headers.length); 

    await sheets.spreadsheets.values.update({
      spreadsheetId,
      range: `'${aba.title}'!${columnLetter}1`,
      valueInputOption: 'USER_ENTERED',
      resource: { values: [[tituloColuna]] },
    });

    return tituloColuna;
  } catch (error) {
    console.error("Erro ao add dia:", error);
    throw error;
  }
};

exports.salvarPresencasLote = async (spreadsheetId, mudancas) => {
  try {
    const sheets = getSheetsClient();
    const aba = await _getAbaInfo(sheets, spreadsheetId);
    
    const data = mudancas.map(m => {
      const diaIdx = parseInt(m.diaIndex);
      const rowIdx = parseInt(m.rowIndex);
      const colunaReal = diaIdx + 2; 
      const letra = getColumnLetter(colunaReal);
      return {
        range: `'${aba.title}'!${letra}${rowIdx}`,
        values: [[m.status]]
      };
    });

    if (data.length === 0) return true;

    await sheets.spreadsheets.values.batchUpdate({
      spreadsheetId,
      resource: {
        valueInputOption: 'USER_ENTERED',
        data: data
      }
    });
    return true;
  } catch (error) {
    console.error("Erro no save batch:", error);
    throw error;
  }
};

exports.removerAluno = async (spreadsheetId, rowIndex) => {
  try {
    const sheets = getSheetsClient();
    const aba = await _getAbaInfo(sheets, spreadsheetId);
    const startIndex = parseInt(rowIndex) - 1;

    await sheets.spreadsheets.batchUpdate({
      spreadsheetId,
      resource: {
        requests: [{
          deleteDimension: {
            range: {
              sheetId: aba.sheetId,
              dimension: "ROWS",
              startIndex: startIndex,
              endIndex: startIndex + 1
            }
          }
        }]
      }
    });
    return true;
  } catch (error) {
    console.error("Erro ao remover aluno:", error);
    throw error;
  }
};

exports.removerDia = async (spreadsheetId, diaIndex) => {
  try {
    const sheets = getSheetsClient();
    const aba = await _getAbaInfo(sheets, spreadsheetId);
    const startIndex = parseInt(diaIndex) + 2; 

    await sheets.spreadsheets.batchUpdate({
      spreadsheetId,
      resource: {
        requests: [{
          deleteDimension: {
            range: {
              sheetId: aba.sheetId,
              dimension: "COLUMNS",
              startIndex: startIndex,
              endIndex: startIndex + 1
            }
          }
        }]
      }
    });
    return true;
  } catch (error) {
    console.error("Erro ao remover dia:", error);
    throw error;
  }
};

exports.deletarArquivo = async (fileId) => {
  try {
    const drive = google.drive({ version: 'v3', auth: getAuthClient() });
    await drive.files.delete({ fileId: fileId });
    console.log(`✅ Arquivo Drive ${fileId} deletado.`);
    return true;
  } catch (error) {
    console.error("Erro ao deletar arquivo do Drive:", error.message);
    throw error; 
  }
};