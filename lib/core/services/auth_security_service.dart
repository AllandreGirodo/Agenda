import 'package:agenda/core/services/firestore_service.dart';

enum AuthAttemptAction {
  login,
  passwordReset,
}

class AuthAttemptDecision {
  final bool allowed;
  final Duration? retryAfter;

  const AuthAttemptDecision({
    required this.allowed,
    this.retryAfter,
  });
}

class _AuthAttemptBucket {
  final List<DateTime> attempts = <DateTime>[];
  DateTime? lastIncidentAt;
}

class AuthSecurityService {
  static const int _maxAttemptsPerMinute = 5;
  static const Duration _window = Duration(minutes: 1);
  static const Duration _incidentCooldown = Duration(minutes: 3);
  static final Map<String, _AuthAttemptBucket> _buckets = <String, _AuthAttemptBucket>{};

  final FirestoreService _firestoreService = FirestoreService();

  AuthAttemptDecision canAttempt(String email, AuthAttemptAction action) {
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail.isEmpty) {
      return const AuthAttemptDecision(allowed: true);
    }

    final bucket = _getBucket(normalizedEmail, action);
    _purgeOldAttempts(bucket);

    if (bucket.attempts.length >= _maxAttemptsPerMinute) {
      final retryAfter = _window - DateTime.now().difference(bucket.attempts.first);
      return AuthAttemptDecision(
        allowed: false,
        retryAfter: retryAfter.isNegative ? Duration.zero : retryAfter,
      );
    }

    return const AuthAttemptDecision(allowed: true);
  }

  Future<AuthAttemptDecision> registerFailedLogin(String email, {String? motivo}) async {
    return _registerAttempt(
      email,
      AuthAttemptAction.login,
      motivo: motivo,
      source: 'login',
    );
  }

  Future<AuthAttemptDecision> registerPasswordResetRequest(String email) async {
    return _registerAttempt(
      email,
      AuthAttemptAction.passwordReset,
      source: 'esqueceu_senha',
    );
  }

  Future<AuthAttemptDecision> registerBlockedAttempt(
    String email,
    AuthAttemptAction action,
  ) async {
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail.isEmpty) {
      return const AuthAttemptDecision(allowed: false);
    }

    final bucket = _getBucket(normalizedEmail, action);
    _purgeOldAttempts(bucket);

    final retryAfter = bucket.attempts.isEmpty
        ? _window
        : (_window - DateTime.now().difference(bucket.attempts.first));

    await _logIncidentIfNeeded(
      normalizedEmail,
      action,
      bucket,
      motivo: 'limite_excedido',
      retryAfter: retryAfter.isNegative ? Duration.zero : retryAfter,
    );

    return AuthAttemptDecision(
      allowed: false,
      retryAfter: retryAfter.isNegative ? Duration.zero : retryAfter,
    );
  }

  Future<AuthAttemptDecision> _registerAttempt(
    String email,
    AuthAttemptAction action, {
    String? motivo,
    required String source,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail.isEmpty) {
      return const AuthAttemptDecision(allowed: true);
    }

    final bucket = _getBucket(normalizedEmail, action);
    _purgeOldAttempts(bucket);
    final now = DateTime.now();
    bucket.attempts.add(now);

    if (bucket.attempts.length > _maxAttemptsPerMinute) {
      final retryAfter = _window - now.difference(bucket.attempts.first);
      await _logIncidentIfNeeded(
        normalizedEmail,
        action,
        bucket,
        motivo: motivo ?? source,
        retryAfter: retryAfter.isNegative ? Duration.zero : retryAfter,
      );

      return AuthAttemptDecision(
        allowed: false,
        retryAfter: retryAfter.isNegative ? Duration.zero : retryAfter,
      );
    }

    return const AuthAttemptDecision(allowed: true);
  }

  Future<void> _logIncidentIfNeeded(
    String email,
    AuthAttemptAction action,
    _AuthAttemptBucket bucket, {
    String? motivo,
    required Duration retryAfter,
  }) async {
    final now = DateTime.now();
    if (bucket.lastIncidentAt != null && now.difference(bucket.lastIncidentAt!) < _incidentCooldown) {
      return;
    }

    bucket.lastIncidentAt = now;

    final actionLabel = action == AuthAttemptAction.login ? 'login' : 'esqueceu_senha';
    final retryAt = now.add(retryAfter).toIso8601String();
    final mensagem = 'Seguranca auth: limite excedido para $actionLabel | email=$email | tentativas=${bucket.attempts.length} | motivo=${motivo ?? 'nao_informado'} | retry_at=$retryAt';

    await _firestoreService.registrarLogPublicoSegurancaAuth(mensagem);
  }

  _AuthAttemptBucket _getBucket(String email, AuthAttemptAction action) {
    final key = '${action.name}:$email';
    return _buckets.putIfAbsent(key, () => _AuthAttemptBucket());
  }

  void _purgeOldAttempts(_AuthAttemptBucket bucket) {
    final cutoff = DateTime.now().subtract(_window);
    bucket.attempts.removeWhere((attempt) => attempt.isBefore(cutoff));
  }

  String _normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }
}
