// lib/utils/web_view_initializer_web.dart
//
// Version RÉELLE, utilisée uniquement quand on compile pour le web (import
// conditionnel dans main.dart, sélectionné quand `dart.library.js_interop`
// est disponible). C'est le seul fichier du projet qui importe encore
// `webview_flutter_web` — voir web_view_initializer_stub.dart pour
// l'explication complète.
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';

void initializeWebViewForWeb() {
  WebViewPlatform.instance = WebWebViewPlatform();
}
