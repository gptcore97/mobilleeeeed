# GPT CORE Mobile

App mobile (solo API) derivata da GPT CORE. Niente modelli locali, niente terminale.

## Cosa c'è dentro
| Voce | Dove | Note |
|---|---|---|
| Menu API | Pillola in alto (dove in Gemini c'è "Gemini Advanced") | Elenca le API aggiunte, tocca per cambiare |
| Store API | Menu ☰ → Store API | Stesso flusso di gpt_store_api: provider → chiave verificata → modelli → nome → test → salvataggio |
| Mail | Menu ☰ → Mail | Scrivi, scheda di conferma, codice MSG-…, storico con esito |
| Web | Automatico | Il modello emette `[[CERCA: …]]`, l'app cerca e risponde (come gpt_web) |
| config.json | Memoria locale dell'app | Compilato dallo Store; Impostazioni → Importa config.json per portare dentro chiavi/prompt |

## Provarla subito (browser)
Servi la cartella con un server statico (es. `python -m http.server`) e apri `index.html` dal telefono.
Nel browser: alcuni provider possono bloccare le chiamate (CORS) e la ricerca web usa solo Wikipedia.

## Creare l'APK (consigliato: rete nativa, niente CORS, ricerca web completa)
```
npm init -y
npm i @capacitor/core @capacitor/cli @capacitor/android
mkdir www && cp index.html style.css core.js app.js manifest.webmanifest icon.svg icon-192.png icon-512.png www/
npx cap init "GPT CORE" it.flubatir.gptcore --web-dir www   # oppure usa capacitor.config.json incluso
npx cap add android
npx cap sync
npx cap open android      # Android Studio → Build → Build APK
```
Nell'app nativa il codice usa `CapacitorHttp` (già incluso in @capacitor/core) per ricerca web e ripiego delle API.

## Mail: configurazione (una volta)
Il vecchio gpt_mail usava SMTP con la password app nel file: un'app mobile non può farlo (le app si decompilano).
Ora l'invio passa da EmailJS (gratuito):
1. emailjs.com → Email Services → collega il Gmail mittente → copia **Service ID**.
2. Email Templates → nuovo: *To* = indirizzo dell'amministratore, *Subject* = `{{subject}}`, *Reply-To* = `{{reply_to}}`, corpo = `{{message}}` → copia **Template ID**.
3. Account → **Public Key**.
4. Nell'app: Mail → Configurazione invio → incolla i tre valori.
Il destinatario sta nel template, non nell'app.
