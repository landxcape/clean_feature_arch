class CoreTemplates {
  static String appError() => r'''
sealed class AppError {
  const AppError(this.message);
  final String message;
}

class NetworkError extends AppError {
  const NetworkError([super.message = 'Network error occurred.']);
}

class ServerError extends AppError {
  const ServerError({required this.statusCode, required String message})
      : super(message);
  final int statusCode;
}

class UnauthorizedError extends AppError {
  const UnauthorizedError([super.message = 'Session expired.']);
}

class NotFoundError extends AppError {
  const NotFoundError([super.message = 'Resource not found.']);
}

class CacheError extends AppError {
  const CacheError([super.message = 'Local storage error.']);
}

class UnknownError extends AppError {
  const UnknownError([super.message = 'An unexpected error occurred.']);
}
''';

  static String errorHandler() => r'''
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import '../utils/logger.dart';
import 'app_error.dart';

class ErrorHandler {
  const ErrorHandler._();

  static Future<Either<AppError, T>> guard<T>(
    Future<T> Function() action,
  ) async {
    try {
      final result = await action();
      return Right(result);
    } on DioException catch (e) {
      return Left(_mapDioException(e));
    } on FormatException catch (e, stack) {
      logger.error('Format exception', error: e, stackTrace: stack);
      return Left(const UnknownError('Invalid response format.'));
    } catch (e, stack) {
      logger.error('Unhandled exception', error: e, stackTrace: stack);
      return Left(const UnknownError());
    }
  }

  static AppError _mapDioException(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout =>
        const NetworkError('Connection timed out.'),
      DioExceptionType.connectionError => const NetworkError(),
      _ => _mapStatusCode(e.response?.statusCode),
    };
  }

  static AppError _mapStatusCode(int? code) {
    return switch (code) {
      401 => const UnauthorizedError(),
      404 => const NotFoundError(),
      int c when c >= 500 => ServerError(statusCode: c, message: 'Server error.'),
      _ => const UnknownError(),
    };
  }
}
''';

  static String injectionContainer() => r'''
import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  // TODO: Register network modules, features, etc.
  // Example: sl.registerLazySingleton<Dio>(() => DioFactory.create());
}
''';

  static String apiClient() => r'''
import 'package:dio/dio.dart';

class ApiClient {
  static Dio create() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    // TODO: Add interceptors (Auth, Logging)
    
    return dio;
  }
}
''';

  static String typedefs() => r'''
import 'package:fpdart/fpdart.dart';
import '../error/app_error.dart';

typedef Result<T> = Either<AppError, T>;
typedef VoidResult = Either<AppError, Unit>;
''';

  static String analysisOptions() {
    return '''
analyzer:
  plugins:
    - custom_lint

# The Absolute Rule linter is enabled by default via custom_lint.
# Rules: 
# - absolute_rule_avoid_illegal_layer_imports
# - absolute_rule_enforce_feature_isolation
# - absolute_rule_prefer_sealed_freezed_models
# - absolute_rule_enforce_model_folder_structure
''';
  }

  static String mainDart() => r'''
import 'package:flutter/material.dart';
import 'app.dart';
import 'core/di/injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await configureDependencies();
  
  runApp(const MyApp());
}
''';

  static String appDart() => r'''
import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Absolute Rule Architecture Initialized'),
        ),
      ),
    );
  }
}
''';

  static String logger() => r'''
import 'dart:developer' as dev;

class AppLogger {
  void info(String message) => _log('INFO', message);
  void warn(String message) => _log('WARN', message);
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    _log('ERROR', message, error: error, stackTrace: stackTrace);
  }

  void _log(String level, String message, {Object? error, StackTrace? stackTrace}) {
    dev.log(
      '[$level] $message',
      time: DateTime.now(),
      error: error,
      stackTrace: stackTrace,
    );
  }
}

final logger = AppLogger();
''';
}
