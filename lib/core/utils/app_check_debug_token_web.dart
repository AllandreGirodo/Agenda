import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

Future<void> configureAppCheckDebugToken(String? debugToken) async {
  final host = web.window.location.hostname;
  final isLocalhost =
      host == 'localhost' ||
      host == '127.0.0.1' ||
      host == '0.0.0.0' ||
      host == '::1';

  if (!isLocalhost) {
    return;
  }

  final hasExplicitToken = debugToken != null && debugToken.isNotEmpty;
  if (!hasExplicitToken) {
    (web.window as JSObject).setProperty(
      'FIREBASE_APPCHECK_DEBUG_TOKEN'.toJS,
      false.toJS,
    );
    return;
  }

  (web.window as JSObject).setProperty(
    'FIREBASE_APPCHECK_DEBUG_TOKEN'.toJS,
    debugToken.toJS,
  );
}
