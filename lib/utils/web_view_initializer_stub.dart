// lib/utils/web_view_initializer_stub.dart
//
// Version "stub" (no-op) utilisée sur toutes les plateformes SAUF le web
// (Android, iOS, desktop). Sélectionnée automatiquement par l'import
// conditionnel dans main.dart quand `dart.library.js_interop` n'est PAS
// disponible (donc hors web).
//
// Pourquoi ce fichier existe : `main.dart` importait auparavant
// `package:webview_flutter_web/webview_flutter_web.dart` directement, sans
// condition. Même protégé par `if (kIsWeb)` à l'exécution, cet import reste
// résolu par le compilateur pour TOUTES les cibles — or ce package utilise
// `package:web`/`dart:js_interop`, qui n'existent pas pour la cible Android.
// Résultat : "'JSObject' isn't a type" et échec total de la compilation
// Android. En isolant l'appel réel derrière un import conditionnel avec un
// stub identique en signature, `webview_flutter_web` n'est plus jamais tiré
// dans la compilation Android.
void initializeWebViewForWeb() {
  // Rien à faire hors web.
}
