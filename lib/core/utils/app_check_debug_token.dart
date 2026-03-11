import 'app_check_debug_token_stub.dart'
    if (dart.library.html) 'app_check_debug_token_web.dart';

Future<void> configureWebAppCheckDebugToken(String? debugToken) {
  return configureAppCheckDebugToken(debugToken);
}
