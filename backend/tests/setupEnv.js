const path = require('path');

// Em CI, as variáveis de ambiente já vêm do workflow. Localmente, o
// desenvolvedor pode copiar .env.test.example para .env.test e rodar contra
// um Postgres descartável. Se o arquivo não existir, isto não faz nada.
require('dotenv').config({ path: path.join(__dirname, '..', '.env.test') });
