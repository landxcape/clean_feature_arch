class CoreTemplates {
  // --- Error Handling ---
  static String appError() => r'''
sealed class AppError {
  const AppError(this.message);
  final String message;
}

class NetworkError extends AppError {
  const NetworkError([super.message = 'Network connection failed.']);
}

class ServerError extends AppError {
  const ServerError({required this.statusCode, required String message})
      : super(message);
  final int statusCode;
}

class UnauthorizedError extends AppError {
  const UnauthorizedError([super.message = 'Session expired. Please login again.']);
}

class NotFoundError extends AppError {
  const NotFoundError([super.message = 'Requested resource not found.']);
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

  // --- Dependency Injection ---
  static String injectionContainer(String? stateManager) {
    String stateComment = stateManager == 'riverpod' 
      ? '// Riverpod uses providers for state DI. Use get_it here for infrastructure only.' 
      : '// Register BLoCs as factory: sl.registerFactory(() => FeatureBloc(sl()));';

    return '''
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import '../network/api_client.dart';
import '../network/network_info.dart';
import '../network/network_info_impl.dart';
import '../storage/secure_storage.dart';
import '../storage/secure_storage_impl.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  // --- Core ---
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(InternetConnection()));
  sl.registerLazySingleton<SecureStorage>(() => const SecureStorageImpl(FlutterSecureStorage()));
  
  // --- Network ---
  sl.registerLazySingleton<Dio>(() => ApiClient.create());

  // --- Features ---
  $stateComment
}
''';
  }

  // --- Networking ---
  static String apiClient() => r'''
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

class ApiClient {
  static Dio create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(),
      LoggingInterceptor(),
    ]);
    
    return dio;
  }
}
''';

  static String authInterceptor() => r'''
import 'package:dio/dio.dart';
import '../../di/injection_container.dart';
import '../../storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final storage = sl<SecureStorage>();
    final token = await storage.read('token');
    
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    super.onRequest(options, handler);
  }
}
''';

  static String loggingInterceptor() => r'''
import 'package:dio/dio.dart';
import '../../utils/logger.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    logger.info('NETWORK [REQ] -> ${options.method} ${options.path}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    logger.info('NETWORK [RES] <- ${response.statusCode} ${response.requestOptions.path}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logger.error('NETWORK [ERR] !! ${err.response?.statusCode} ${err.requestOptions.path}');
    super.onError(err, handler);
  }
}
''';

  static String networkInfo() => r'''
abstract interface class NetworkInfo {
  Future<bool> get isConnected;
}
''';

  static String networkInfoImpl() => r'''
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'network_info.dart';

class NetworkInfoImpl implements NetworkInfo {
  const NetworkInfoImpl(this._connection);
  final InternetConnection _connection;

  @override
  Future<bool> get isConnected => _connection.hasInternetAccess;
}
''';

  // --- Storage ---
  static String secureStorage() => r'''
abstract interface class SecureStorage {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> clear();
}
''';

  static String secureStorageImpl() => r'''
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'secure_storage.dart';

class SecureStorageImpl implements SecureStorage {
  const SecureStorageImpl(this._storage);
  final FlutterSecureStorage _storage;

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> clear() => _storage.deleteAll();
}
''';

  // --- Configuration ---
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

  static FlavorConfig? _instance;
  FlavorConfig._internal(this.flavor, this.name);

  static void initialize({required Flavor flavor, required String name}) {
    _instance = FlavorConfig._internal(flavor, name);
  }

  static FlavorConfig get instance => _instance!;
}
''';

  // --- Router ---
  static String appRouter() => r'''
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../constants/route_constants.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: RouteConstants.home,
    routes: [
      GoRoute(
        path: RouteConstants.home,
        name: 'home',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Home')),
        ),
      ),
    ],
  );
}
''';

  static String routeConstants() => r'''
class RouteConstants {
  static const home = '/';
}
''';

  // --- Extensions & Utils ---
  static String contextExtensions() => r'''
import 'package:flutter/material.dart';

extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => mediaQuery.size;
}
''';

  static String stringExtensions() => r'''
extension StringExtensions on String {
  bool get isValidEmail => RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  bool get isNotBlank => trim().isNotEmpty;
}
''';

  static String validatorUtils() => r'''
class ValidatorUtils {
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Field required';
    return null;
  }
}
''';

  // --- UI & Entry Points ---
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
}
''';

  static String mainDart(String? stateManager) {
    String imports = '';
    String observer = '';
    String appWrapper = 'const MyApp()';

    switch (stateManager) {
      case 'bloc':
        imports = "import 'package:flutter_bloc/flutter_bloc.dart';\nimport 'core/utils/logger.dart';";
        observer = r'''
class AppBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    logger.info('BLOC: ${bloc.runtimeType} -> $change');
  }
}
''';
        appWrapper = 'Bloc.observer = AppBlocObserver();\n  runApp(const MyApp())';
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

  // --- Others ---
  static String logger() => r'''
import 'dart:developer' as dev;

class AppLogger {
  void info(String msg) => _log('INFO', msg);
  void error(String msg, {Object? error, StackTrace? stackTrace}) => 
      _log('ERROR', msg, error: error, stackTrace: stackTrace);

  void _log(String level, String msg, {Object? error, StackTrace? stackTrace}) {
    dev.log('[$level] $msg', time: DateTime.now(), error: error, stackTrace: stackTrace);
  }
}
final logger = AppLogger();
''';

  static String typedefs() => r'''
import 'package:fpdart/fpdart.dart';
import '../error/app_error.dart';

typedef Result<T> = Either<AppError, T>;
typedef VoidResult = Either<AppError, Unit>;
''';

  static String analysisOptions() => r'''
include: package:lints/recommended.yaml

plugins:
  clean_feature_arch:
    diagnostics:
      absolute_rule_avoid_illegal_layer_imports: true
      absolute_rule_enforce_feature_isolation: true
      absolute_rule_enforce_model_folder_structure: true
      absolute_rule_prefer_sealed_freezed_models: true
      absolute_rule_enforce_data_source_folder_structure: true
''';

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

  static String sharedButton() => r'''
import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading ? const CircularProgressIndicator() : Text(label),
    );
  }
}
''';

  static String appScaffold() => r'''
import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key, required this.body, this.title});
  final Widget body;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title != null ? AppBar(title: Text(title!)) : null,
      body: SafeArea(child: body),
    );
  }
}
''';
}
