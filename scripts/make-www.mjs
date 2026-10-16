// Copia i file web dell'app in www/ (la cartella che Capacitor impacchetta) e controlla config.json.
import { cpSync, existsSync, mkdirSync, readFileSync, rmSync } from 'node:fs';

const FILES = ['index.html', 'style.css', 'core.js', 'app.js', 'config.json', 'manifest.webmanifest', 'icon.svg', 'icon-192.png', 'icon-512.png'];
const missing = FILES.filter(f => !existsSync(f));
if (missing.length) { console.error('File mancanti: ' + missing.join(', ')); process.exit(1); }

let cfg;
try { cfg = JSON.parse(readFileSync('config.json', 'utf8')); }
catch (e) { console.error('config.json non è un JSON valido: ' + e.message); process.exit(1); }

rmSync('www', { recursive: true, force: true });
mkdirSync('www');
for (const f of FILES) cpSync(f, 'www/' + f);
// sw.js serve solo al browser/PWA: nell'app installata non viene usato

const warn = [];
if (!cfg.mail || !cfg.mail.service || !cfg.mail.template || !cfg.mail.key) warn.push('mail: dati EmailJS vuoti -> l\'invio mail sarà disattivato');
if (!cfg.google || !cfg.google.web_client_id) warn.push('google.web_client_id vuoto -> il pulsante "Accedi con Google" non comparirà');
else if (!cfg.google.ios_client_id) warn.push('google.ios_client_id vuoto -> il login Google su iPhone non funzionerà');
if (!cfg.help || !cfg.help.email) warn.push('help.email vuoto -> nella schermata Aiuto non comparirà l\'email');
console.log('www/ pronta (' + FILES.length + ' file).');
for (const w of warn) console.log('  avviso: ' + w);
