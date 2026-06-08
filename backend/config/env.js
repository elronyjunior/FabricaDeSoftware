const path = require('path');
const { google } = require('googleapis');

require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

function requireEnv(name) {
  const value = process.env[name];
  if (value === undefined || value === '') {
    throw new Error(
      `Variável de ambiente obrigatória ausente: ${name}. Configure o arquivo backend/.env`
    );
  }
  return value;
}

function loadFirebaseServiceAccount() {
  return {
    type: 'service_account',
    project_id: requireEnv('FIREBASE_PROJECT_ID'),
    private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
    private_key: requireEnv('FIREBASE_PRIVATE_KEY').replace(/\\n/g, '\n'),
    client_email: requireEnv('FIREBASE_CLIENT_EMAIL'),
    client_id: process.env.FIREBASE_CLIENT_ID,
    auth_uri: 'https://accounts.google.com/o/oauth2/auth',
    token_uri: 'https://oauth2.googleapis.com/token',
    auth_provider_x509_cert_url: 'https://www.googleapis.com/oauth2/v1/certs',
    client_x509_cert_url: process.env.FIREBASE_CLIENT_X509_CERT_URL,
    universe_domain: process.env.FIREBASE_UNIVERSE_DOMAIN || 'googleapis.com',
  };
}

function loadGoogleApiCredentials() {
  return JSON.parse(requireEnv('GOOGLE_API_TOKEN_JSON'));
}

function createGoogleAuthClient() {
  return google.auth.fromJSON(loadGoogleApiCredentials());
}

const db = {
  host: requireEnv('DB_HOST'),
  port: parseInt(process.env.DB_PORT || '5432', 10),
  user: requireEnv('DB_USER'),
  password: requireEnv('DB_PASSWORD'),
  database: requireEnv('DB_NAME'),
};

const firebaseServiceAccount = loadFirebaseServiceAccount();

module.exports = {
  db,
  firebaseServiceAccount,
  port: parseInt(process.env.PORT || '3000', 10),
  jwtSecret: requireEnv('JWT_SECRET'),
  openaiApiKey: process.env.OPENAI_API_KEY,
  openaiModel: process.env.OPENAI_MODEL || 'gpt-4o-mini',
  createGoogleAuthClient,
};
