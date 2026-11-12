const { spawn } = require('child_process');
const path = require('path');

console.log('🚀 SmartBus serverlari ishga tushirilmoqda...\n');

const backend = spawn('node', ['server.js'], {
  cwd: path.join(__dirname, 'smartbus_backend'),
  stdio: 'inherit',
  shell: true
});

const dispetcher = spawn('node', ['server.js'], {
  cwd: path.join(__dirname, 'dispetcher'),
  stdio: 'inherit',
  shell: true
});

backend.on('error', (err) => console.error('Backend xatosi:', err));
dispetcher.on('error', (err) => console.error('Dispetcher xatosi:', err));

process.on('SIGINT', () => {
  backend.kill();
  dispetcher.kill();
  process.exit();
});

