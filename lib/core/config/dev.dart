import 'env_config.dart';

class DevConfig implements EnvConfig {
  @override
  String get apiBaseUrl => 'http://192.168.0.110:3000/api/v1';

  @override
  bool get enableDebugLogs => true;
}
