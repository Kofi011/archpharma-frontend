import 'package:dio/dio.dart';
import '../services/logger_service.dart';

class ApiErrorHandler {
  /// Converts any [Object] (especially [DioException]) into a user-friendly error message.
  /// 
  /// Logs the detailed technical error message for debugging/development
  /// without exposing any sensitive information (passwords, tokens).
  static String handle(Object error, {String? context}) {
    if (error is DioException) {
      final safeRequestUrl = error.requestOptions.uri.toString();
      final safeMethod = error.requestOptions.method;
      
      // Safe detailed logging (excluding sensitive request body fields)
      LoggerService.error(
        'API Error caught in $safeMethod $safeRequestUrl [Type: ${error.type}]',
        tag: 'API-Error',
      );
      
      if (error.response != null) {
        final statusCode = error.response!.statusCode;
        final responseData = error.response!.data;
        
        LoggerService.error(
          'HTTP Status Code: $statusCode',
          tag: 'API-Error',
        );

        if (statusCode == 401) {
          return 'Invalid username or password. Please try again.';
        }

        if (statusCode == 403) {
          return 'Access denied. You do not have permission to perform this action.';
        }

        if (statusCode == 404) {
          return 'Requested resource not found on server.';
        }

        if (statusCode != null && statusCode >= 500) {
          return 'Server error ($statusCode). Please contact administration or try again later.';
        }

        // Extract custom server error messages if present
        if (responseData is Map && responseData.containsKey('message')) {
          final msg = responseData['message'];
          if (msg is List) {
            return msg.join(', ');
          }
          if (msg is String && msg.isNotEmpty) {
            return msg;
          }
        }
      }

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Request timeout. Please check your connection speed and try again.';
        case DioExceptionType.connectionError:
          return 'Server unreachable. Please verify the API server is online.';
        case DioExceptionType.badCertificate:
          return 'Secure connection failed (bad certificate).';
        case DioExceptionType.cancel:
          return 'Request was cancelled.';
        case DioExceptionType.unknown:
        default:
          final errorStr = error.error?.toString() ?? '';
          if (errorStr.contains('SocketException') || errorStr.contains('Network') || errorStr.contains('Failed host lookup')) {
            return 'No internet connection. Please verify your Wi-Fi or cellular network.';
          }
          return 'Connection failed. Please check your network and try again.';
      }
    }

    // Generic fallback for non-Dio exceptions
    LoggerService.error('Unexpected error: $error', tag: 'API-Error');
    return 'An unexpected error occurred. Please try again.';
  }
}
