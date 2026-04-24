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
    final String stateComment = stateManager == 'riverpod'
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
import '../utils/permission_service.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  // --- Core ---
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(InternetConnection()));
  sl.registerLazySingleton<SecureStorage>(() => const SecureStorageImpl(FlutterSecureStorage()));
  sl.registerLazySingleton<PermissionService>(() => PermissionServiceImpl());
  
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

  static String localSettings() => r'''
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class LocalSettings {
  Future<void> setBool(String key, bool value);
  bool? getBool(String key);
  Future<void> setString(String key, String value);
  String? getString(String key);
  Future<void> remove(String key);
}

class LocalSettingsImpl implements LocalSettings {
  const LocalSettingsImpl(this._prefs);
  final SharedPreferences _prefs;

  @override
  bool? getBool(String key) => _prefs.getBool(key);

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  Future<void> remove(String key) => _prefs.remove(key);

  @override
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  @override
  Future<void> setString(String key, String value) => _prefs.setString(key, value);
}
''';

  static String driftDatabase(String projectName) {
    return '''
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

@DriftDatabase(tables: [])
// TODO: Register feature-specific tables here:
// import '../../features/auth/data/data_sources/local_data_sources/auth_table.dart';
// @DriftDatabase(tables: [AuthTable])
class AppDatabase extends _\$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}
''';
  }

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
import '../theme/app_spacing.dart';

extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => mediaQuery.size;
  
  EdgeInsets get paddingAllSmall => const EdgeInsets.all(AppSpacing.s8);
  EdgeInsets get paddingAllMedium => const EdgeInsets.all(AppSpacing.s16);
  EdgeInsets get paddingAllLarge => const EdgeInsets.all(AppSpacing.s32);
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

  static String permissionService() => r'''
import 'package:permission_handler/permission_handler.dart';

abstract interface class PermissionService {
  Future<bool> isGranted(Permission permission);
  Future<void> openSettings();
}

class PermissionServiceImpl implements PermissionService {
  @override
  Future<bool> isGranted(Permission permission) async {
    return permission.isGranted;
  }

  @override
  Future<void> openSettings() async {
    await openAppSettings();
  }
}
''';

  // --- Design System ---
  static String appTheme() => r'''
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_theme.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ),
    textTheme: AppTextTheme.light,
    elevatedButtonTheme: _elevatedButtonTheme,
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ),
    textTheme: AppTextTheme.dark,
    elevatedButtonTheme: _elevatedButtonTheme,
  );

  static final _elevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      minimumSize: const Size.fromHeight(50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
''';

  static String appColors() => r'''
import 'package:flutter/material.dart';

class AppColors {
  static const primary = Colors.deepPurple;
  static const secondary = Colors.amber;
  static const success = Colors.green;
  static const error = Colors.red;
}
''';

  static String appSpacing() => r'''
class AppSpacing {
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;
  static const double s48 = 48.0;
  static const double s64 = 64.0;
}
''';

  static String appTextTheme() => r'''
import 'package:flutter/material.dart';

class AppTextTheme {
  static const TextTheme light = TextTheme(
    headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
    bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
    bodyMedium: TextStyle(fontSize: 14, color: Colors.black54),
  );

  static const TextTheme dark = TextTheme(
    headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
    bodyLarge: TextStyle(fontSize: 16, color: Colors.white70),
    bodyMedium: TextStyle(fontSize: 14, color: Colors.white60),
  );
}
''';

  // --- CI/CD ---
  static String githubVerify() => r'''
name: Verify

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
          cache: true
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Verify formatting
        run: dart format --set-exit-if-changed .
      
      - name: Analyze project
        run: flutter analyze
      
      - name: Run tests
        run: flutter test
''';

  static String gitlabCI() => r'''
image: "ghcr.io/cirruslabs/flutter:stable"

stages:
  - test

verify:
  stage: test
  script:
    - flutter pub get
    - dart format --set-exit-if-changed .
    - flutter analyze
    - flutter test
''';

  // --- Testing ---
  static String apiClientTest() => r'''
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:your_project/core/network/api_client.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late Dio dio;

  setUp(() {
    dio = ApiClient.create();
  });

  test('ApiClient should be configured with correct timeouts', () {
    expect(dio.options.connectTimeout?.inSeconds, 15);
    expect(dio.options.receiveTimeout?.inSeconds, 15);
  });
}
''';

  // --- App Structure ---
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
    logger.info('BLOC: ${bloc.runtimeType} -> $change');
  }
}
''';
        appWrapper =
            'Bloc.observer = AppBlocObserver();\n  runApp(const MyApp())';
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
