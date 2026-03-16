class AppSoftwareConfigModel {
  final String currentVersion;
  final String minRequiredVersion;

  const AppSoftwareConfigModel({
    required this.currentVersion,
    required this.minRequiredVersion,
  });

  static const AppSoftwareConfigModel padrao = AppSoftwareConfigModel(
    currentVersion: '1.0.0.0',
    minRequiredVersion: '1.0.0.0',
  );

  Map<String, dynamic> toMap() {
    return {
      'current_version': currentVersion,
      'min_required_version': minRequiredVersion,
    };
  }

  factory AppSoftwareConfigModel.fromMap(Map<String, dynamic> map) {
    final current = (map['current_version'] as String?)?.trim();
    final minRequired = (map['min_required_version'] as String?)?.trim();

    return AppSoftwareConfigModel(
      currentVersion: current == null || current.isEmpty
          ? AppSoftwareConfigModel.padrao.currentVersion
          : current,
      minRequiredVersion: minRequired == null || minRequired.isEmpty
          ? AppSoftwareConfigModel.padrao.minRequiredVersion
          : minRequired,
    );
  }
}
