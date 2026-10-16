#!/bin/sh
# Da lanciare dalla cartella del progetto DOPO "npx cap add android" (idempotente).
#  1) spegne i backup Android (altrimenti chiavi API e chat finiscono nei backup)
#  2) permesso fotocamera (pulsante Fotocamera), senza escludere i telefoni senza camera
#  3) MainActivity per il plugin di login Google (richiesto dalla sua guida Android)
M=android/app/src/main/AndroidManifest.xml
[ -f "$M" ] || { echo "Non trovo $M: lancia lo script dalla cartella del progetto, dopo 'npx cap add android'."; exit 1; }
sed -i 's/android:allowBackup="true"/android:allowBackup="false"/' "$M"
grep -q 'android.permission.CAMERA' "$M" || sed -i 's#<uses-permission android:name="android.permission.INTERNET" />#&\n    <uses-permission android:name="android.permission.CAMERA" />\n    <uses-feature android:name="android.hardware.camera" android:required="false" />#' "$M"
grep -q 'allowBackup="false"' "$M" && echo "allowBackup: OFF  ok" || { echo "ERRORE: allowBackup non modificato"; exit 1; }
grep -q 'permission.CAMERA' "$M" && echo "CAMERA: ok" || { echo "ERRORE: permesso CAMERA non aggiunto"; exit 1; }

MA=$(find android/app/src/main/java -name MainActivity.java 2>/dev/null | head -n 1)
[ -n "$MA" ] || { echo "ERRORE: MainActivity.java non trovata"; exit 1; }
PKG=$(grep -m1 '^package ' "$MA" | sed 's/package \(.*\);/\1/')
cat > "$MA" <<JAVA
package $PKG;

import android.content.Intent;
import android.util.Log;
import com.getcapacitor.BridgeActivity;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginHandle;
import ee.forgr.capacitor.social.login.GoogleProvider;
import ee.forgr.capacitor.social.login.ModifiedMainActivityForSocialLoginPlugin;
import ee.forgr.capacitor.social.login.SocialLoginPlugin;

public class MainActivity extends BridgeActivity implements ModifiedMainActivityForSocialLoginPlugin {

  @Override
  public void onActivityResult(int requestCode, int resultCode, Intent data) {
    super.onActivityResult(requestCode, resultCode, data);
    if (requestCode >= GoogleProvider.REQUEST_AUTHORIZE_GOOGLE_MIN && requestCode < GoogleProvider.REQUEST_AUTHORIZE_GOOGLE_MAX) {
      PluginHandle pluginHandle = getBridge().getPlugin("SocialLogin");
      if (pluginHandle == null) { Log.i("Google Activity Result", "SocialLogin login handle is null"); return; }
      Plugin plugin = pluginHandle.getInstance();
      if (!(plugin instanceof SocialLoginPlugin)) { Log.i("Google Activity Result", "SocialLogin plugin instance is not SocialLoginPlugin"); return; }
      ((SocialLoginPlugin) plugin).handleGoogleLoginIntent(requestCode, data);
    }
  }

  // Non viene mai chiamato: serve solo come marcatore richiesto dal plugin.
  @Override
  public void IHaveModifiedTheMainActivityForTheUseWithSocialLoginPlugin() {}
}
JAVA
echo "MainActivity (login Google): ok"
