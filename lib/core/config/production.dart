import 'env_config.dart';

class ProductionConfig implements EnvConfig {
  @override
  String get apiBaseUrl => 'https://api.archpharma.com/api/v1';

  @override
  bool get enableDebugLogs => false;
}
