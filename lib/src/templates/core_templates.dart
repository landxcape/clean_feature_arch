class CoreTemplates {
  // --- Error Handling ---
  static String appError() => r'''
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_error.freezed.dart';

@freezed
sealed class AppError with _$AppError {
  const factory AppError.network([@Default('Network connection failed.') String message]) = NetworkError;
  const factory AppError.server({required int statusCode, required String message}) = ServerError;
  const factory AppError.unauthorized([@Default('Session expired.') String message]) = UnauthorizedError;
  const factory AppError.notFound([@Default('Resource not found.') String message]) = NotFoundError;
  const factory AppError.unknown([@Default('An unexpected error occurred.') String message]) = UnknownError;
}
''';

  static String baseResponse() => r'''
import 'package:freezed_annotation/freezed_annotation.dart';

part 'base_response.freezed.dart';
part 'base_response.g.dart';

/// Interface to allow ErrorHandler to probe for success without generation dependency.
abstract interface class IBaseResponse {
  bool get success;
  String get message;
}

@Freezed(genericArgumentFactories: true)
sealed class BaseResponse<T> with _$BaseResponse<T> implements IBaseResponse {
  const factory BaseResponse({
    required bool success,
    required String message,
    T? data,
  }) = _BaseResponse<T>;

  factory BaseResponse.fromJson(Map<String, dynamic> json, T Function(Object?) fromJsonT) => 
      _$BaseResponseFromJson(json, fromJsonT);
}
''';

  static String errorHandler(String projectName) => '''
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:$projectName/core/utils/logger.dart';
import 'package:$projectName/core/error/app_error.dart';
import 'package:$projectName/core/network/base_response.dart';

class ErrorHandler {
  const ErrorHandler._();

  static Future<Either<AppError, T>> guard<T>(Future<T> Function() action) async {
    try {
      final result = await action();
      
      final dynamic dynamicResult = result;
      if (dynamicResult is BaseResponse && !dynamicResult.success) {
        return Left(
          AppError.server(
            statusCode: 200,
            message: dynamicResult.message,
          ),
        );
      }
      
      return Right(result);
    } on DioException catch (e) {
      return Left(_mapDioException(e));
    } catch (e, stack) {
      logger.error(
        'Unhandled exception',
        error: e,
        stackTrace: stack,
      );
      return Left(const AppError.unknown());
    }
  }

  static AppError _mapDioException(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout || 
      DioExceptionType.sendTimeout || 
      DioExceptionType.receiveTimeout => const AppError.network('Connection timed out.'),
      _ => _mapStatusCode(
          e.response?.statusCode,
          e.response?.data,
        ),
    };
  }

  static AppError _mapStatusCode(int? code, dynamic data) {
    return switch ((code, data)) {
      (401, _) => const AppError.unauthorized(),
      (404, _) => const AppError.notFound(),
      (int c, {'message': String m}) when c >= 500 => AppError.server(
          statusCode: c,
          message: m,
        ),
      (int c, _) when c >= 500 => AppError.server(
          statusCode: c,
          message: 'Server error.',
        ),
      _ => const AppError.unknown(),
    };
  }
}
''';

  // --- Networking ---
  static String apiClient(String projectName) => '''
import 'package:dio/dio.dart';
import 'package:$projectName/core/config/app_config.dart';
import 'package:$projectName/core/network/interceptors/auth_interceptor.dart';
import 'package:$projectName/core/network/interceptors/logging_interceptor.dart';

class ApiClient {
  static Dio create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
      ),
    );

    dio.interceptors.add(AuthInterceptor());
    dio.interceptors.add(loggingInterceptor());

    return dio;
  }
}
''';

  static String authInterceptor(String projectName) => '''
import 'package:dio/dio.dart';
import 'package:$projectName/core/di/injection_container.dart';
import 'package:$projectName/core/storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final storage = sl<SecureStorage>();
    final token = await storage.read('token');

    if (token != null) {
      options.headers['Authorization'] = 'Bearer \$token';
    }

    super.onRequest(options, handler);
  }
}
''';

  static String loggingInterceptor() => r'''
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

/// Professional API logging interceptor.
PrettyDioLogger loggingInterceptor() => PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      error: true,
      compact: true,
      maxWidth: 90,
    );
''';

  static String networkInfo() => r'''
abstract interface class NetworkInfo {
  Future<bool> get isConnected;
}
''';

  static String networkInfoImpl(String projectName) => '''
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:$projectName/core/network/network_info.dart';

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

  static String appFlavor() => r'''
enum AppFlavor {
  dev(baseUrl: 'https://api.dev.com', name: 'DEV'),
  prod(baseUrl: 'https://api.prod.com', name: 'PROD');

  const AppFlavor({required this.baseUrl, required this.name});
  final String baseUrl;
  final String name;
}
''';

  static String appBootstrap(String projectName, String? stateManager) {
    final riverpodImport = stateManager == 'riverpod' 
        ? "import 'package:flutter_riverpod/flutter_riverpod.dart';\n" 
        : "";
    
    return '''
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
$riverpodImport
import 'package:$projectName/core/di/injection_container.dart';
import 'package:$projectName/core/localization/app_locales.dart';

typedef BootstrapResult = ({Widget app});

class AppBootstrap {
  /// Initializes core services and returns the configured root widget.
  static Future<BootstrapResult> init({
    required Widget app,
    String? stateManager,
    Widget Function(Widget)? stateWrapper,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();
    await configureDependencies();

    // Use Switch Expression for state management wrapping
    final stateApp = switch (stateManager) {
      'riverpod' => _wrapRiverpod(app),
      _ => stateWrapper?.call(app) ?? app,
    };

    final localizedApp = EasyLocalization(
      supportedLocales: AppLocales.supported,
      path: AppLocales.path,
      fallbackLocale: AppLocales.en.locale,
      child: stateApp,
    );

    return (app: localizedApp);
  }

  static Widget _wrapRiverpod(Widget child) {
    return ${stateManager == 'riverpod' ? 'ProviderScope(child: child)' : 'child'};
  }
}
''';
  }

  // --- Localization ---
  static String appLocales() => r'''
import 'package:flutter/material.dart';

enum AppLocales {
  en(Locale('en', 'US')),
  ne(Locale('ne', 'NP'));

  const AppLocales(this.locale);
  final Locale locale;

  static List<Locale> get supported => values.map((e) => e.locale).toList();
  static String get path => 'assets/translations';
}
''';

  static String appStrings() => r'''
import 'package:easy_localization/easy_localization.dart';

class AppStrings {
  static String get example => 'example'.tr();
}
''';

  static String emptyJson() => r'''
{}
''';

  // --- Dependency Injection ---
  static String coreModuleFile(String projectName) => '''
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import 'package:$projectName/core/network/api_client.dart';
import 'package:$projectName/core/network/network_info.dart';
import 'package:$projectName/core/network/network_info_impl.dart';
import 'package:$projectName/core/storage/secure_storage.dart';
import 'package:$projectName/core/storage/secure_storage_impl.dart';
import 'package:$projectName/core/utils/permission_service.dart';

class CoreModule {
  static Future<void> init(GetIt sl) async {
    // --- Infrastructure ---
    sl.registerLazySingleton<NetworkInfo>(
      () => NetworkInfoImpl(
        InternetConnection(),
      ),
    );
    sl.registerLazySingleton<SecureStorage>(
      () => const SecureStorageImpl(
        FlutterSecureStorage(),
      ),
    );
    sl.registerLazySingleton<PermissionService>(
      () => PermissionServiceImpl(),
    );
    
    // --- Network ---
    sl.registerLazySingleton<Dio>(
      () => ApiClient.create(),
    );
  }
}
''';

  static String injectionContainer(String projectName) => '''
import 'package:get_it/get_it.dart';
import 'package:$projectName/core/di/modules/core_module.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  // --- Core ---
  await CoreModule.init(sl);

  // --- Features ---
}
''';

  // --- Router ---
  static String appRouter(String projectName) => '''
import 'package:go_router/go_router.dart';
import 'package:$projectName/core/constants/route_constants.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: RouteConstants.root,
    routes: [
      // TODO: Add feature routes
    ],
  );
}
''';

  static String routeConstants() => r'''
class RouteConstants {
  static const String root = '/';
}
''';

  static String assetConstants() => r'''
class AssetConstants {
  static const String _imagePath = 'assets/images';
  static const String _iconPath = 'assets/icons';

  // --- Icons ---
  // static const String logo = '$_iconPath/logo.svg';

  // --- Images ---
  // static const String placeholder = '$_imagePath/placeholder.png';
}
''';

  static String appConstants() => r'''
class AppConstants {
  static const String appName = 'Absolute App';
  static const String appVersion = '1.0.0';
  
  // Design Dimensions (Target)
  static const double designWidth = 375.0;
  static const double designHeight = 812.0;
}
''';

  // --- Theme ---
  static String appTheme(String projectName) => '''
import 'package:flutter/material.dart';
import 'package:$projectName/core/theme/app_colors.dart';
import 'package:$projectName/core/theme/app_text_theme.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
        ),
        textTheme: AppTextTheme.light,
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ),
        textTheme: AppTextTheme.dark,
      );
}
''';

  static String appColors() => r'''
import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF6200EE);
}
''';

  static String appSpacing() => r'''
class AppSpacing {
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s16 = 16.0;
}
''';

  static String appTextTheme() => r'''
import 'package:flutter/material.dart';

class AppTextTheme {
  static TextTheme get light => const TextTheme();
  static TextTheme get dark => const TextTheme();
}
''';

  // --- CI/CD ---
  static String githubVerify() => r'''
name: Verify
on: [push, pull_request]
jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
''';

  static String gitlabCI() => r'''
stages:
  - test
verify:
  stage: test
  image: "ghcr.io/cirruslabs/flutter:stable"
  script:
    - flutter pub get
    - flutter analyze
    - flutter test
''';

  // --- Utils ---
  static String validatorUtils() => r'''
class ValidatorUtils {
  static String? required(String? value) => value == null || value.isEmpty ? 'Field required' : null;
}
''';

  static String responsiveUtils() => r'''
import 'package:flutter/material.dart';

extension ResponsiveExtension on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 1200;
  bool get isDesktop => screenWidth >= 1200;

  double get scaleWidth => screenWidth / 375.0; // Based on designWidth
  double get scaleHeight => screenHeight / 812.0;
}

extension SizeExtension on num {
  double h(BuildContext context) => this * (MediaQuery.sizeOf(context).height / 812.0);
  double w(BuildContext context) => this * (MediaQuery.sizeOf(context).width / 375.0);
}
''';

  static String contextExtensions() => r'''
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

extension ContextExtensions on BuildContext {
  // Theme
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;
  
  // UI / Responsive
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  EdgeInsets get padding => MediaQuery.paddingOf(this);
  
  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 1200;
  bool get isDesktop => screenWidth >= 1200;

  // i18n
  String translate(String key) => tr(key);
}
''';

  static String stringExtensions() => r'''
extension StringExtensions on String {
  bool get isValidEmail => RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
}
''';

  static String permissionService() => r'''
import 'package:permission_handler/permission_handler.dart';

abstract interface class PermissionService {
  Future<void> openSettings();
}

class PermissionServiceImpl implements PermissionService {
  @override
  Future<void> openSettings() async {
    await openAppSettings();
  }
}
''';

  static String apiClientTest(String projectName) => '''
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:$projectName/core/network/api_client.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late Dio dio;

  setUp(() {
    dio = ApiClient.create();
  });

  test(
    'ApiClient should be configured with correct timeouts',
    () {
      expect(dio.options.connectTimeout?.inSeconds, 15);
      expect(dio.options.receiveTimeout?.inSeconds, 15);
    },
  );
}
''';

  static String appDart(String projectName) => '''
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:$projectName/core/router/app_router.dart';
import 'package:$projectName/core/theme/app_theme.dart';

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
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    );
  }
}
''';

  static String mainDart(String? stateManager, String projectName) {
    String stateImport = '';
    String observer = '';
    String initArgs = "app: const MyApp(), stateManager: '$stateManager'";

    if (stateManager == 'bloc') {
      stateImport =
          "import 'package:flutter_bloc/flutter_bloc.dart';\nimport 'package:$projectName/core/utils/logger.dart';\n";
      observer = r'''
class AppBlocObserver extends BlocObserver {
  @override
  void onChange(
    BlocBase bloc,
    Change change,
  ) {
    super.onChange(bloc, change);
    logger.info('BLOC: ${bloc.runtimeType} -> $change');
  }
}
''';
      initArgs += r''',
    stateWrapper: (child) {
      Bloc.observer = AppBlocObserver();
      return child;
    }''';
    }

    return '''
import 'package:flutter/material.dart';
import 'package:$projectName/core/config/app_bootstrap.dart';
$stateImport
import 'package:$projectName/app.dart';

void main() async {
  final (:app) = await AppBootstrap.init(
    $initArgs,
  );

  runApp(app);
}

$observer
''';
  }

  static String logger() => r'''
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Contract for production error reporting (e.g., Sentry, Crashlytics).
abstract interface class LogReporter {
  void report(String message, {Object? error, StackTrace? stackTrace});
}

class AppLogger {
  AppLogger({this.reporter})
      : _logger = Logger(
          printer: PrettyPrinter(
            methodCount: 0,
            errorMethodCount: 8,
            lineLength: 120,
            colors: true,
            printEmojis: true,
            dateTimeFormat: DateTimeFormat.none,
          ),
          filter: DevelopmentFilter(),
        );

  final LogReporter? reporter;
  final Logger _logger;

  void info(String msg) => _logger.i(msg);

  void error(String msg, {Object? error, StackTrace? stackTrace}) {
    _logger.e(msg, error: error, stackTrace: stackTrace);

    if (kReleaseMode) {
      reporter?.report(msg, error: error, stackTrace: stackTrace);
    }
  }

  void debug(String msg) => _logger.d(msg);
  void warning(String msg) => _logger.w(msg);
}

final logger = AppLogger();
''';

  static String typedefs(String projectName) => '''
import 'package:fpdart/fpdart.dart';
import 'package:$projectName/core/error/app_error.dart';

typedef Result<T> = Either<AppError, T>;
typedef VoidResult = Either<AppError, Unit>;
''';

  static String analysisOptions() => r'''
include: package:flutter_lints/flutter.yaml

analyzer:
  exclude:
    - "lib/**.g.dart"
    - "lib/**.freezed.dart"
    - "lib/generated_plugin_registrant.dart"
    - "bin/**.g.dart"
    - "bin/**.freezed.dart"
    - "android/**"
    - "ios/**"
    - "windows/**"
    - "linux/**"
    - "macos/**"
    - "web/**"
    - ".dart_tool/**"
    - "build/**"
  plugins:
    - clean_feature_arch
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true

formatter:
  page_width: 150

linter:
  rules:
    prefer_single_quotes: true
    require_trailing_commas: true
    always_use_package_imports: true

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
