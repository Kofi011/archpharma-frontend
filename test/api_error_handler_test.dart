import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:archpharma/core/utils/api_error_handler.dart';

void main() {
  group('ApiErrorHandler Tests', () {
    test('Handles 401 Unauthorized correctly', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 401,
          data: {'message': 'Unauthorized'},
        ),
        type: DioExceptionType.badResponse,
      );

      final message = ApiErrorHandler.handle(dioException);
      expect(message, equals('Invalid username or password. Please try again.'));
    });

    test('Handles 403 Forbidden correctly', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/products'),
        response: Response(
          requestOptions: RequestOptions(path: '/products'),
          statusCode: 403,
          data: {'message': 'Forbidden'},
        ),
        type: DioExceptionType.badResponse,
      );

      final message = ApiErrorHandler.handle(dioException);
      expect(message, contains('Access denied.'));
    });

    test('Handles 500 Internal Server Error correctly', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/products'),
        response: Response(
          requestOptions: RequestOptions(path: '/products'),
          statusCode: 500,
          data: {'message': 'Internal Server Error'},
        ),
        type: DioExceptionType.badResponse,
      );

      final message = ApiErrorHandler.handle(dioException);
      expect(message, contains('Server error (500).'));
    });

    test('Handles Timeout correctly', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/products'),
        type: DioExceptionType.connectionTimeout,
      );

      final message = ApiErrorHandler.handle(dioException);
      expect(message, contains('Request timeout.'));
    });

    test('Handles SocketException / No internet connection correctly', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/products'),
        type: DioExceptionType.unknown,
        error: 'SocketException: Failed host lookup',
      );

      final message = ApiErrorHandler.handle(dioException);
      expect(message, contains('No internet connection.'));
    });

    test('Handles Generic unexpected exception correctly', () {
      final message = ApiErrorHandler.handle(ArgumentError('Invalid input'));
      expect(message, contains('An unexpected error occurred.'));
    });
  });
}
