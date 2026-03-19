import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agenda/core/models/changelog_model.dart';
import 'package:agenda/core/models/usuario_model.dart';
import 'package:agenda/core/services/app_governance_service.dart';
import 'package:agenda/core/utils/app_strings.dart';

class AppGovernanceDialogs {
  static Future<void> showForceUpdateDialog(
    BuildContext context, {
    required String localVersion,
    required String minRequiredVersion,
    required String currentVersion,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.system_update, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(child: Text(AppStrings.atualizacaoObrigatoriaTitulo)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.atualizacaoObrigatoriaMensagem(
                  localVersion,
                  minRequiredVersion,
                ),
              ),
              const SizedBox(height: 12),
              Text(AppStrings.versaoAtualInstalada(localVersion)),
              Text(AppStrings.versaoMinimaExigida(minRequiredVersion)),
              Text(AppStrings.versaoSistemaDisponivel(currentVersion)),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(AppStrings.entendiBtn),
            ),
          ],
        );
      },
    );
  }

  static Future<bool> showChangelogDialog(
    BuildContext context, {
    required ChangeLogModel changelog,
    required bool initialShowAuto,
  }) async {
    var showAuto = initialShowAuto;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.teal),
                  const SizedBox(width: 8),
                  Expanded(child: Text(AppStrings.novidadesSistemaTitulo)),
                ],
              ),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      changelog.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(AppStrings.versaoSistemaDisponivel(changelog.versao)),
                    if (changelog.isCritical) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          AppStrings.changelogCritico,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Flexible(
                      child: changelog.modifications.isEmpty
                          ? Text(AppStrings.semNovidadesRegistradas)
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: changelog.modifications.length,
                              itemBuilder: (context, index) {
                                final item = changelog.modifications[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(top: 2),
                                        child: Icon(
                                          Icons.fiber_manual_record,
                                          size: 10,
                                          color: Colors.teal,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(item)),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: showAuto,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (value) {
                        setDialogState(() {
                          showAuto = value ?? true;
                        });
                      },
                      title: Text(AppStrings.exibirNovidadesAutomaticamente),
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(showAuto),
                  child: Text(AppStrings.fechar),
                ),
              ],
            );
          },
        );
      },
    );

    return result ?? initialShowAuto;
  }

  /// Processa o resultado pós-login de verificação de governance.
  /// 
  /// Exibe diálogos apropriados (atualização forçada, changelog) e navega para
  /// a tela de login se necessário. Este método consolida a lógica duplicada
  /// que existia em [AgendamentoView] e [AdminAgendamentosView].
  /// 
  /// [loginViewBuilder] é um callback para construir a [LoginView] sem criar
  /// uma dependency cíclica.
  static Future<void> processarResultadoGovernanca(
    BuildContext context, {
    required AppGovernanceCheckResult resultado,
    required UsuarioModel usuario,
    required AppGovernanceService governanceService,
    required String uid,
    required WidgetBuilder loginViewBuilder,
  }) async {
    if (!context.mounted) return;

    if (resultado.forceUpdate) {
      await showForceUpdateDialog(
        context,
        localVersion: resultado.localVersion,
        minRequiredVersion: resultado.minRequiredVersion,
        currentVersion: resultado.currentVersion,
      );

      if (!context.mounted) return;

      await FirebaseAuth.instance.signOut();

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: loginViewBuilder),
          (route) => false,
        );
      }
      return;
    }

    if (!resultado.shouldShowChangelog || resultado.changelog == null) return;

    final manterExibicaoAutomatica = await showChangelogDialog(
      context,
      changelog: resultado.changelog!,
      initialShowAuto: usuario.showChangelogAuto,
    );

    if (!context.mounted) return;

    await governanceService.registrarVisualizacaoChangelog(
      uid: uid,
      versao: resultado.currentVersion,
      manterExibicaoAutomatica: manterExibicaoAutomatica,
    );
  }
}
