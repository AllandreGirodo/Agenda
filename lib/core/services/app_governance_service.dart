import 'package:agenda/core/models/changelog_model.dart';
import 'package:agenda/core/models/usuario_model.dart';
import 'package:agenda/core/services/firestore_service.dart';

class AppGovernanceCheckResult {
  final String localVersion;
  final String currentVersion;
  final String minRequiredVersion;
  final bool forceUpdate;
  final bool shouldShowChangelog;
  final ChangeLogModel? changelog;

  const AppGovernanceCheckResult({
    required this.localVersion,
    required this.currentVersion,
    required this.minRequiredVersion,
    required this.forceUpdate,
    required this.shouldShowChangelog,
    required this.changelog,
  });
}

class AppGovernanceService {
  final FirestoreService _firestoreService;

  AppGovernanceService({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService();

  Future<AppGovernanceCheckResult> verificarPosLogin(
    UsuarioModel usuario,
  ) async {
    final localVersion = await _firestoreService.getVersaoLocalAplicativo();
    final config = await _firestoreService.getAppSoftwareConfig();

    final forceUpdate =
        _compararVersoes(localVersion, config.minRequiredVersion) < 0;

    final lastSeen = (usuario.lastChangelogSeen ?? '').trim();
    final shouldShowChangelog =
        !forceUpdate &&
        (usuario.showChangelogAuto || lastSeen != config.currentVersion);

    ChangeLogModel? changelog;
    if (shouldShowChangelog) {
      changelog =
          await _firestoreService.getAppChangelogByVersion(
            config.currentVersion,
          ) ??
          await _firestoreService.getLatestAppChangelog();
    }

    return AppGovernanceCheckResult(
      localVersion: localVersion,
      currentVersion: config.currentVersion,
      minRequiredVersion: config.minRequiredVersion,
      forceUpdate: forceUpdate,
      shouldShowChangelog: shouldShowChangelog && changelog != null,
      changelog: changelog,
    );
  }

  Future<void> registrarVisualizacaoChangelog({
    required String uid,
    required String versao,
    required bool manterExibicaoAutomatica,
  }) async {
    await _firestoreService.marcarChangelogComoVisto(uid, versao);
    await _firestoreService.atualizarPreferenciaAutoChangelog(
      uid,
      manterExibicaoAutomatica,
    );
  }

  int _compararVersoes(String v1, String v2) {
    final a = _partesVersao(v1);
    final b = _partesVersao(v2);
    final maxLen = a.length > b.length ? a.length : b.length;

    for (var i = 0; i < maxLen; i++) {
      final ai = i < a.length ? a[i] : 0;
      final bi = i < b.length ? b[i] : 0;
      if (ai != bi) return ai.compareTo(bi);
    }

    return 0;
  }

  List<int> _partesVersao(String versao) {
    final normalized = versao.trim().replaceFirst(RegExp(r'^[vV]'), '');
    if (normalized.isEmpty) return const <int>[0];

    final chunks = normalized
        .split(RegExp(r'[^0-9]+'))
        .where((chunk) => chunk.isNotEmpty)
        .map((chunk) => int.tryParse(chunk) ?? 0)
        .toList();

    if (chunks.isEmpty) return const <int>[0];
    return chunks;
  }
}
