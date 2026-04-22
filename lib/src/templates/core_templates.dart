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

  static String injectionContainer(String? stateManager) {
    String comment = '';
    if (stateManager == 'riverpod') {
      comment =
          '\n  // Note: Riverpod uses providers for DI within the widget tree.\n  // Use get_it here only for infrastructure (Dio, Storage, etc.).';
    } else if (stateManager == 'bloc') {
      comment =
          '\n  // Register features, repositories, and BLoCs here.\n  // Always register BLoCs as Factory: sl.registerFactory(() => MyBloc(sl()));';
    }

    return '''
import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  // TODO: Register infrastructure modules and feature dependencies.$comment
}
''';
  }

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

    // TODO: Add required interceptors (authentication, logging, etc.)
    
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
include: package:lints/recommended.yaml

plugins:
  clean_feature_arch:
    diagnostics:
      absolute_rule_avoid_illegal_layer_imports: true
      absolute_rule_enforce_feature_isolation: true
      absolute_rule_enforce_model_folder_structure: true
      absolute_rule_prefer_sealed_freezed_models: true
      absolute_rule_enforce_data_source_folder_structure: true

# The Absolute Rule linter is integrated natively into dart analyze.
''';
  }

  static String buildYaml() => r'''
targets:
  $default:
    builders:
      freezed:freezed:
        enabled: true
      json_serializable:
        enabled: true
        options:
          explicit_to_json: true
''';

  static String mainDart(String? stateManager) {
    String imports = '';
    String observer = '';
    String appWrapper = 'const MyApp()';

    switch (stateManager) {
      case 'bloc':
        imports =
            "import 'package:flutter_bloc/flutter_bloc.dart';\nimport 'core/utils/logger.dart';";
        observer = r'''
class AppBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    logger.info('Bloc Change: ${bloc.runtimeType} -> $change');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    logger.error('Bloc Error: ${bloc.runtimeType}', error: error, stackTrace: stackTrace);
    super.onError(bloc, error, stackTrace);
  }
}
''';
        appWrapper = '''
  Bloc.observer = AppBlocObserver();
  runApp(const MyApp())''';
        break;
      case 'riverpod':
        imports = "import 'package:flutter_riverpod/flutter_riverpod.dart';";
        appWrapper = 'runApp(const ProviderScope(child: MyApp()))';
        break;
      default:
        appWrapper = 'runApp(const MyApp())';
    }

    return '''
import 'package:flutter/material.dart';
$imports
import 'app.dart';
import 'core/di/injection_container.dart';

$observer

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await configureDependencies();
  
  $appWrapper;
}
''';
  }

  static String appDart() => r'''
import 'package:flutter/material.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter App',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
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

  // --- New Production Infrastructure Templates ---

  static String appConfig() => r'''
class AppConfig {
  static const String baseUrl = String.fromEnvironment('BASE_URL', defaultValue: 'https://api.example.com');
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
''';

  static String flavorConfig() => r'''
enum Flavor { dev, staging, prod }

class FlavorConfig {
  final Flavor flavor;
  final String name;
  final String apiBaseUrl;

  static FlavorConfig? _instance;

  FlavorConfig._internal(this.flavor, this.name, this.apiBaseUrl);

  static void initialize({
    required Flavor flavor,
    required String name,
    required String apiBaseUrl,
  }) {
    _instance = FlavorConfig._internal(flavor, name, apiBaseUrl);
  }

  static FlavorConfig get instance => _instance!;
}
''';

  static String appRouter() => r'''
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Home')),
        ),
      ),
    ],
  );
}
''';

  static String appTheme() => r'''
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ),
  );
}
''';

  static String appColors() => r'''
import 'package:flutter/material.dart';

class AppColors {
  static const primary = Colors.deepPurple;
  static const secondary = Colors.amber;
  static const error = Colors.red;
}
''';

  static String networkInfo() => r'''
abstract interface class NetworkInfo {
  Future<bool> get isConnected;
}

// Implementation for connectivity status.
''';

  static String secureStorage() => r'''
abstract interface class SecureStorage {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
}
''';

  static String sharedButton() => r'''
import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading 
        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
        : Text(label),
    );
  }
}
''';
}
