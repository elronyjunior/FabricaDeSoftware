const jwt = require('jsonwebtoken');
const { jwtSecret } = require('../../config/env');

// Gera um token JWT válido para os testes de integração baterem em rotas
// protegidas por authenticateToken, sem precisar passar pelo fluxo de login.
function gerarTokenTeste(payload = { id: 1, email: 'teste@fabrica.com', nivel: 'USUARIO' }) {
  return jwt.sign(payload, jwtSecret, { expiresIn: '1h' });
}

module.exports = { gerarTokenTeste };
