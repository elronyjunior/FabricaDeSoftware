const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });
const { authenticate } = require('@google-cloud/local-auth');

const SCOPES = [
  'https://www.googleapis.com/auth/documents',
  'https://www.googleapis.com/auth/drive',
];

async function main() {
  const clientJson = process.env.GOOGLE_OAUTH_CLIENT_JSON;
  if (!clientJson) {
    console.error(
      'Defina GOOGLE_OAUTH_CLIENT_JSON no .env (conteúdo do antigo credentials.json).'
    );
    process.exit(1);
  }

  const keys = JSON.parse(clientJson);
  const key = keys.installed || keys.web;
  const keyfilePath = path.join(__dirname, '_oauth_client.tmp.json');
  const fs = require('fs').promises;
  await fs.writeFile(keyfilePath, JSON.stringify({ installed: key }));

  console.log('Abrindo navegador para você fazer login...');
  const client = await authenticate({
    scopes: SCOPES,
    keyfilePath,
  });

  await fs.unlink(keyfilePath).catch(() => {});

  if (client.credentials) {
    const payload = JSON.stringify({
      type: 'authorized_user',
      client_id: key.client_id,
      client_secret: key.client_secret,
      refresh_token: client.credentials.refresh_token,
    });
    console.log('\n✅ Login OK. Cole esta linha no seu .env:\n');
    console.log(`GOOGLE_API_TOKEN_JSON=${payload}`);
  }
}

main().catch(console.error);
