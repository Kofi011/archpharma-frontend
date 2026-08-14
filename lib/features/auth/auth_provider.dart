import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../../data/datasource/api_client.dart';
import '../../core/services/logger_service.dart';
import '../../core/utils/api_error_handler.dart';
import '../settings/settings_provider.dart';

enum UserRole { admin, cashier, storekeeper, accountant }

class UserSession {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String token;

  const UserSession({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.token,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isCashier => role == UserRole.cashier;
  bool get isStorekeeper => role == UserRole.storekeeper;
  bool get isAccountant => role == UserRole.accountant;

  bool canManageUsers() => isAdmin;
  bool canCreateInvoices() => isAdmin || isCashier;
  bool canManageStock() => isAdmin || isStorekeeper;
  bool canViewFinancialReports() => isAdmin || isAccountant;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role.name,
    'token': token,
  };

  factory UserSession.fromJson(Map<String, dynamic> json) => UserSession(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    role: UserRole.values.firstWhere(
      (r) => r.name == json['role'],
      orElse: () => UserRole.cashier,
    ),
    token: json['token'] as String,
  );
}

class AuthNotifier extends StateNotifier<UserSession?> {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage;

  AuthNotifier(this._apiClient, this._storage) : super(null) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    try {
      final sessionStr = await _storage.read(key: 'user_session');
      if (sessionStr != null) {
        state = UserSession.fromJson(jsonDecode(sessionStr) as Map<String, dynamic>);
      }
    } catch (e) {
      LoggerService.error('Auth state validation failed', error: e, tag: 'Auth');
      await logout();
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {
          'email': email.trim(),
          'password': password,
        },
      );

      final data = response.data;
      final token = data['access_token'] as String;
      final userData = data['user'] as Map<String, dynamic>;

      final session = UserSession(
        id: userData['id'] as String,
        name: userData['name'] as String,
        email: userData['email'] as String,
        role: UserRole.values.firstWhere(
          (r) => r.name.toLowerCase() == (userData['role'] as String).toLowerCase(),
          orElse: () => UserRole.cashier,
        ),
        token: token,
      );

      await _storage.write(key: 'jwt_token', value: token);
      await _storage.write(key: 'user_session', value: jsonEncode(session.toJson()));

      state = session;
    } catch (e) {
      final userFriendlyMsg = ApiErrorHandler.handle(e);
      throw Exception(userFriendlyMsg);
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.post('/auth/logout');
    } catch (e) {
      LoggerService.warning('Failed to post logout request to server: $e', tag: 'Auth');
    }

    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_session');
    state = null;
  }

  void switchRole(UserRole role) {
    if (state != null) {
      final updated = UserSession(
        id: state!.id,
        name: state!.name,
        email: state!.email,
        role: role,
        token: state!.token,
      );
      _storage.write(key: 'user_session', value: jsonEncode(updated.toJson()));
      state = updated;
    }
  }
}

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final settings = ref.watch(settingsProvider);
  final client = ApiClient(storage, baseUrl: settings.apiEndpoint);

  client.dio.interceptors.add(
    InterceptorsWrapper(
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401 && e.requestOptions.path != '/auth/login') {
          LoggerService.warning('Global Interceptor: 401 Unauthorized detected. Auto-logging out.', tag: 'Auth');
          ref.read(authProvider.notifier).logout();
        }
        return handler.next(e);
      },
    ),
  );

  return client;
});

final authProvider = StateNotifierProvider<AuthNotifier, UserSession?>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthNotifier(apiClient, storage);
});
