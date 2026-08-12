import 'env_config.dart';

class StagingConfig implements EnvConfig {
  @override
  String get apiBaseUrl => 'https://staging.api.archpharma.com/api/v1';

  @override
  bool get enableDebugLogs => true;
}
