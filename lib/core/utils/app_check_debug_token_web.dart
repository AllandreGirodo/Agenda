import 'dart:js_util' as js_util;

import 'package:web/web.dart' as web;

Future<void> configureAppCheckDebugToken(String? debugToken) async {
  final host = web.window.location.hostname;
  final isLocalhost = host == 'localhost' || host == '127.0.0.1';

  if (!isLocalhost) {
    return;
  }

  js_util.setProperty(
    web.window,
    'FIREBASE_APPCHECK_DEBUG_TOKEN',
    debugToken != null && debugToken.isNotEmpty ? debugToken : true,
  );
}
