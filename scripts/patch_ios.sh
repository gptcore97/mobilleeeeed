#!/bin/sh
# Da lanciare su macOS dalla cartella del progetto DOPO "npx cap add ios" (idempotente).
# Aggiunge a Info.plist: permessi (foto, fotocamera, microfono, dettatura), rete locale (LM Studio ecc.)
# e lo schema URL per il ritorno dal login Google.
PB="${PB:-/usr/libexec/PlistBuddy}"
P=ios/App/App/Info.plist
[ -f "$P" ] || { echo "Non trovo $P: lancia lo script dalla cartella del progetto, dopo 'npx cap add ios'."; exit 1; }

setstr() {   # chiave valore
  "$PB" -c "Set :$1 $2" "$P" 2>/dev/null || "$PB" -c "Add :$1 string $2" "$P"
}
setstr NSCameraUsageDescription "GPT CORE usa la fotocamera per allegare foto alle domande."
setstr NSPhotoLibraryUsageDescription "GPT CORE legge le immagini che scegli dalla galleria per allegarle alle domande."
setstr NSMicrophoneUsageDescription "GPT CORE usa il microfono per la dettatura vocale."
setstr NSSpeechRecognitionUsageDescription "GPT CORE trasforma la tua voce in testo per la dettatura."
setstr NSLocalNetworkUsageDescription "GPT CORE può collegarsi a modelli in esecuzione sulla tua rete locale."
"$PB" -c "Print :NSAppTransportSecurity" "$P" >/dev/null 2>&1 || "$PB" -c "Add :NSAppTransportSecurity dict" "$P"
"$PB" -c "Set :NSAppTransportSecurity:NSAllowsLocalNetworking true" "$P" 2>/dev/null || "$PB" -c "Add :NSAppTransportSecurity:NSAllowsLocalNetworking bool true" "$P"

# schema URL Google = ID client iOS "al contrario": NNN-xxx.apps.googleusercontent.com -> com.googleusercontent.apps.NNN-xxx
IOS_ID=$(node -p "((require('./config.json').google||{}).ios_client_id)||''" 2>/dev/null)
if [ -n "$IOS_ID" ]; then
  SCHEME="com.googleusercontent.apps.${IOS_ID%.apps.googleusercontent.com}"
  if ! "$PB" -c "Print :CFBundleURLTypes" "$P" >/dev/null 2>&1; then
    "$PB" -c "Add :CFBundleURLTypes array" "$P"
    "$PB" -c "Add :CFBundleURLTypes:0 dict" "$P"
    "$PB" -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes array" "$P"
    "$PB" -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string $SCHEME" "$P"
  else
    "$PB" -c "Print :CFBundleURLTypes" "$P" | grep -q "$SCHEME" || {
      N=$("$PB" -c "Print :CFBundleURLTypes" "$P" | grep -c 'Dict {')
      "$PB" -c "Add :CFBundleURLTypes:$N dict" "$P"
      "$PB" -c "Add :CFBundleURLTypes:$N:CFBundleURLSchemes array" "$P"
      "$PB" -c "Add :CFBundleURLTypes:$N:CFBundleURLSchemes:0 string $SCHEME" "$P"
    }
  fi
  echo "Schema URL Google: $SCHEME"
else
  echo "google.ios_client_id vuoto in config.json: login Google su iPhone non configurato."
fi
echo "Info.plist: ok"
