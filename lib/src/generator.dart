import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:recase/recase.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:yaml/yaml.dart';
import 'templates/domain_templates.dart';
import 'templates/data_templates.dart';
import 'templates/presentation_templates.dart';
import 'templates/core_templates.dart';
import 'templates/test_templates.dart';
import 'commands/permission_command.dart';

/// Overwrite strategy for file conflicts.
enum OverwriteStrategy { ask, always, skipAll }

/// Generates architectural layers and core utilities.
class FeatureGenerator {
  /// Creates a [FeatureGenerator] with the provided [Logger].
  FeatureGenerator(this._logger);

  final Logger _logger;

  /// The current strategy for handling file conflicts.
  OverwriteStrategy _strategy = OverwriteStrategy.ask;

  /// Scaffolds a feature directory structure at [targetDirectory].
  Future<void> generate(String name,
      {String? targetDirectory,
      String? stateManager,
      String? storageType,
      bool force = false}) async {
    final snakeCaseName = name.snakeCase;
    final baseDir = targetDirectory ?? p.join('lib', 'features', snakeCaseName);
    final projectName = _getProjectName();

    _strategy = force ? OverwriteStrategy.always : OverwriteStrategy.ask;

    _logger.info('Generating feature: ${lightCyan.wrap(snakeCaseName)}...');

    final progress = _logger.progress('Generating layers');

    try {
      // 1. Detect Available Storage
      final dbExists = await File('lib/core/storage/app_database.dart').exists();
      final prefsExists =
          await File('lib/core/storage/local_settings.dart').exists();

      String? storageSelection = (storageType == 'none') ? null : storageType;

      if (storageSelection == null &&
          storageType != 'none' &&
          (dbExists || prefsExists)) {
        final options = ['None'];
        if (dbExists) {
          options.add('Drift (SQL)');
        }
        if (prefsExists) {
          options.add('Shared Preferences');
        }

        if (options.length > 1) {
          final choice = _logger.chooseOne(
            'Which storage should feature "$snakeCaseName" use?',
            choices: options,
            defaultValue: 'None',
          );
          if (choice == 'Drift (SQL)') {
            storageSelection = 'drift';
          }
          if (choice == 'Shared Preferences') {
            storageSelection = 'shared';
          }
        }
      }

      // 2. Domain Layer
      await _createFile(
          p.join(baseDir, 'domain', 'entities', '${snakeCaseName}_entity.dart'),
          DomainTemplates.entity(snakeCaseName));
      await _createFile(
          p.join(baseDir, 'domain', 'repositories',
              '${snakeCaseName}_repository.dart'),
          DomainTemplates.repository(snakeCaseName, projectName));
      await _createFile(
          p.join(baseDir, 'domain', 'usecases', 'get_${snakeCaseName}_usecase.dart'),
          DomainTemplates.usecase(snakeCaseName, projectName));

      // 3. Data Layer
      await _createFile(
          p.join(baseDir, 'data', 'models', 'requests',
              '${snakeCaseName}_request_model.dart'),
          DataTemplates.requestModel(snakeCaseName));
      await _createFile(
          p.join(baseDir, 'data', 'models', 'responses',
              '${snakeCaseName}_response_model.dart'),
          DataTemplates.responseModel(snakeCaseName, projectName));
      await _createFile(
          p.join(baseDir, 'data', 'models', 'local',
              '${snakeCaseName}_local_model.dart'),
          DataTemplates.localModel(snakeCaseName, projectName));

      await _createFile(
          p.join(baseDir, 'data', 'data_sources', 'remote_data_sources',
              '${snakeCaseName}_remote_data_source.dart'),
          DataTemplates.remoteDataSource(snakeCaseName, projectName));
      await _createFile(
          p.join(baseDir, 'data', 'data_sources', 'local_data_sources',
              '${snakeCaseName}_local_data_source.dart'),
          DataTemplates.localDataSource(snakeCaseName, projectName,
              storageType: storageSelection));
      await _createFile(
          p.join(baseDir, 'data', 'repositories',
              '${snakeCaseName}_repository_impl.dart'),
          DataTemplates.repositoryImpl(snakeCaseName, projectName));

      // 4. Presentation Layer
      final stateFolderName = stateManager == 'bloc'
          ? 'bloc'
          : (stateManager == 'riverpod' ? 'providers' : 'state');

      await _createFile(
          p.join(baseDir, 'presentation', 'screens', '${snakeCaseName}_screen.dart'),
          PresentationTemplates.screen(snakeCaseName, projectName,
              stateManager: stateManager, stateFolderName: stateFolderName));

      final stateDir = p.join(baseDir, 'presentation', stateFolderName);
      await Directory(stateDir).create(recursive: true);

      switch (stateManager) {
        case 'bloc':
          await _createFile(p.join(stateDir, '${snakeCaseName}_bloc.dart'),
              PresentationTemplates.bloc(snakeCaseName, projectName));
          await _createFile(p.join(stateDir, '${snakeCaseName}_event.dart'),
              PresentationTemplates.blocEvent(snakeCaseName));
          await _createFile(p.join(stateDir, '${snakeCaseName}_state.dart'),
              PresentationTemplates.blocState(snakeCaseName));
          break;
        case 'riverpod':
          await _createFile(p.join(stateDir, '${snakeCaseName}_provider.dart'),
              PresentationTemplates.riverpod(snakeCaseName, projectName));
          break;
        default:
          await _createFile(p.join(stateDir, '${snakeCaseName}_state.dart'),
              PresentationTemplates.genericState(snakeCaseName));
          break;
      }

      // 5. Auto-Wiring
      if (storageSelection == 'drift') {
        await _patchDatabase(snakeCaseName);
      }
      await _patchDI(snakeCaseName,
          stateManager: stateManager, storageType: storageSelection);

      progress.complete('Feature generated and wired at $baseDir');
    } catch (e) {
      progress.fail('Generation failed: $e');
      rethrow;
    }
  }

  /// Initializes core structure and resources.
  Future<void> initProject({String? stateManager, bool force = false}) async {
    _strategy = force ? OverwriteStrategy.always : OverwriteStrategy.ask;
    _logger.info('Initializing core architecture...');
    final progress = _logger.progress('Generating core structure');

    try {
      final dirs = [
        'lib/core/config',
        'lib/core/constants',
        'lib/core/di/modules',
        'lib/core/error',
        'lib/core/extensions',
        'lib/core/network/interceptors',
        'lib/core/router',
        'lib/core/storage',
        'lib/core/theme',
        'lib/core/types',
        'lib/core/utils',
        'lib/core/localization',
        'lib/features',
        'lib/shared/widgets/buttons',
        'lib/shared/widgets/layout',
        'lib/shared/state',
        'assets/images',
        'assets/icons',
        'assets/fonts',
        'assets/animations',
        'assets/translations',
      ];

      for (final dir in dirs) {
        final directory = Directory(dir);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
      }

      await _createFile('lib/core/error/app_error.dart', CoreTemplates.appError());
      await _createFile(
          'lib/core/error/error_handler.dart', CoreTemplates.errorHandler());
      await _createFile('lib/core/di/injection_container.dart',
          CoreTemplates.injectionContainer(stateManager));
      await _createFile('lib/core/network/api_client.dart', CoreTemplates.apiClient());
      await _createFile(
          'lib/core/network/base_response.dart', CoreTemplates.baseResponse());
      await _createFile('lib/core/network/network_info.dart', CoreTemplates.networkInfo());
      await _createFile(
          'lib/core/network/network_info_impl.dart', CoreTemplates.networkInfoImpl());
      await _createFile('lib/core/network/interceptors/auth_interceptor.dart',
          CoreTemplates.authInterceptor());
      await _createFile('lib/core/network/interceptors/logging_interceptor.dart',
          CoreTemplates.loggingInterceptor());
      await _createFile(
          'lib/core/storage/secure_storage.dart', CoreTemplates.secureStorage());
      await _createFile('lib/core/storage/secure_storage_impl.dart',
          CoreTemplates.secureStorageImpl());
      await _createFile(
          'lib/core/config/app_config.dart', CoreTemplates.appConfig());
      await _createFile(
          'lib/core/config/flavor_config.dart', CoreTemplates.flavorConfig());
      await _createFile(
          'lib/core/router/app_router.dart', CoreTemplates.appRouter());
      await _createFile('lib/core/constants/route_constants.dart',
          CoreTemplates.routeConstants());
      await _createFile('lib/core/constants/asset_constants.dart',
          CoreTemplates.assetConstants());
      await _createFile(
          'lib/core/constants/app_constants.dart', CoreTemplates.appConstants());
      await _createFile('lib/core/localization/app_strings.dart',
          CoreTemplates.appStrings());
      await _createFile('lib/core/theme/app_theme.dart', CoreTemplates.appTheme());
      await _createFile('lib/core/theme/app_colors.dart', CoreTemplates.appColors());
      await _createFile('lib/core/theme/app_spacing.dart', CoreTemplates.appSpacing());
      await _createFile(
          'lib/core/theme/app_text_theme.dart', CoreTemplates.appTextTheme());
      await _createFile('lib/core/extensions/context_extensions.dart',
          CoreTemplates.contextExtensions());
      await _createFile('lib/core/extensions/string_extensions.dart',
          CoreTemplates.stringExtensions());
      await _createFile('lib/core/utils/validator_utils.dart',
          CoreTemplates.validatorUtils());
      await _createFile(
          'lib/core/utils/responsive_utils.dart', CoreTemplates.responsiveUtils());
      await _createFile('lib/core/utils/permission_service.dart',
          CoreTemplates.permissionService());
      await _createFile('lib/core/utils/logger.dart', CoreTemplates.logger());
      await _createFile('lib/core/types/typedefs.dart', CoreTemplates.typedefs());
      await _createFile('lib/shared/widgets/buttons/primary_button.dart',
          CoreTemplates.sharedButton());
      await _createFile('lib/shared/widgets/layout/app_scaffold.dart',
          CoreTemplates.appScaffold());
      await _createFile('lib/main.dart', CoreTemplates.mainDart(stateManager));
      await _createFile('lib/app.dart', CoreTemplates.appDart());
      await _createFile('analysis_options.yaml', CoreTemplates.analysisOptions());
      await _createFile('build.yaml', CoreTemplates.buildYaml());
      await _createFile(
          'assets/translations/en-US.json', CoreTemplates.emptyJson());
      await _createFile(
          'assets/translations/ne-NP.json', CoreTemplates.emptyJson());

      await _patchAndroidManifest();
      await _patchInfoPlist();
      await _patchPubspecForAssets();
      await _addDependencies(stateManager: stateManager);

      progress.complete(
          'Project initialized successfully with Absolute Resource Suite.');
    } catch (e) {
      progress.fail('Initialization failed: $e');
      rethrow;
    }
  }

  /// Initializes modular storage.
  Future<void> initStorage(String engine, {bool force = false}) async {
    _strategy = force ? OverwriteStrategy.always : OverwriteStrategy.ask;
    final progress = _logger.progress('Initializing $engine');
    try {
      final projectName = _getProjectName();
      if (engine == 'drift') {
        await Process.run('flutter', [
          'pub',
          'add',
          'drift',
          'sqlite3_flutter_libs',
          'path_provider',
          'path'
        ]);
        await Process.run('flutter', ['pub', 'add', '-d', 'drift_dev']);
        await _createFile('lib/core/storage/app_database.dart',
            CoreTemplates.driftDatabase(projectName));
        await _patchDIForStorage('drift');
      } else if (engine == 'shared') {
        await Process.run('flutter', ['pub', 'add', 'shared_preferences']);
        await _createFile('lib/core/storage/local_settings.dart',
            CoreTemplates.localSettings());
        await _patchDIForStorage('shared');
      }
      progress.complete('$engine initialized.');
    } catch (e) {
      progress.fail('Failed to initialize $engine: $e');
    }
  }

  /// Injects storage into existing feature.
  Future<void> addStorageToFeature(String featureName, String engine,
      {bool force = false}) async {
    _strategy = force ? OverwriteStrategy.always : OverwriteStrategy.ask;
    final progress = _logger.progress('Adding $engine to $featureName');
    try {
      if (engine == 'drift') {
        await _patchDatabase(featureName);
      }
      await _patchFeatureLocalDataSource(featureName, engine);
      await _patchDIForFeatureStorage(featureName, engine);
      progress.complete();
    } catch (e) {
      progress.fail('Failed: $e');
    }
  }

  Future<void> _patchDIForStorage(String type) async {
    final file = File('lib/core/di/injection_container.dart');
    if (!await file.exists()) {
      return;
    }
    var content = await file.readAsString();
    if (type == 'drift') {
      if (!content.contains('app_database.dart')) {
        content = "import '../storage/app_database.dart';\n$content";
      }
      if (!content.contains('AppDatabase')) {
        content = content.replaceFirst('configureDependencies() async {',
            'configureDependencies() async {\n  sl.registerLazySingleton<AppDatabase>(() => AppDatabase());');
      }
    } else if (type == 'shared') {
      if (!content.contains('shared_preferences.dart')) {
        content =
            "import 'package:shared_preferences/shared_preferences.dart';\nimport '../storage/local_settings.dart';\n$content";
      }
      if (!content.contains('LocalSettings')) {
        content = content.replaceFirst('configureDependencies() async {',
            'configureDependencies() async {\n  final sharedPreferences = await SharedPreferences.getInstance();\n  sl.registerSingleton<LocalSettings>(LocalSettingsImpl(sharedPreferences));');
      }
    }
    await file.writeAsString(content);
  }

  Future<void> _patchFeatureLocalDataSource(
      String featureName, String engine) async {
    final snake = featureName.snakeCase;
    final pascal = featureName.pascalCase;
    final file = File(
        'lib/features/$snake/data/data_sources/local_data_sources/${snake}_local_data_source.dart');
    if (!await file.exists()) {
      return;
    }
    var content = await file.readAsString();

    // Remove old empty constructor if it exists
    content = content.replaceFirst('const ${pascal}LocalDataSourceImpl();', '');

    if (engine == 'drift' && !content.contains('AppDatabase')) {
      content =
          "import 'package:drift/drift.dart';\nimport 'package:${_getProjectName()}/core/storage/app_database.dart';\n$content";
      final tableDef =
          '\nclass ${pascal}Table extends Table {\n  IntColumn get id => integer().autoIncrement()();\n}\n';
      content = content.replaceFirst(
          'abstract interface class', '$tableDef\nabstract interface class');
      content = content.replaceFirst(
        'class ${pascal}LocalDataSourceImpl implements ${pascal}LocalDataSource {',
        'class ${pascal}LocalDataSourceImpl implements ${pascal}LocalDataSource {\n  final AppDatabase _db;\n  const ${pascal}LocalDataSourceImpl(this._db);',
      );
    } else if (engine == 'shared' && !content.contains('LocalSettings')) {
      content =
          "import 'package:${_getProjectName()}/core/storage/local_settings.dart';\n$content";
      content = content.replaceFirst(
        'class ${pascal}LocalDataSourceImpl implements ${pascal}LocalDataSource {',
        'class ${pascal}LocalDataSourceImpl implements ${pascal}LocalDataSource {\n  final LocalSettings _localSettings;\n  const ${pascal}LocalDataSourceImpl(this._localSettings);',
      );
    }
    await file.writeAsString(content);
  }

  Future<void> _patchDIForFeatureStorage(
      String featureName, String engine) async {
    final file = File('lib/core/di/injection_container.dart');
    if (!await file.exists()) {
      return;
    }
    var content = await file.readAsString();
    final pascal = featureName.pascalCase;

    final oldReg = '${pascal}LocalDataSourceImpl()';
    final newReg = '${pascal}LocalDataSourceImpl(sl())';

    if (content.contains(oldReg)) {
      content = content.replaceFirst(oldReg, newReg);
      await file.writeAsString(content);
    }
  }

  Future<void> _patchDatabase(String featureName) async {
    final file = File('lib/core/storage/app_database.dart');
    if (!await file.exists()) {
      return;
    }
    var content = await file.readAsString();
    final pascal = featureName.pascalCase;
    final snake = featureName.snakeCase;
    final projectName = _getProjectName();

    // Improved idempotency: search only inside tables: [...]
    final tablePattern = RegExp(r'tables: \[(.*?)\]');
    final match = tablePattern.firstMatch(content);

    if (match != null && !match.group(1)!.contains('${pascal}Table')) {
      final import =
          "import 'package:$projectName/features/$snake/data/data_sources/local_data_sources/${snake}_local_data_source.dart';";
      if (!content.contains(import)) {
        content = "$import\n$content";
      }
      content = content.replaceFirst('tables: [', 'tables: [${pascal}Table, ');
    }
    await file.writeAsString(content);
  }

  Future<void> _patchDI(String featureName,
      {String? stateManager, String? storageType}) async {
    final file = File('lib/core/di/injection_container.dart');
    if (!await file.exists()) {
      return;
    }
    var content = await file.readAsString();
    final pascal = featureName.pascalCase;
    final snake = featureName.snakeCase;
    final projectName = _getProjectName();

    if (content.contains('// --- $pascal ---')) {
      return;
    }

    final stateFolderName = stateManager == 'bloc'
        ? 'bloc'
        : (stateManager == 'riverpod' ? 'providers' : 'state');

    final imps = [
      "import 'package:$projectName/features/$snake/data/data_sources/local_data_sources/${snake}_local_data_source.dart';",
      "import 'package:$projectName/features/$snake/data/data_sources/remote_data_sources/${snake}_remote_data_source.dart';",
      "import 'package:$projectName/features/$snake/data/repositories/${snake}_repository_impl.dart';",
      "import 'package:$projectName/features/$snake/domain/repositories/${snake}_repository.dart';",
      "import 'package:$projectName/features/$snake/domain/usecases/get_${snake}_usecase.dart';",
    ];
    if (stateManager == 'bloc') {
      imps.add(
          "import 'package:$projectName/features/$snake/presentation/$stateFolderName/${snake}_bloc.dart';");
    }
    if (stateManager == 'riverpod') {
      imps.add(
          "import 'package:$projectName/features/$snake/presentation/$stateFolderName/${snake}_provider.dart';");
    }

    for (final i in imps) {
      if (!content.contains(i)) {
        content = "$i\n$content";
      }
    }

    final localArgs = (storageType != null) ? 'sl()' : '';
    var regs =
        '\n  // --- $pascal ---\n  sl.registerLazySingleton<${pascal}RemoteDataSource>(() => ${pascal}RemoteDataSourceImpl());\n  sl.registerLazySingleton<${pascal}LocalDataSource>(() => ${pascal}LocalDataSourceImpl($localArgs));\n  sl.registerLazySingleton<${pascal}Repository>(() => ${pascal}RepositoryImpl(sl(), sl()));\n  sl.registerLazySingleton<Get${pascal}UseCase>(() => Get${pascal}UseCase(sl()));';
    if (stateManager == 'bloc') {
      regs += '\n  sl.registerFactory(() => ${pascal}Bloc(sl()));';
    }

    content = content.replaceFirst('configureDependencies() async {',
        'configureDependencies() async {$regs');
    await file.writeAsString(content);
  }

  Future<void> _patchPubspecForAssets() async {
    final file = File('pubspec.yaml');
    if (!await file.exists()) {
      return;
    }

    var content = await file.readAsString();
    if (!content.contains('assets:')) {
      const assetsBlock =
          '\n  assets:\n    - assets/images/\n    - assets/icons/\n    - assets/fonts/\n    - assets/animations/\n    - assets/translations/\n';
      content = content.replaceFirst(
          'uses-material-design: true', 'uses-material-design: true$assetsBlock');
      await file.writeAsString(content);
    }
  }

  Future<void> addCI(String platform) async {
    final progress = _logger.progress('Scaffolding $platform');
    try {
      if (platform == 'github_actions') {
        await _createFile(
            '.github/workflows/verify.yml', CoreTemplates.githubVerify());
      } else if (platform == 'gitlab_ci') {
        await _createFile('.gitlab-ci.yml', CoreTemplates.gitlabCI());
      }
      progress.complete();
    } catch (e) {
      progress.fail('CI failed: $e');
    }
  }

  Future<void> initTests() async {
    final progress = _logger.progress('Scaffolding tests');
    try {
      final projectName = _getProjectName();
      await _createFile(
          'test/core/network/api_client_test.dart',
          CoreTemplates.apiClientTest()
              .replaceFirst('your_project', projectName));
      progress.complete();
    } catch (e) {
      progress.fail('Failed: $e');
    }
  }

  Future<void> generateFeatureTests(String name, {bool force = false}) async {
    final snake = name.snakeCase;
    _strategy = force ? OverwriteStrategy.always : OverwriteStrategy.ask;
    final progress = _logger.progress('Generating tests for $snake');
    try {
      final projectName = _getProjectName();

      final presentationDir = Directory('lib/features/$snake/presentation');
      String stateFolderName = 'state';
      if (await presentationDir.exists()) {
        final subDirs = await presentationDir
            .list()
            .where((e) => e is Directory)
            .map((e) => p.basename(e.path))
            .toList();
        if (subDirs.contains('bloc')) {
          stateFolderName = 'bloc';
        } else if (subDirs.contains('providers')) {
          stateFolderName = 'providers';
        }
      }
      String? state;
      if (await File(
              'lib/features/$snake/presentation/$stateFolderName/${snake}_bloc.dart')
          .exists()) {
        state = 'bloc';
      } else if (await File(
              'lib/features/$snake/presentation/$stateFolderName/${snake}_provider.dart')
          .exists()) {
        state = 'riverpod';
      }

      await _createFile('test/integration/live_api/${snake}_api_test.dart',
          TestTemplates.liveApiTest(snake, projectName));
      await _createFile(
          'test/features/$snake/data/repositories/${snake}_repository_impl_test.dart',
          TestTemplates.repositoryTest(snake, projectName));
      await _createFile(
          'test/features/$snake/domain/usecases/get_${snake}_usecase_test.dart',
          TestTemplates.usecaseTest(snake, projectName));
      if (state == 'bloc') {
        await _createFile(
            'test/features/$snake/presentation/$stateFolderName/${snake}_bloc_test.dart',
            TestTemplates.blocTest(snake, projectName));
      } else if (state == 'riverpod') {
        await _createFile(
            'test/features/$snake/presentation/$stateFolderName/${snake}_provider_test.dart',
            TestTemplates.riverpodTest(snake, projectName));
      }
      progress.complete();
    } catch (e) {
      progress.fail('Failed: $e');
    }
  }

  Future<void> addPermission(PermissionMetadata p) async {
    final progress = _logger.progress('Configuring ${p.name}');
    try {
      await _updateAndroidManifest(p.android);
      if (p.iosKey.isNotEmpty) {
        await _updateInfoPlist(p.iosKey, p.iosDesc);
      }
      await _updatePermissionService(p.name);
      progress.complete();
    } catch (e) {
      progress.fail('Failed: $e');
    }
  }

  Future<void> _updateAndroidManifest(List<String> ps) async {
    final file = File('android/app/src/main/AndroidManifest.xml');
    if (!await file.exists()) {
      return;
    }
    var c = await file.readAsString();
    bool mod = false;
    for (final p in ps) {
      if (!c.contains(p)) {
        c = c.replaceFirst(
            '<application', '    <uses-permission android:name="$p" />\n    <application');
        mod = true;
      }
    }
    if (mod) {
      await file.writeAsString(c);
    }
  }

  Future<void> _updateInfoPlist(String k, String d) async {
    final file = File('ios/Runner/Info.plist');
    if (!await file.exists()) {
      return;
    }
    var c = await file.readAsString();
    if (!c.contains(k)) {
      c = c.replaceFirst(
          '<dict>', '<dict>\n\t<key>$k</key>\n\t<string>$d</string>');
      await file.writeAsString(c);
    }
  }

  Future<void> _updatePermissionService(String name) async {
    final file = File('lib/core/utils/permission_service.dart');
    if (!await file.exists()) {
      return;
    }
    var c = await file.readAsString();
    final p = name.pascalCase;
    if (!c.contains('request$p()')) {
      c = c.replaceFirst('openSettings();', 'openSettings();\n  Future<bool> request$p();');
    }
    if (!c.contains('request$p() async')) {
      final impl =
          '\n  @override\n  Future<bool> request$p() async {\n    final status = await Permission.$name.request();\n    return status.isGranted;\n  }';
      c = c.replaceFirst('openAppSettings();\n  }', 'openAppSettings();\n  }$impl');
    }
    await file.writeAsString(c);
  }

  Future<void> _addDependencies({String? stateManager}) async {
    final progress = _logger.progress('Injecting dependencies');
    try {
      final deps = [
        'get_it',
        'go_router',
        'dio',
        'fpdart',
        'freezed_annotation',
        'json_annotation',
        'retrofit',
        'flutter_secure_storage',
        'internet_connection_checker_plus',
        'permission_handler',
        'logger',
        'pretty_dio_logger',
        'easy_localization'
      ];
      if (stateManager == 'bloc') {
        deps.add('flutter_bloc');
      } else if (stateManager == 'riverpod') {
        deps.add('flutter_riverpod');
        deps.add('riverpod_annotation');
      }
      final devDeps = [
        'freezed',
        'json_serializable',
        'build_runner',
        'retrofit_generator',
        'mocktail',
        'clean_feature_arch'
      ];
      if (stateManager == 'riverpod') {
        devDeps.add('riverpod_generator');
      }
      await Process.run('flutter', ['pub', 'add', ...deps]);
      await Process.run('flutter', ['pub', 'add', '-d', ...devDeps]);
      progress.complete();
    } catch (e) {
      progress.fail('Failed: $e');
    }
  }

  Future<void> _patchAndroidManifest() async {
    final file = File('android/app/src/main/AndroidManifest.xml');
    if (!await file.exists()) {
      return;
    }
    var c = await file.readAsString();
    if (!c.contains('INTERNET')) {
      c = c.replaceFirst('<application',
          '    <uses-permission android:name="android.permission.INTERNET" />\n    <application');
      await file.writeAsString(c);
    }
  }

  Future<void> _patchInfoPlist() async {
    final file = File('ios/Runner/Info.plist');
    if (!await file.exists()) {
      return;
    }
    var c = await file.readAsString();
    const ps = {
      'NSCameraUsageDescription': 'Needs camera.',
      'NSLocationWhenInUseUsageDescription': 'Needs location.',
      'NSPhotoLibraryUsageDescription': 'Needs photos.'
    };
    bool mod = false;
    for (final e in ps.entries) {
      if (!c.contains(e.key)) {
        c = c.replaceFirst(
            '<dict>', '<dict>\n\t<key>${e.key}</key>\n\t<string>${e.value}</string>');
        mod = true;
      }
    }
    if (mod) {
      await file.writeAsString(c);
    }
  }

  Future<void> _createFile(String path, String content) async {
    final file = File(path);
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    if (await file.exists()) {
      if (_strategy == OverwriteStrategy.skipAll) {
        return;
      }
      if (_strategy == OverwriteStrategy.ask) {
        final c = _logger.chooseOne('File $path exists. Overwrite?',
            choices: ['Yes', 'No', 'Always', 'Skip All'], defaultValue: 'No');
        if (c == 'Always') {
          _strategy = OverwriteStrategy.always;
        } else if (c == 'Skip All') {
          _strategy = OverwriteStrategy.skipAll;
          return;
        } else if (c == 'No') {
          return;
        }
      }
    }
    await file.writeAsString(content);
    _logger.detail('Created: $path');
  }

  String _getProjectName() {
    final file = File('pubspec.yaml');
    if (!file.existsSync()) {
      return 'your_project';
    }
    final yaml = loadYaml(file.readAsStringSync()) as YamlMap;
    return yaml['name'] as String? ?? 'your_project';
  }
}
