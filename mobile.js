import os from 'os';
import { spawn } from 'child_process';
import qrcode from 'qrcode-terminal';
import http from 'http';

// Get Local IP
function getLocalIp() {
  const interfaces = os.networkInterfaces();
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        return iface.address;
      }
    }
  }
  return 'localhost';
}

const PORT = 5173;
const ip = getLocalIp();
const localUrl = `http://${ip}:${PORT}`;

console.log('🚀 Iniciando servidor Vite en host abierto...');

// Start Vite process
const viteProcess = spawn('npx', ['vite', '--host', '0.0.0.0', '--port', PORT], {
  stdio: 'inherit',
  shell: true
});

viteProcess.on('error', (err) => {
  console.error('Error iniciando Vite:', err);
});

// Start ngrok CLI process
const ngrokProcess = spawn('npx', ['ngrok', 'http', PORT.toString()], {
  stdio: 'ignore', // Ignore output to keep terminal clean
  shell: true
});

// Helper to fetch from local ngrok API
function getNgrokUrl() {
  return new Promise((resolve, reject) => {
    http.get('http://127.0.0.1:4040/api/tunnels', (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          const json = JSON.parse(data);
          const tunnel = json.tunnels.find(t => t.public_url.startsWith('https'));
          if (tunnel) resolve(tunnel.public_url);
          else reject(new Error('No HTTPS tunnel found'));
        } catch (e) {
          reject(e);
        }
      });
    }).on('error', reject);
  });
}

// Wait for ngrok to initialize and fetch URL
setTimeout(async () => {
  console.log('\n🌐 Conectando a ngrok...');
  let attempts = 0;
  let publicUrl = null;

  while (attempts < 5 && !publicUrl) {
    try {
      publicUrl = await getNgrokUrl();
    } catch (e) {
      attempts++;
      await new Promise(r => setTimeout(r, 1000));
    }
  }

  if (publicUrl) {
    console.log('\n=============================================');
    console.log(`📱 RED LOCAL (WIFI): ${localUrl}`);
    console.log(`🌍 LINK PÚBLICO:     ${publicUrl}`);
    console.log('=============================================\n');
    
    console.log('► Escanea el código QR para abrir el LINK PÚBLICO en tu celular:');
    qrcode.generate(publicUrl, { small: true });
    
    console.log('\n(Para terminar, presiona Ctrl + C)');
  } else {
    console.log('\n=============================================');
    console.log(`📱 RED LOCAL (WIFI): ${localUrl}`);
    console.log('=============================================\n');
    console.error('⚠️ No se pudo obtener el link público de ngrok.');
    console.error('Asegúrate de tener ngrok configurado (ngrok authtoken <token>)');
    console.error('Puedes acceder a la app usando la RED LOCAL desde tu celular.');
  }
}, 3000);

// Handle termination
process.on('SIGINT', () => {
  console.log('\nCerrando servidor y túnel ngrok...');
  ngrokProcess.kill();
  viteProcess.kill();
  process.exit();
});
