const { port: PORT } = require('./config/env');
const app = require('./app');

app.listen(PORT, () => {
  console.log(`Servidor rodando em http://localhost:${PORT}`);
});
